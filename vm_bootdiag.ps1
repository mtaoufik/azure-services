# Function to create a VM
function Create-VM {
    param (
        [string]$resourceGroupName,
        [string]$location,
        [string]$vmName,
        [string]$username,
        [securestring]$password,
        [string]$image,
        [int]$osDiskSizeGB,
        [string]$vmSize,
        [string]$storageAccountName
    )

    # Create resource group if it doesn't exist
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }

    # Create a virtual network if it doesn't exist
    $vnetName = "$resourceGroupName-vnet"
    $subnetName = "$resourceGroupName-subnet"
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
    if (-not $vnet) {
        $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix "10.0.0.0/16"
        Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet
        $vnet | Set-AzVirtualNetwork
    }

    # Create a network security group
    $nsgName = "$resourceGroupName-nsg"
    $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $nsgName -ErrorAction SilentlyContinue
    if (-not $nsg) {
        $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName
        # Add security rules (example: allow SSH)
        Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "Allow-SSH" -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 22
        $nsg | Set-AzNetworkSecurityGroup
    }

    # Create the virtual machine configuration
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

    # Set the operating system
    Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential (New-Object System.Management.Automation.PSCredential ($username, $password))

    # Set the image
    Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "UbuntuServer" -Skus $image -Version "latest"

    # Set the OS disk
    Set-AzVMOSDisk -VM $vmConfig -DiskSizeInGB $osDiskSizeGB -CreateOption FromImage

    # Configure network settings
    $nicName = "$vmName-nic"
    $subnetId = (Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName).Id
    $nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name $nicName -SubnetId $subnetId -NetworkSecurityGroupId $nsg.Id

    # Attach the network interface to the VM
    Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

    # Enable boot diagnostics
    $storageUri = "https://$storageAccountName.blob.core.windows.net/"
    $diagnosticsProfile = New-AzDiagnosticsProfile -BootDiagnosticsEnabled $true -StorageUri $storageUri
    $vmConfig.DiagnosticsProfile = $diagnosticsProfile

    # Create the virtual machine
    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

    Write-Host "Virtual Machine $vmName created successfully in resource group $resourceGroupName with boot diagnostics enabled."
}

# Authenticate to Azure
Connect-AzAccount

# Prompt user for input
$resourceGroupName = Read-Host -Prompt "Enter Resource Group Name"
$location = Read-Host -Prompt "Enter Location (e.g., eastus)"
$storageAccountName = Read-Host -Prompt "Enter Storage Account Name"

# List of VM configurations
$vms = @(
    @{
        resourceGroupName = $resourceGroupName
        location = $location
        vmName = "VM1"
        username = "adminUser1"
        password = (ConvertTo-SecureString "Password1!" -AsPlainText -Force)
        image = "UbuntuLTS"
        osDiskSizeGB = 30
        vmSize = "Standard_DS1_v2"
        storageAccountName = $storageAccountName
    },
    @{
        resourceGroupName = $resourceGroupName
        location = $location
        vmName = "VM2"
        username = "adminUser2"
        password = (ConvertTo-SecureString "Password2!" -AsPlainText -Force)
        image = "UbuntuLTS"
        osDiskSizeGB = 30
        vmSize = "Standard_DS1_v2"
        storageAccountName = $storageAccountName
    }
)

# Create VMs
foreach ($vm in $vms) {
    Create-VM @vm
}
