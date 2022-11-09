#install azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#check version
az version

#configure az cli
az login

#create resource group for k8s
az group create --name k8slab1 --location westeurope

#create acr 
az acr create --resource-group k8slab1 --name lab1k8s --sku Basic

#create k8s cluster
az aks create --resource-group k8slab1 --name k8sCluster --node-count 2 --node-vm-size 'standard_a2_v2' --generate-ssh-keys --attach-acr lab1k8s

#install kubectl for cluster
az aks install-cli

#configure kubectl for cluster
az aks get-credentials --resource-group k8slab1 --name k8sCluster

#check node
kubectl get nodes

#get acr list
az acr list --resource-group k8slab1 --query "[].{acrLoginServer:loginServer}" --output table

#delete all
az group delete --name k8slab1 --yes

