// The below commands are used to get accesskey and secret key from the aws secret manager
echo checking for aws credentials from Secret Manager
accesskey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efileraccesskey')
secretkey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efilersecretkey')

//The received aws credentials are configured inside the custom image 
echo Aws credentials retrieved from secret manager.......
aws configure set aws_access_key_id $accesskey; aws configure set aws_secret_access_key $secretkey; aws configure set default.region "us-east-1"; aws configure set default.format "json"
echo AWS credentials configured Successfully

//Fecthing user inputs from inputs.yaml file and proceeding for deployment
echo Checking for repo at ECR
tag=$(grep -w "deployment_tag" ./inputs.yaml | awk -F= '{print $2}')
env=$(grep -w "environment" ./inputs.yaml | awk -F= '{print $2}')
app=$(grep -w "application" ./inputs.yaml | awk -F= '{print $2}')
cluster=$(grep -w "cluster" ./inputs.yaml | awk -F= '{print $2}')
repo=556277294023.dkr.ecr.us-east-1.amazonaws.com/actimize-$env-$app
sed -i 's@apache:apache@'"$repo:$tag"'@' ./$app.yaml
echo $tag :$repo

//logging into the cluster
echo logging in to cluster
aws eks --region us-east-1 update-kubeconfig --name $cluster

//command to inititate the deployment
echo Deployment has been initiated........
kubectl apply -f $app.yaml -n actimize

//command used to delete the stored aws credentials from the custom image
cd ~/.aws
rm -f /root/.aws/credentials
echo Listing aws folder to confirm aws credentials has been removed from the custom Image...
ls /root/.aws
