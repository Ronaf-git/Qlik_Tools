function Reload-QlikApp {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [string]$AppId,
        [bool]$WriteHost = $true
    )

    $handle = Open-Document -ws $Session -appId $AppId 
    Reload-App -ws $Session -appHandle $handle -WriteHost $WriteHost
    return $handle
}
