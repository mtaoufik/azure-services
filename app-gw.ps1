# -------------------------------
# Azure Application Gateway Script
# -------------------------------

# Login to Azure Account (Ensure you have the right permissions)
# This will prompt you to log in to your Azure account
Connect-AzAccount

# Set the subscription context
# Replace 'YourSubscriptionID' with your Azure Subscription ID
$SubscriptionId = "YourSubscriptionID"
Set-AzContext -SubscriptionId $SubscriptionId

# Define Resource Group and Location
# Specify the Resource Group name and location where the resources will be created
$ResourceGroupName = "MyResourceGroup"
$Location = "EastUS"

# Create a new Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Define VNet (Virtual Network) and Subnets
# The Application Gateway requires a virtual network with a specific subnet
$VnetName = "MyVNet"
$SubnetName = "AppGatewaySubnet"
$AddressPrefix = "10.0.0.0/16" # Address space for the VNet
$SubnetPrefix = "10.0.1.0/24" # Address range for the subnet

# Create the VNet and Subnet
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix
$Vnet = New-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AddressPrefix -Subnet $SubnetConfig

# Get the App Gateway Subnet
$AppGatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $Vnet

# Define Public IP Address for the Application Gateway
# This will be used to expose the Application Gateway to the internet
$PublicIpName = "MyAppGatewayPublicIP"
$PublicIp = New-AzPublicIpAddress -Name $PublicIpName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Static -Sku Standard

# Configure Frontend IP Configuration
# This links the Public IP Address to the Application Gateway
$FrontendIPConfig = New-AzApplicationGatewayFrontendIPConfig -Name "FrontendIP" -PublicIPAddress $PublicIp

# Configure Backend Pool
# This defines the backend servers that the Application Gateway will route traffic to
$BackendPool = New-AzApplicationGatewayBackendAddressPool -Name "BackendPool" -BackendIPAddresses @("10.0.2.4", "10.0.2.5")

# Configure Backend HTTP Settings
# This defines the backend port and protocol used for routing traffic
$BackendHttpSettings = New-AzApplicationGatewayBackendHttpSettings -Name "BackendHttpSettings" -Port 80 -Protocol Http -CookieBasedAffinity Disabled

# Configure HTTP Listener
# This listens to incoming traffic on the specified frontend IP and port
$HttpListener = New-AzApplicationGatewayHttpListener -Name "HttpListener" -FrontendIPConfiguration $FrontendIPConfig -FrontendPort (New-AzApplicationGatewayFrontendPort -Name "FrontendPort" -Port 80) -Protocol Http

# Configure Request Routing Rule
# This defines how incoming traffic is routed to the backend pool
$RequestRoutingRule = New-AzApplicationGatewayRequestRoutingRule -Name "RoutingRule" -RuleType Basic -HttpListener $HttpListener -BackendAddressPool $BackendPool -BackendHttpSettings $BackendHttpSettings

# Create the Application Gateway
# Combines all the components into a single Application Gateway resource
$AppGateway = New-AzApplicationGateway -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name "MyApplicationGateway" `
    -Sku Standard_v2 `
    -GatewayIPConfigurations (New-AzApplicationGatewayIPConfiguration -Name "GatewayIPConfig" -Subnet $AppGatewaySubnet) `
    -FrontendIPConfigurations $FrontendIPConfig `
    -BackendAddressPools $BackendPool `
    -HttpListeners $HttpListener `
    -RequestRoutingRules $RequestRoutingRule `
    -BackendHttpSettingsCollection $BackendHttpSettings

# Output the details of the created Application Gateway
$AppGateway | Format-List