function Get-QlikScript {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [string]$AppHandle,
        [bool]$WriteHost = $true
    )

    $script = Get-QlikAppScript -client $Session -appHandle $AppHandle -WriteHost $WriteHost

    return $script 

}
