function Format-Sanitize {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString
    )

    process {
        $InputString `
            -replace '[\\\/:*?"<>|]', '' `
            -replace '\s+', '_' `
            -replace '(^_+|_+$)', '' `
            | ForEach-Object { $_.Trim() }
    }
}