<#
.SYNOPSIS
    A utility to create or delete scheduled tasks that automatically start and stop 
    the Vonage Business application on workstation unlock and lock events.

.DESCRIPTION
    This script provides a complete management solution for Vonage Business startup/shutdown.
    It uses the robust XML import feature for creation and the universally compatible
    Schedule.Service COM object for folder deletion to ensure it works on all systems.

.PARAMETER -Create
    Creates the 'Start' and 'Stop' scheduled tasks in the \Vonage folder.

.PARAMETER -Delete
    Deletes the 'Start' and 'Stop' scheduled tasks and cleans up the \Vonage folder.

.EXAMPLE
    .\VonageTasks.ps1 -Create
    .\VonageTasks.ps1 -Delete

.NOTES
    Author: Gemini Assistant
    Version: 6.4 (Final. Simplifies the main logic to fix all 'double enter' issues.)
#>
[CmdletBinding()]
param (
    [Switch]$Create,
    [Switch]$Delete,
    [Switch]$Help
)

#============================================================================
# SCRIPT CONFIGURATION
#============================================================================
# Path for schtasks.exe (needs leading backslash)
$SchtasksTaskFolder = "\Vonage" 
# Path for PowerShell cmdlets (NO leading backslash)
$CmdletTaskFolder = "Vonage" 

$StartTaskName = "Start Vonage Business on Unlock"
$StopTaskName = "Stop Vonage Business on Lock"

#============================================================================
# ADMINISTRATIVE PRIVILEGE CHECK
#============================================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script needs to be run as an Administrator. Trying to re-launch with elevated privileges..."
    $psArgs = if ($Create) {'-Create'} elseif ($Delete) {'-Delete'} else {''}
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $psArgs" -Verb RunAs
    Exit
}

#============================================================================
# HELP FUNCTION
#============================================================================
function Show-Help {
    Write-Host @"

    Vonage Task Management Script

    This script creates or deletes scheduled tasks to manage the Vonage Business app.
    You must run this script with one of the following parameters:

    -Create     Creates the 'Start on Unlock' and 'Stop on Lock' tasks.
                Example: .\VonageTasks.ps1 -Create

    -Delete     Deletes the 'Start on Unlock' and 'Stop on Lock' tasks and the \Vonage folder.
                Example: .\VonageTasks.ps1 -Delete
    
    -Help       Displays this help message.

"@ -ForegroundColor Yellow
}

#============================================================================
# CREATE TASKS FUNCTION
#============================================================================
function New-VonageTasks {
    # This function uses a try/catch block for its specific operations.
    try {
        Write-Host "Starting setup for Vonage Business startup and shutdown tasks..." -ForegroundColor Cyan
        Write-Host "------------------------------------------------------------------"

        # --- Step 1: Find the Vonage executable ---
        Write-Host "Locating Vonage Business.exe..."
        $vonageExePath = Join-Path $env:LOCALAPPDATA "Programs\vonage\Vonage Business.exe"
        if (-not (Test-Path $vonageExePath)) {
            throw "Could not find 'Vonage Business.exe' at the expected path: $vonageExePath"
        }
        $sanitizedVonagePath = [System.Security.SecurityElement]::Escape($vonageExePath)
        Write-Host "  [SUCCESS] Found Vonage at: $vonageExePath" -ForegroundColor Green

        # --- Step 2: Get the current user ---
        $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
        if (-not $currentUser) {
            throw "Could not determine the currently logged-in user."
        }
        Write-Host "  [SUCCESS] Tasks will be created for user: $currentUser" -ForegroundColor Green

        # --- Step 3: Define the XML template for the tasks ---
$taskXmlTemplate = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>##STATECHANGE##</StateChange>
      <UserId>##USER##</UserId>
      <Delay>PT10S</Delay>
    </SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>##USER##</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <Enabled>true</Enabled>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>##COMMAND##</Command>
      <Arguments>##ARGUMENTS##</Arguments>
    </Exec>
  </Actions>
</Task>
"@

        # --- Step 4: Create the START task ---
        $fullStartTaskName = "$SchtasksTaskFolder\$StartTaskName"
        Write-Host "Creating START task: '$fullStartTaskName'..."
        $startXml = $taskXmlTemplate -replace '##STATECHANGE##', 'SessionUnlock'
        $startXml = $startXml -replace '##USER##', $currentUser
        $startXml = $startXml -replace '##COMMAND##', 'cmd.exe'
        $startXml = $startXml -replace '##ARGUMENTS##', "/c start `"`" `"$sanitizedVonagePath`""
        
        $tempXmlFile = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString() + ".xml")
        $startXml | Out-File -FilePath $tempXmlFile -Encoding "Unicode"
        
        schtasks.exe /CREATE /F /TN "$fullStartTaskName" /XML "$tempXmlFile"
        if ($LASTEXITCODE -ne 0) {
            throw "schtasks.exe failed to create the START task via XML. Exit code: $LASTEXITCODE"
        }
        Remove-Item $tempXmlFile -Force
        Write-Host "  [SUCCESS] Start task created." -ForegroundColor Green

        # --- Step 5: Create the STOP task ---
        $fullStopTaskName = "$SchtasksTaskFolder\$StopTaskName"
        Write-Host "Creating STOP task: '$fullStopTaskName'..."
        $stopXml = $taskXmlTemplate -replace '##STATECHANGE##', 'SessionLock'
        $stopXml = $stopXml -replace '##USER##', $currentUser
        $stopXml = $stopXml -replace '##COMMAND##', 'taskkill.exe'
        $stopXml = $stopXml -replace '##ARGUMENTS##', '/F /IM "Vonage Business.exe"'

        $stopXml | Out-File -FilePath $tempXmlFile -Encoding "Unicode"

        schtasks.exe /CREATE /F /TN "$fullStopTaskName" /XML "$tempXmlFile"
        if ($LASTEXITCODE -ne 0) {
            throw "schtasks.exe failed to create the STOP task via XML. Exit code: $LASTEXITCODE"
        }
        Remove-Item $tempXmlFile -Force
        Write-Host "  [SUCCESS] Stop task created." -ForegroundColor Green
        
        Write-Host "------------------------------------------------------------------"
        Write-Host "Creation complete! Both tasks have been created successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "An error occurred during task creation: $_"
    }
}

