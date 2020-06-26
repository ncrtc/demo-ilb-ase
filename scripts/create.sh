affix=$RANDOM
RES_GROUP='myResourceGroup' # Resource Group name
ACR_NAME='myContainerRegistry'$affix       # Azure Container Registry registry name
AZP_URL='https://dev.azure.com/ncrtc/' # This is your org name in Azure DevOps
AKV_NAME='mykeyvault'$affix       # Azure Key Vault vault name
IMAGE_NAME='sample/hello-world:v1'
VNET_NAME='test-network'
SUBNET_NAME='container-subnet'

# Create a resource group. My testing shows this does not through an error if the group already exists.
az group create --name $RES_GROUP --location eastus

az acr create --resource-group $RES_GROUP --name $ACR_NAME --sku Basic
az acr build --image $IMAGE_NAME --registry $ACR_NAME --file Dockerfile .

# This can be used to test running within the container registry, but we will make this work with ACI below.
# az acr run --registry $ACR_NAME --cmd '$Registry/sample/hello-world:v1' /dev/null

az keyvault create -g $RES_GROUP -n $AKV_NAME

# Create service principal, store its password in vault (the registry *password*)
az keyvault secret set \
  --vault-name $AKV_NAME \
  --name $ACR_NAME-pull-pwd \
  --value $(az ad sp create-for-rbac \
                --name http://$ACR_NAME-pull \
                --scopes $(az acr show --name $ACR_NAME --query id --output tsv) \
                --role acrpull \
                --query password \
                --output tsv)

# Store service principal ID in vault (the registry *username*)
az keyvault secret set \
    --vault-name $AKV_NAME \
    --name $ACR_NAME-pull-usr \
    --value $(az ad sp show --id http://$ACR_NAME-pull --query appId --output tsv)

ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RES_GROUP --query "loginServer" --output tsv)

echo "Now you need to manually generate a PAT for azure devops. Add it as a secret to the keyvault $AKV_NAME with the name azp-token. I will sleep for 5 minutes for you to get this done."
sleep 300

# Create the container with the agent
az container create \
    --name aci-demo-$RANDOM \
    --resource-group $RES_GROUP \
    --image $ACR_LOGIN_SERVER/$IMAGE_NAME \
    --registry-login-server $ACR_LOGIN_SERVER \
    --registry-username $(az keyvault secret show --vault-name $AKV_NAME -n $ACR_NAME-pull-usr --query value -o tsv) \
    --registry-password $(az keyvault secret show --vault-name $AKV_NAME -n $ACR_NAME-pull-pwd --query value -o tsv) \
    --subnet  $SUBNET_NAME \
    --vnet $VNET_NAME \
    --environment-variables 'AZP_URL'=$AZP_URL 'AZP_TOKEN'=$(az keyvault secret show --vault-name $AKV_NAME -n azp-token --query value -o tsv) 

# After this, you will need to configure Azure DevOps.