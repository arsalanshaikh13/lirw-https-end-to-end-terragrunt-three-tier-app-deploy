ROLE="S3-SSM-CW-Role-panda-app-prod"
PROFILE="S3-SSM-CW-Profile-panda-app-prod"
region=us-east-1
aws iam remove-role-from-instance-profile \
    --instance-profile-name "$PROFILE" \
    --role-name "$ROLE" \
    --region "$region"
aws iam delete-instance-profile \
    --instance-profile-name "$PROFILE" \
    --region "$region"

aws iam list-attached-role-policies --role-name "$ROLE" --region "$region"

ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE" --query 'AttachedPolicies[].PolicyArn'  --region "$region" --output text)
for POLICY_ARN in $ATTACHED_POLICIES; do
    echo "Detaching managed policy $POLICY_ARN from role $ROLE"
    aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY_ARN" --region "$region"
done

# aws iam list-role-policies --role-name "$ROLE"
POLICIES=$(aws iam list-role-policies --role-name "$ROLE" --query 'PolicyNames' --region "$region" --output text)
for POLICY in $POLICIES; do
    echo "Deleting inline policy $POLICY from role $ROLE"
    aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POLICY" --region "$region"
done
aws iam delete-role --role-name "$ROLE" --region "$region"