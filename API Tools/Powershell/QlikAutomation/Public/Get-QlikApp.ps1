function Get-QlikApp {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [string]$AppId,
        [bool]$WriteHost = $true
    )

    $handle = Open-Document -ws $Session -appId $AppId -WriteHost $WriteHost
    return $handle
}
