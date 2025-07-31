
<#
.SYNOPSIS
    Example usage of the QlikAutomation PowerShell module.
.DESCRIPTION
    This script demonstrates how to:
    - Load config
    - Connect to a Qlik Sense app
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

# Open and reload the app
# Reload App
$appHandle = Reload-QlikApp -Session $session -AppId $config.AppId -WriteHost $config.WriteHost
if (-not $appHandle) {
    Write-Error "Failed to open or reload app"
    Close-WebSocket -client $session
    exit 1
}

# Open and save the app
# reload an app without saving it won't save datas into the qvf file
$appHandle = Save-QlikApp -Session $session -AppId $config.AppId -WriteHost $config.WriteHost
if (-not $appHandle) {
    Write-Error "Failed to open or save app"
    Close-WebSocket -client $session
    exit 1
}

# Select field and export data
$OutputDirectory = $config.OutputDirectory
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
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
