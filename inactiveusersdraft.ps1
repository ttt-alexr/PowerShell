# Install the Microsoft.Graph module if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser

# Import the Microsoft.Graph module
# Import-Module Microsoft.Graph

# Connect to Microsoft Graph (delegated)
# Connect-MgGraph -Scopes "User.Read.All"

# Connect to Microsoft Graph (application)
# Define the Application (Client) ID and Secret
$ApplicationClientId = 'c1419333-c0ec-494a-936e-0c63584ada58' # Application (Client) ID
$ApplicationClientSecret = 'hYy8Q~Hy39mDwTBgdRTNGinJ2k4CiSGtgnvEraFT' # Application Secret Value
$TenantId = '437bdb66-fd93-44ac-a10a-dd89b31099d1' # Tenant ID
# Convert the Client Secret to a Secure String
$SecureClientSecret = ConvertTo-SecureString -String $ApplicationClientSecret -AsPlainText -Force
# Create a PSCredential Object Using the Client ID and Secure Client Secret
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationClientId, $SecureClientSecret
# Connect to Microsoft Graph Using the Tenant ID and Client Secret Credential
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome

# The actual script:

# Get inactive users from this many days ago:
$days = 30

$users = Get-MgUser -All -Property DisplayName,SignInActivity,UserPrincipalName

$results = @()

foreach ($user in $users) {
    try {
        if ($user.SignInActivity) {
            $lastSignIn = $user.SignInActivity.LastSuccessfulSignInDateTime

            if ($lastSignIn) {
                # Calculate the date 30 days ago
                $daysAgo = (Get-Date).AddDays(-$days)

                # Check if the last sign-in was more than 30 days ago
                if ($lastSignIn -lt $daysAgo) { # Changed to -lt (less than)
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

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null