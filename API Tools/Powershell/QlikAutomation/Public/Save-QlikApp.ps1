function Save-QlikApp {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [string]$AppHandle,
        [bool]$WriteHost = $true
    )

    Save-App -ws $Session -appHandle $AppHandle -WriteHost $WriteHost
}
