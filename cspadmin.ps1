# Import Partner Center module
Import-Module PartnerCenter

# Function to generate a secure random password
function New-SecureRandomPassword {
    $length = 16
    $nonAlphanumeric = 5
    $uppercase = 5
    $lowercase = 3
    $numbers = 3

    $password = ""
    $random = New-Object System.Random

    $upperChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lowerChars = "abcdefghijklmnopqrstuvwxyz"
    $numericChars = "0123456789"
    $specialChars = "!@#$%^&*()-_=+[]{}|;:,.<>?"

    for ($i = 0; $i -lt $uppercase; $i++) {
        $password += $upperChars[$random.Next(0, $upperChars.Length)]
    }
    for ($i = 0; $i -lt $lowercase; $i++) {
        $password += $lowerChars[$random.Next(0, $lowerChars.Length)]
    }
    for ($i = 0; $i -lt $numbers; $i++) {
        $password += $numericChars[$random.Next(0, $numericChars.Length)]
    }
    for ($i = 0; $i -lt $nonAlphanumeric; $i++) {
        $password += $specialChars[$random.Next(0, $specialChars.Length)]
    }

    $passwordArray = $password.ToCharArray()
    $passwordArray = $passwordArray | Sort-Object {Get-Random}
    $password = -join $passwordArray

    return $password
}

Write-Host "`nStarting CSPAdmin account management script..." -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

$csvPath = Read-Host "Enter the path to your CSV file containing customer IDs"
Write-Host "Reading CSV file: $csvPath"
$customers = Import-Csv $csvPath

Write-Host "Found $($customers.Count) customers in CSV`n"

foreach ($customer in $customers) {
    $customerId = $customer.CustomerId
    Write-Host "`nProcessing Tenant ID: $customerId" -ForegroundColor Yellow
    Write-Host "----------------------------------------"

    try {
        Write-Host "1. Checking tenant access..." -NoNewline
        $customer = Get-PartnerCustomer -CustomerId $customerId
        Write-Host " SUCCESS" -ForegroundColor Green
        
        Write-Host "2. Checking domain..." -NoNewline
        $defaultDomain = $customer.Domain
        Write-Host " Using $defaultDomain"
        
        $userPrincipalName = "cspadmin@$defaultDomain"
        Write-Host "3. Checking for CSPAdmin account..." -NoNewline
        
        $existingUser = Get-PartnerCustomerUser -CustomerId $customerId | 
            Where-Object { $_.UserPrincipalName -eq $userPrincipalName }
            
        if ($existingUser) {
            Write-Host " FOUND" -ForegroundColor Yellow
            
            if (-not $existingUser.AccountEnabled) {
                Write-Host "Account is DISABLED" -ForegroundColor Red
                continue
            }
            
            Write-Host "4. Checking Company Administrator role..." -NoNewline
            $userRoles = Get-PartnerCustomerUserRole -CustomerId $customerId -UserId $existingUser.UserId
            
            if ($userRoles.Name -contains "Company Administrator") {
                Write-Host " HAS ROLE" -ForegroundColor Green
                Write-Host "5. Action: None needed - CSPAdmin exists with Company Administrator role"
            } else {
                Write-Host " MISSING ROLE" -ForegroundColor Yellow
                Write-Host "5. Action: Adding Company Administrator role..." -NoNewline
                
                # Get Company Admin role ID
                $allRoles = Get-PartnerCustomerUserRole -CustomerId $customerId
                $role = $allRoles | Where-Object { $_.Name -eq "Company Administrator" }
                Add-PartnerCustomerUserRoleMember -CustomerId $customerId -UserId $existingUser.UserId -RoleId $role.Id
                Write-Host " SUCCESS" -ForegroundColor Green
            }
        } else {
            Write-Host " NOT FOUND" -ForegroundColor Yellow
            Write-Host "4. Action: Creating new CSPAdmin account..." -NoNewline
            
            $password = New-SecureRandomPassword
            $userParams = @{
                UsageLocation = "US"
                DisplayName = "CSPAdmin"
                UserPrincipalName = $userPrincipalName
                Password = (ConvertTo-SecureString $password -AsPlainText -Force)
                FirstName = "CSP"
                LastName = "Admin"
                ForceChangePassword = $false
            }

            $user = New-PartnerCustomerUser -CustomerId $customerId @userParams
            Write-Host " SUCCESS" -ForegroundColor Green
            
            Write-Host "5. Adding Company Administrator role..." -NoNewline
            $allRoles = Get-PartnerCustomerUserRole -CustomerId $customerId
            $role = $allRoles | Where-Object { $_.Name -eq "Company Administrator" }
            Add-PartnerCustomerUserRoleMember -CustomerId $customerId -UserId $user.UserId -RoleId $role.Id
            Write-Host " SUCCESS" -ForegroundColor Green
            
            Write-Host "`nNew Account Details:"
            Write-Host "Username: $userPrincipalName"
            Write-Host "Password: $password"
        }
        
    }
    catch {
        Write-Host " ERROR" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "----------------------------------------"
}

Write-Host "`nScript execution completed." -ForegroundColor Cyan