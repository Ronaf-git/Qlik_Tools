function Reload-QlikApp {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [string]$AppHandle,
        [bool]$WriteHost = $true
    )

    Reload-App -ws $Session -appHandle $AppHandle -WriteHost $WriteHost
}
