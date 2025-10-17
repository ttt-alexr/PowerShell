# ----------------------------------------------------------------------------------------------------------------------
# Clear OnPremisesImmutableId
Connect-MgGraph -Scopes User.ReadWrite.All
Invoke-MgGraphRequest -Method PATCH -Uri 'https://graph.microsoft.com/v1.0/users/Username@example.com' -Body @{onPremisesImmutableId = $null}


# ----------------------------------------------------------------------------------------------------------------------
# Remove user from risky user notifications
connect-mggraph -scopes IdentityRiskEvent.ReadWrite.All
$endpoint = "https://graph.microsoft.com/beta/identityProtection/settings/notifications"
$objectid = "801885e7-aec1-4b1d-bbf0-9c5f3f0dfba4"
$body = @"
{
    "notificationRecipients": [
        {
            "id": "$objectid",
            "isRiskyUsersAlertsRecipient": false,
            "isWeeklyDigestRecipient": false
        }
    ]
}
"@
Invoke-MgGraphRequest -uri $endpoint -body $body -method PATCH -ContentType "application/json"


# ----------------------------------------------------------------------------------------------------------------------
# PowerShell in VS Code
# https://code.visualstudio.com/docs/languages/powershell#_installing-the-powershell-extension


# ----------------------------------------------------------------------------------------------------------------------
# Hide path in terminal
function prompt( ) {">"}


# ----------------------------------------------------------------------------------------------------------------------
# Check last Managed Folder Assistant status
$user = "username@domain.com"
([xml]((Export-MailboxDiagnosticLogs -Identity $user -ExtendedProperties).MailboxLog)).Properties.MailboxTable.Property | Where-Object {$_.Name -like "ELC*"}