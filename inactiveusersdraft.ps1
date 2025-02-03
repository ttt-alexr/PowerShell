# Install the Microsoft.Graph module if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser

# Import the Microsoft.Graph module
# Import-Module Microsoft.Graph

# Connect to Microsoft Graph
# Connect-MgGraph -Scopes "User.Read.All", ""

$users = Get-MgUser -All -Property DisplayName,SignInActivity,UserPrincipalName

$results = @()

foreach ($user in $users) {
    try {
        if ($user.SignInActivity) {
            $lastSignIn = $user.SignInActivity.LastSuccessfulSignInDateTime

            if ($lastSignIn) {
                # Calculate the date 30 days ago
                $thirtyDaysAgo = (Get-Date).AddDays(-30)

                # Check if the last sign-in was more than 30 days ago
                if ($lastSignIn -lt $thirtyDaysAgo) { # Changed to -lt (less than)
                    $results += [PSCustomObject]@{
                        DisplayName = $user.DisplayName
                        UserPrincipalName = $user.UserPrincipalName
                        LastSuccessfulSignInDateTime = $lastSignIn
                    }
                }
            } else {
              #If LastSuccessfulSignInDateTime is null, treat it as older than 30 days.
              $results += [PSCustomObject]@{
                    DisplayName = $user.DisplayName
                    UserPrincipalName = $user.UserPrincipalName
                    LastSuccessfulSignInDateTime = "Never" 
                }
            }
        } else {
            # If SignInActivity is null, treat it as older than 30 days.
            $results += [PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                LastSuccessfulSignInDateTime = "Never"
            }
        }

    } catch {
        Write-Warning "Error processing user $($user.UserPrincipalName): $_"
    }
}

# Filter the results *after* the loop to display only users older than 30 days.
# This is more efficient than filtering inside the loop.
$results | Where-Object {$_.LastSuccessfulSignInDateTime -ne "Never"} | Format-Table -AutoSize # Filtered results