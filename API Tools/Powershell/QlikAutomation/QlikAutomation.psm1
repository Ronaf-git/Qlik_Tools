# Load Private Helpers
Get-ChildItem -Path "$PSScriptRoot\Private" -Filter *.ps1 | ForEach-Object { . $_.FullName }

# Load Public Functions
Get-ChildItem -Path "$PSScriptRoot\Public" -Filter *.ps1 | ForEach-Object { . $_.FullName }
