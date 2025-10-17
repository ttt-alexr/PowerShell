# Detection script for Intune to check if one of two specific GUIDs is installed
$guidList = @(
    '{a98dc6ff-d360-4878-9f0a-915eba86eaf3}',
    '{80A1753C-B44C-81E2-3B11-FCE7A3A412C2}'
    
)
 
$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
 
foreach ($keyPath in $uninstallKeys) {
    foreach ($guid in $guidList) {
        $key = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq $guid }
        if ($key) {
            Write-Host "Found application with GUID $guid"
            exit 0
        }
    }
}
 
# App not found
Write-Host "Application not found"
exit 1