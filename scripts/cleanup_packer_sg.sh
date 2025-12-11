cleanup_packer_sg() {
    echo "===== Starting Packer SG Cleanup =====" 

    echo "Checking for security groups containing 'packer'..." 

    SG_IDS=$(aws ec2 describe-security-groups \
        --query "SecurityGroups[?contains(GroupName, 'packer') || contains(Description, 'packer')].GroupId" \
        --output text 2>>"$LOGFILE.tmp" )

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
        else
            echo "Deletion failed for SG $SG_ID. Checking dependencies..." 
            eni_sg $SG_ID
        fi

        
    done

    echo "===== Completed Packer SG Cleanup =====" 
}

eni_sg() {
  local SG_ID=$1
  # Check ENIs attached
  ENI_IDS=$(aws ec2 describe-network-interfaces \
      --filters "Name=group-id,Values=$SG_ID" \
      --query "NetworkInterfaces[].NetworkInterfaceId" \
      --output text 2>>"$LOGFILE.tmp")

  if [[ -n "$ENI_IDS" ]]; then
      echo "ENIs attached to $SG_ID: $ENI_IDS" 

      for ENI in $ENI_IDS; do
          echo "Processing ENI $ENI" 

          ATTACHMENT_ID=$(aws ec2 describe-network-interfaces \
              --network-interface-ids "$ENI" \
              --query "NetworkInterfaces[0].Attachment.AttachmentId" \
              --output text 2>>"$LOGFILE.tmp")

          if [[ "$ATTACHMENT_ID" != "None" ]]; then
              echo "Detaching ENI $ENI (attachment ID: $ATTACHMENT_ID)" 
              aws ec2 detach-network-interface --attachment-id "$ATTACHMENT_ID" 
              sleep 3
          fi

          echo "Deleting ENI $ENI" 
          aws ec2 delete-network-interface --network-interface-id "$ENI" 
      done
  else
      echo "No ENIs attached to SG $SG_ID" 
  fi

  echo "Retrying deletion of SG $SG_ID..." 
  if aws ec2 delete-security-group --group-id "$SG_ID" ; then
      echo "Successfully deleted SG $SG_ID after dependency cleanup" 
  else
      echo "FAILED: SG $SG_ID could not be deleted even after cleanup." 
  fi
}

cleanup_packer_sg