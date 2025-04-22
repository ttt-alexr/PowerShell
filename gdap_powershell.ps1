# Accessing PowerShell Modules with GDAP
# https://davidjust.com/post/gdap-partner-access-with-powershell/

# EXCHANGE
Connect-ExchangeOnline -DelegatedOrganization domain.com

# PURVIEW
$TenantID = 'dac510b8-85bc-43f6-85d4-dc29d0b1bdd7'
Connect-IPPSSession -DelegatedOrganization domain.onmicrosoft.com -AzureADAuthorizationEndpointUri https://login.microsoftonline.com/$TenantID/oauth2/authorize 

# TEAMS
Connect-MicrosoftTeams -TenantID dac510b8-85bc-43f6-85d4-dc29d0b1bdd7

# GRAPH
Connect-MGGraph -TenantID dac510b8-85bc-43f6-85d4-dc29d0b1bdd7 

# AZURE AD
Connect-AzureAD -TenantID dac510b8-85bc-43f6-85d4-dc29d0b1bdd7

# SHAREPOINT
$TenantID = 'dac510b8-85bc-43f6-85d4-dc29d0b1bdd7'
Connect-SPOService -Url https://domain-admin.sharepoint.com -AuthenticationUrl https://login.microsoftonline.com/$TenantID/oauth2/authorize