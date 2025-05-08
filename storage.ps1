# Function to create a Storage Account
function Create-StorageAccount {
    param (
        [string]$resourceGroupName,
        [string]$location,
        [string]$storageAccountName,
        [string]$skuName,
        [string]$kind,
        [string]$accessTier
    )

    # Create resource group if it doesn't exist
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }

    # Create the storage account
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location `
        -SkuName $skuName -Kind $kind -AccessTier $accessTier -EnableHttpsTrafficOnly $true

    Write-Host "Storage Account $storageAccountName created successfully in resource group $resourceGroupName."

    # Configure network rules (example: allow access from specific IP range)
    $networkRuleSet = New-AzStorageAccountNetworkRuleSetConfig -DefaultAction Deny
    Add-AzStorageAccountNetworkRule -ResourceGroupName $resourceGroupName -AccountName $storageAccountName `
        -IPAddressOrRange "203.0.113.0/24" -NetworkRuleSet $networkRuleSet

    Write-Host "Network rules configured for Storage Account $storageAccountName."
}

# Authenticate to Azure
Connect-AzAccount

# Prompt user for input
$resourceGroupName = Read-Host -Prompt "Enter Resource Group Name"
$location = Read-Host -Prompt "Enter Location (e.g., eastus)"
$storageAccountName = Read-Host -Prompt "Enter Storage Account Name"
$skuName = Read-Host -Prompt "Enter SKU Name (e.g., Standard_LRS)"
$kind = Read-Host -Prompt "Enter Kind (e.g., StorageV2)"
$accessTier = Read-Host -Prompt "Enter Access Tier (e.g., Hot)"

# Create the Storage Account
Create-StorageAccount -resourceGroupName $resourceGroupName -location $location -storageAccountName $storageAccountName `
    -skuName $skuName -kind $kind -accessTier $accessTier
