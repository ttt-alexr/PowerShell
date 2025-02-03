# Install the Microsoft.Graph module if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser

# Import the Microsoft.Graph module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All"

# Get the current date and calculate the date 30 days ago
$currentDate = Get-Date
$thirtyDaysAgo = $currentDate.AddDays(-30)

# Get all users
$users = Get-MgUser -All

# Filter users who haven't logged in in the last 30 days
$inactiveUsers = $users | Where-Object {
    $_.SignInActivity.LastSignInDateTime -lt $thirtyDaysAgo
}

# Output the inactive users
$inactiveUsers | Select-Object DisplayName, UserPrincipalName, SignInActivity.LastSignInDateTime