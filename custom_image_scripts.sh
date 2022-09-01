#The below commands are used to get accesskey and secret key from the aws secret manager
echo -e "\e[1;32mchecking for aws credentials from Secret Manager"
accesskey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efileraccesskey')
secretkey=$(aws secretsmanager get-secret-value --secret-id 'efiler_test' --query 'SecretString' --output text | jq -r '.efilersecretkey')

#The received aws credentials are configured inside the custom image 
echo -e "\e[1;32mAws credentials retrieved from secret manager......."
aws configure set aws_access_key_id $accesskey; aws configure set aws_secret_access_key $secretkey; aws configure set default.region "us-east-1"; aws configure set default.format "json"
echo AWS credentials configured Successfully

#Fecthing user inputs from manual_deployment_parameters.yaml file and proceeding for deployment
echo -e "\e[1;32mChecking for user inputs from mamaul_deployment_parameters.yaml file"
tag=$(grep -w "deployment_tag" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
env=$(grep -w "environment" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
app=$(grep -w "application" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
cluster=$(grep -w "cluster" ./manual_deployment_parameters.yaml | awk -F= '{print $2}')
repo=556277294023.dkr.ecr.us-east-1.amazonaws.com/actimize-$env-$app
sed -i 's@apache:apache@'"$repo:$tag"'@' ./$app.yaml

#Command used to find the current image running inside the pod
oldimage=$(kubectl describe deployment efiler -n actimize | grep Image)
echo -e "\e[1;32mcurrent running $app $oldimage"

#Command used to display the image details which we are going to deploy
echo -e "\e[1;32m---------------------------------------------------------------------------------------"
echo -e "\e[1;32mlatest image going to deploy $tag and image retrived from $repo"

#logging into the cluster
echo -e "\e[1;32mlogging in to cluster"
aws eks --region us-east-1 update-kubeconfig --name $cluster

#command to inititate the deployment
echo -e "\e[1;32mDeployment has been initiated........"
kubectl apply -f $app.yaml -n actimize

#command used to check the Pod status post deployment 
sleep 60
kubectl get pods -n actimize  | grep $app

#command used to delete the stored aws credentials from the custom image
cd ~/.aws
rm -f /root/.aws/credentials
echo -e "\e[1;32mListing aws folder to confirm aws credentials has been removed from the custom Image..."
ls /root/.aws
