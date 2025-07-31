function Select-QlikField {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [int]$AppHandle,
        [string]$FieldName,
        [array]$Values,
        [bool]$WriteHost = $true
    )

    Select-FieldValues -client $Session -appHandle $AppHandle -fieldName $FieldName -values $Values -WriteHost $WriteHost 
}
