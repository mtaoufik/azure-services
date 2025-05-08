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
        [string]$vmSize
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

    # Create the virtual machine
    New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

    Write-Host "Virtual Machine $vmName created successfully in resource group $resourceGroupName."
}

# Authenticate to Azure
Connect-AzAccount

# List of VM configurations
$vms = @(
    @{
        resourceGroupName = "ResourceGroup1"
        location = "eastus"
        vmName = "VM1"
        username = "adminUser1"
        password = (ConvertTo-SecureString "Password1!" -AsPlainText -Force)
        image = "UbuntuLTS"
        osDiskSizeGB = 30
        vmSize = "Standard_DS1_v2"
    },
    @{
        resourceGroupName = "ResourceGroup1"
        location = "eastus"
        vmName = "VM2"
        username = "adminUser2"
        password = (ConvertTo-SecureString "Password2!" -AsPlainText -Force)
        image = "UbuntuLTS"
        osDiskSizeGB = 30
        vmSize = "Standard_DS1_v2"
    }
)

# Create VMs
foreach ($vm in $vms) {
    Create-VM @vm
}


# Adding best practices for security, 
#   using Key Vault for storing sensitive information, 
#   setting up network security groups,
#   ensuring consistent naming conventions