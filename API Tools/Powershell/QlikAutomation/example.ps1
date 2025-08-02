
<#
.SYNOPSIS
    Example usage of the QlikAutomation PowerShell module.
.DESCRIPTION
    This script demonstrates how to:
    - Load config
    - Connect to a Qlik Sense session
    - Open a Qlik Sense app
    - Reload the app
    - Save the app
    - Select values
    - Export object data
    - Close the session
#>

# Import the module
Import-Module .\QlikAutomation.psm1 -Force

# Load configuration file
$configPath = ".\Config\QlikSettings.json"
if (-Not (Test-Path $configPath)) {
    Write-Error "Config file not found at $configPath"
    exit 1
}
$config = Get-Content -Raw -Path $configPath | ConvertFrom-Json


# Connect to Qlik session
$session = Connect-QlikSession -Url $config.QlikUrl -CookieName $config.CookieName 
if (-not $session) {
    Write-Error "Failed to establish WebSocket connection"
    exit 1
}

# Open the Qlik app
$appHandle = Get-QlikApp -Session $session -AppId $config.AppId -WriteHost $config.WriteHost
if (-not $appHandle) {
    Write-Error "Failed to open the app"
    Close-WebSocket -client $session
    exit 1
}

# Reload the app
Reload-QlikApp -Session $session -appHandle $appHandle -WriteHost $config.WriteHost

# Save the app
# reload an app without saving it won't save datas into the qvf file
Save-QlikApp -Session $session -appHandle $appHandle -WriteHost $config.WriteHost


# Select field and export data
$OutputDirectory = $config.OutputDirectory
if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

Export-QlikObject -Session $session `
                  -AppHandle $appHandle `
                  -FieldName $config.FieldName `
                  -FieldValues $config.FieldValues `
                  -OutputDirectory $OutputDirectory `
                  -WriteHost $config.WriteHost

# Close WebSocket connection
Close-WebSocket -client $session

Write-Host "Example execution completed successfully." -ForegroundColor Green
