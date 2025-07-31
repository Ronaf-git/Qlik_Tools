function Export-QlikObject {
    param (
        [System.Net.WebSockets.ClientWebSocket]$Session,
        [int]$AppHandle,
        [string]$FieldName,
        [array]$FieldValues,
        [string]$OutputDirectory,
        [bool]$WriteHost = $true
    )

    foreach ($value in $FieldValues) {
        Select-FieldValues -client $Session -appHandle $AppHandle -fieldName $FieldName -values @($value) -WriteHost $WriteHost 
        
        $sheets = (Get-AllAppInfos -ws $Session -appHandle $AppHandle -WriteHost $WriteHost).result.qInfos | Where-Object { $_.qType -eq 'sheet' }

        foreach ($sheet in $sheets) {
            $sheetObj = Get-AppObject -ws $Session -appHandle $AppHandle -objectId $sheet.qId -WriteHost $WriteHost
            $sheetHandle = $sheetObj.result.qReturn.qHandle

            $children = (Get-ChildInfos -ws $Session -sheetHandle $sheetHandle -WriteHost $WriteHost).result.qInfos

            foreach ($child in $children) {
                $obj = Get-AppObject -ws $Session -appHandle $AppHandle -objectId $child.qId  -WriteHost $WriteHost
                $layout = Get-LayoutInfo -client $Session -objHandle $obj.result.qReturn.qHandle -WriteHost $false
                $title = $layout.result.qLayout.title
                $fileName = "$(Get-Date -Format 'yyyyMMdd')_$($child.qId)_${title}_${value}" | Format-Sanitize
                $path = Join-Path $OutputDirectory "${fileName}.xlsx"

                $export = Export-DataFromObject -client $Session -objHandle $obj.result.qReturn.qHandle -qFileType 'EXPORT_OOXML' -WriteHost $WriteHost

                if ($export.result.qUrl) {
                    if ($Session.WebSocketOrigin.StartsWith("wss")) {
                        $scheme = "https"
                    } else {
                        $scheme = "http"
}
                    $downloadBase = $Session.WebSocketOrigin -replace "^ws", $scheme -replace "^wss", $scheme
                    $url = "$downloadBase$($export.result.qUrl)"
                    Invoke-WebRequest -Uri $url -OutFile $path -UseDefaultCredentials
                    Write-Host "Exported to $path" -ForegroundColor Green
                }
            }
        }
    }
}