#============================================================================
# DELETE TASKS FUNCTION
#============================================================================
function Remove-VonageTasks {
    # This function uses a try/catch block for its specific operations.
    try {
        Write-Host "Starting removal of Vonage Business scheduled tasks..." -ForegroundColor Cyan
        Write-Host "------------------------------------------------------------------"

        # --- Step 1: Delete the START task ---
        if (Get-ScheduledTask -TaskName $StartTaskName -TaskPath "\$CmdletTaskFolder\" -ErrorAction SilentlyContinue) {
            Write-Host "Removing task: '$StartTaskName'..."
            Unregister-ScheduledTask -TaskName $StartTaskName -TaskPath "\$CmdletTaskFolder\" -Confirm:$false
            Write-Host "  [SUCCESS] Start task removed." -ForegroundColor Green
        } else {
            Write-Host "Start task not found. Skipping." -ForegroundColor Yellow
        }
        
        # --- Step 2: Delete the STOP task ---
        if (Get-ScheduledTask -TaskName $StopTaskName -TaskPath "\$CmdletTaskFolder\" -ErrorAction SilentlyContinue) {
            Write-Host "Removing task: '$StopTaskName'..."
            Unregister-ScheduledTask -TaskName $StopTaskName -TaskPath "\$CmdletTaskFolder\" -Confirm:$false
            Write-Host "  [SUCCESS] Stop task removed." -ForegroundColor Green
        } else {
            Write-Host "Stop task not found. Skipping." -ForegroundColor Yellow
        }

        # --- Step 3: Delete the folder using the compatible COM object method ---
        try {
            $service = New-Object -ComObject Schedule.Service
            $service.Connect()
            $rootFolder = $service.GetFolder("\")
            # This will throw an error if the folder doesn't exist, which is handled by the catch block.
            $rootFolder.DeleteFolder($CmdletTaskFolder, 0)
            Write-Host "Removing folder: '\$CmdletTaskFolder'..."
            Write-Host "  [SUCCESS] Folder removed." -ForegroundColor Green
        }
        catch {
            # This will fail if the folder doesn't exist or isn't empty, which is fine.
            Write-Host "Folder '\$CmdletTaskFolder' not found or was not empty. Skipping removal." -ForegroundColor Yellow
        }
        
        Write-Host "------------------------------------------------------------------"
        Write-Host "Removal complete!" -ForegroundColor Green
    }
    catch {
        Write-Error "An error occurred during task removal: $_"
    }
}

#============================================================================
# MAIN SCRIPT LOGIC
#============================================================================
# No top-level try/catch block. The script will now flow directly.
if ($Create) {
    New-VonageTasks
}
elseif ($Delete) {
    Remove-VonageTasks
}
else {
    Show-Help
}

# A single, final pause that will now behave consistently.
if ($pscmdlet.MyInvocation.BoundParameters.Count -gt 0) {
    Write-Host "Script finished. Press Enter to exit..." -ForegroundColor Yellow
    Read-Host
}