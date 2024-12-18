# Ensure you're connected to Microsoft Graph with appropriate scopes
# Connect-MgGraph -Scopes User.Read.All, Organization.Read.All

# Get all SKUs and create a lookup dictionary
$skus = Get-MgSubscribedSku

# Debug: Check the SKUs
Write-Host "Total SKUs found: $($skus.Count)"
$skus | Format-Table SkuId, SkuPartNumber, DisplayName

# Create lookup dictionary using different properties
$skuLookup = @{}
foreach ($sku in $skus) {
    # Try multiple ways to ensure we capture the license name
    $skuLookup[$sku.SkuId] = $sku.DisplayName ?? $sku.SkuPartNumber ?? "Unknown License"
    Write-Host "Added SKU: $($sku.SkuId) - Name: $($skuLookup[$sku.SkuId])"
}

# Get users and their assigned licenses
$users = Get-MgUser -All -Property UserPrincipalName, AssignedLicenses

# Create a report with user, SKU ID, and human-readable license name
$report = foreach ($user in $users) {
    foreach ($license in $user.AssignedLicenses) {
        [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            SkuId = $license.SkuId
            LicenseName = $skuLookup[$license.SkuId] ?? "Unknown License"
        }
    }
}

# Export the report
$report | Export-Csv -Path "C:\Temp\Licensereport.csv" -NoTypeInformation

# Optional: Display the report to verify
$report | Format-Table -AutoSize
