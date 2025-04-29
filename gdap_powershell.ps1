# Accessing PowerShell Modules with GDAP
# https://davidjust.com/post/gdap-partner-access-with-powershell/

# EXCHANGE
Connect-ExchangeOnline -DelegatedOrganization domain.com

# PURVIEW
$TenantID = '00000000-0000-0000-0000-000000000000'
Connect-IPPSSession -DelegatedOrganization domain.onmicrosoft.com -AzureADAuthorizationEndpointUri https://login.microsoftonline.com/$TenantID/oauth2/authorize 

# TEAMS
Connect-MicrosoftTeams -TenantID 00000000-0000-0000-0000-000000000000

# GRAPH
Connect-MGGraph -TenantID 00000000-0000-0000-0000-000000000000

# AZURE AD
Connect-AzureAD -TenantID 00000000-0000-0000-0000-000000000000

# SHAREPOINT
$TenantID = '00000000-0000-0000-0000-000000000000'
Connect-SPOService -Url https://domain-admin.sharepoint.com -AuthenticationUrl https://login.microsoftonline.com/$TenantID/oauth2/authorize