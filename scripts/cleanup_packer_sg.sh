#!/bin/bash
set -euo pipefail

cleanup_packer_sg() {
    echo "===== Starting Packer SG Cleanup =====" 

    echo "Checking for security groups containing 'packer'..." 

    SG_IDS=$(aws ec2 describe-security-groups \
        --query "SecurityGroups[?contains(GroupName, 'packer') || contains(Description, 'packer')].GroupId" \
        --output text 2>>"$LOGFILE.tmp")

    if [[ -z "$SG_IDS" ]]; then
        echo "No security group with 'packer' found. Cleanup not required." 
        echo "===== Completed Packer SG Cleanup (No SG Found) =====" 
        return 0
    fi

    echo "Found security group(s): $SG_IDS" 

    for SG_ID in $SG_IDS; do
        echo "Attempting to delete SG: $SG_ID" 

        if aws ec2 delete-security-group --group-id "$SG_ID" ; then
            echo "Successfully deleted SG: $SG_ID" 
            continue
        fi

        echo "Deletion FAILED for SG $SG_ID. Checking dependencies..." 

        #####################################################################
        # 1️⃣ CHECK ENIs ATTACHED TO THIS SECURITY GROUP
        #####################################################################
        ENI_IDS=$(aws ec2 describe-network-interfaces \
            --filters "Name=group-id,Values=$SG_ID" \
            --query "NetworkInterfaces[].NetworkInterfaceId" \
            --output text 2>>"$LOGFILE.tmp")

        if [[ -z "$ENI_IDS" ]]; then
            echo "No ENIs attached to SG $SG_ID" 
        else
            echo "ENIs attached to $SG_ID: $ENI_IDS" 

            for ENI in $ENI_IDS; do
                echo "Processing ENI $ENI" 

                #################################################################
                # 2️⃣ CHECK IF THIS ENI IS ATTACHED TO AN EC2 INSTANCE
                #################################################################
                INSTANCE_ID=$(aws ec2 describe-network-interfaces \
                    --network-interface-ids "$ENI" \
                    --query "NetworkInterfaces[0].Attachment.InstanceId" \
                    --output text 2>>"$LOGFILE.tmp")

                ATTACHMENT_ID=$(aws ec2 describe-network-interfaces \
                    --network-interface-ids "$ENI" \
                    --query "NetworkInterfaces[0].Attachment.AttachmentId" \
                    --output text 2>>"$LOGFILE.tmp")

                if [[ "$INSTANCE_ID" != "None" ]]; then
                    echo "ENI $ENI is attached to EC2 instance: $INSTANCE_ID" 

                    #################################################################
                    # 3️⃣ TERMINATE INSTANCE (DEFAULT BEHAVIOR)
                    #    Because if instance is alive, you cannot delete ENI or SG.
                    #################################################################
                    echo "Terminating EC2 instance $INSTANCE_ID..." 
                    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" 

                    echo "Waiting for instance $INSTANCE_ID to terminate..." 
                    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" 
                fi

                #################################################################
                # 4️⃣ DETACH AND DELETE THE ENI
                #################################################################
                if [[ "$ATTACHMENT_ID" != "None" ]]; then
                    echo "Detaching ENI $ENI (attachment ID: $ATTACHMENT_ID)" 
                    aws ec2 detach-network-interface --attachment-id "$ATTACHMENT_ID" 
                    sleep 3
                fi

                echo "Deleting ENI $ENI" 
                aws ec2 delete-network-interface --network-interface-id "$ENI" 
            done
        fi

        #####################################################################
        # 5️⃣ RETRY SECURITY GROUP DELETION AFTER CLEANUP
        #####################################################################
        echo "Retrying deletion of SG $SG_ID..." 
        if aws ec2 delete-security-group --group-id "$SG_ID" ; then
            echo "Successfully deleted SG $SG_ID after cleaning dependencies." 
        else
            echo "FAILED: SG $SG_ID could not be deleted even after full cleanup!" 
        fi
    done

    echo "===== Completed Packer SG Cleanup =====" 
}

cleanup_packer_sg
