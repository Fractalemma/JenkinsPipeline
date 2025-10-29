# Initial tests

## Permission tests

Initiate an SSM session into the "Jenkins EC2" and execute these commands to verify the IAM instance profile permissions.

```shell
export REGION=us-east-1

export APP_TAG_KEY=Role
export APP_TAG_VAL=App

export BUCKET=jenkins-pipeline-emmanuel-engineering-com
export KEY_PREFIX=myapp/releases
export REL=$(date -u +%Y-%m-%dT%H-%M-%S)_manual
export KEY="${KEY_PREFIX}/${REL}.zip"
```

### Check aws:DescribeInstanceInformation permission

```shell
aws ssm describe-instance-information --region $REGION --query "InstanceInformationList[].[InstanceId,PlatformName,IPAddress,ResourceType]" --output table
```

### Check aws:SendCommand permission

```shell
aws ssm send-command   --region $REGION   --document-name "AWS-RunShellScript"   --targets "Key=tag:$APP_TAG_KEY,Values=$APP_TAG_VAL"   --comment "Test: write file"   --parameters '{"commands":["echo Hello from SSM $(date) | sudo tee /tmp/ssm-test.txt"]}'
```

You can check the command record in the Systems Manager -> Run Command -> Command history

### Upload dummy artifact to S3

```shell
mkdir -p /tmp/s3test && cd /tmp/s3test
echo "Hello from Jenkins EC2 at $(date)" > testfile.txt
zip -r artifact.zip testfile.txt > /dev/null

aws s3 cp artifact.zip "s3://${BUCKET}/${KEY}" --region "$REGION"
```

Verify:

```shell
aws s3 ls "s3://${BUCKET}/${KEY_PREFIX}/" --region "$REGION"
```

### Outcome/goal

This way we verify that the Jenkins EC2 can:

- Run Commands on the App EC2s
- Upload to S3

## Test the pipeline without Jenkins (execute the script via SSM in the Jenkins EC2)

- Note: the user-data of the App EC2s should be the terraform\root\user-data-scripts\nginx-deploy.sh

```shell
set -euxo pipefail

mkdir -p /tmp/testartifact && cd /tmp/testartifact
cat > index.html <<'HTML'
<!doctype html><meta charset="utf-8"><title>Deployed via SSM 🎉 </title>
<h1 style="font-family:sans-serif">Hello from ALB + SSM + S3!</h1>
<p>Build: <span id="b"></span></p>
<script>document.getElementById('b').textContent=new Date().toISOString()</script>
HTML

zip -qr artifact.zip index.html

export REGION=us-east-1
export BUCKET=jenkins-pipeline-emmanuel-engineering-com
export KEY_PREFIX=myapp/releases
REL="$(date -u +%Y-%m-%dT%H-%M-%S)_manual"
KEY="${KEY_PREFIX}/${REL}.zip"

aws s3 cp artifact.zip "s3://${BUCKET}/${KEY}" --region "$REGION"
echo "Uploaded to s3://${BUCKET}/${KEY}"


export APP_TAG_KEY=Role
export APP_TAG_VAL=App
CMD_ID=$(aws ssm send-command \
  --region "$REGION" \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:${APP_TAG_KEY},Values=${APP_TAG_VAL}" \
  --comment "Manual deploy ${REL}" \
  --parameters commands="sudo /opt/deploy/pull_and_switch.sh ${BUCKET} ${KEY}" \
  --query "Command.CommandId" --output text)

echo "Command: $CMD_ID"

# Wait for completion (simple loop)
STATUS="InProgress"; ATTEMPTS=0
until [[ "$STATUS" =~ ^(Success|Cancelled|TimedOut|Failed)$ ]]; do
  sleep 5
  STATUS=$(aws ssm list-command-invocations --region "$REGION" \
    --command-id "$CMD_ID" --details \
    --query "CommandInvocations[0].Status" --output text || echo InProgress)
  echo "SSM status: $STATUS"
  ATTEMPTS=$((ATTEMPTS+1)); [[ $ATTEMPTS -le 120 ]] || { echo "Timeout"; exit 1; }
done

[[ "$STATUS" == "Success" ]] || { echo "Deploy failed: $STATUS"; exit 1; }
```
