# Variables
resourceGroupName="YourResourceGroupName"
vmName="YourVMName"
storageAccountName="YourStorageAccountName"

# Enable boot diagnostics
az vm boot-diagnostics enable --resource-group $resourceGroupName --name $vmName --storage $storageAccountName
