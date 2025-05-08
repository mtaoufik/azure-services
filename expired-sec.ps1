# Variables
$resourceGroupName = "YourResourceGroupName"
$automationAccountName = "YourAutomationAccountName"
$keyVaultName = "YourKeyVaultName"
$notificationEmail = "YourEmail@example.com"

# Authenticate to Azure
Connect-AzAccount

# Get the secrets from the Key Vault
$secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName

# Get the current date and the date two weeks from now
$currentDate = Get-Date
$expirationThreshold = $currentDate.AddDays(14)

# Initialize an array to hold expiring secrets
$expiringSecrets = @()

# Check each secret's expiration date
foreach ($secret in $secrets) {
    $secretAttributes = Get-AzKeyVaultSecretAttribute -VaultName $keyVaultName -Name $secret.Name
    if ($secretAttributes.Expires -lt $expirationThreshold) {
        $expiringSecrets += $secret
    }
}

# Send notification if there are expiring secrets
if ($expiringSecrets.Count -gt 0) {
    $expiringSecretsList = $expiringSecrets | ForEach-Object { $_.Name + " (Expires: " + $_.Attributes.Expires.ToString() + ")" }
    $body = "The following secrets are set to expire within the next two weeks:`n`n" + ($expiringSecretsList -join "`n")
    
    Send-MailMessage -To $notificationEmail -From "noreply@example.com" -Subject "Expiring Secrets Notification" -Body $body -SmtpServer "smtp.example.com"
}

# Output the expiring secrets for logging purposes
$expiringSecrets


# How to 
#*******************************************************************************************************

Steps to Set Up the Script in Azure Automation Account:

Create an Automation Account:

In the Azure portal, navigate to "Automation Accounts" and create a new automation account.

Add a Runbook:

In the automation account, go to "Runbooks" and create a new PowerShell runbook.

Copy and paste the script into the runbook editor.


Publish the Runbook:
    Save and publish the runbook.

    Create a Schedule:
    Create a schedule to run the runbook at your desired frequency (e.g., daily).

Configure Email Settings:
    Ensure that the Send-MailMessage cmdlet is configured with the correct SMTP server and credentials.

Assign Permissions:
    Ensure the automation account has the necessary permissions to access the Key Vault.


#******************************************************************************************