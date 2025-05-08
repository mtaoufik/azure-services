# Prompt user for input
$resourceGroupName = Read-Host -Prompt "Enter Resource Group Name"
$location = Read-Host -Prompt "Enter Location (e.g., eastus)"
$vmName = Read-Host -Prompt "Enter VM Name"
$username = Read-Host -Prompt "Enter Username"
$password = Read-Host -Prompt "Enter Password" -AsSecureString
$image = Read-Host -Prompt "Enter Image (e.g., UbuntuLTS)"
$osDiskSizeGB = Read-Host -Prompt "Enter OS Disk Size (in GB)"
$vmSize = Read-Host -Prompt "Enter VM Size (e.g., Standard_DS1_v2)"

# Authenticate to Azure
Connect-AzAccount

# Create resource group if it doesn't exist
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create the virtual machine configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Set the operating system
Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential ($username, $password))

# Set the image
Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "UbuntuServer" -Skus $image -Version "latest"

# Set the OS disk
Set-AzVMOSDisk -VM $vmConfig -DiskSizeInGB $osDiskSizeGB -CreateOption FromImage

# Create the virtual machine
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

Write-Host "Virtual Machine $vmName created successfully in resource group $resourceGroupName."
