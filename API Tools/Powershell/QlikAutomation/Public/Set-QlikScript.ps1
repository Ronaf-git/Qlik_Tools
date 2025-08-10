function Set-QlikScript {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [string]$AppHandle,
        [string]$scriptText,
        [bool]$WriteHost = $true
    )

    Set-QlikAppScript -client $Session -appHandle $AppHandle -scriptText $scriptText -WriteHost $WriteHost | Out-Null

}
