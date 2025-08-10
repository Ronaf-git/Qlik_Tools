function Open-Document {
    param (
        [System.Net.WebSockets.ClientWebSocket]$ws,
        [string]$appId,
        [bool]$WriteHost = $true
    )

    Write-Host "$(Get-Timestamp) Try to open app ${appId}..." -ForegroundColor Cyan

    $request = @{
        jsonrpc = "2.0"
        method  = "OpenDoc"
        handle  = -1
        params  = @($appId)
        id      = (Get-NextRequestId)
    }
    Send-JsonMessage -client $ws -json (ConvertTo-Json $request -Depth 10) -WriteHost $WriteHost

    while ($true) {
        $responseText = Receive-JsonMessage -client $ws -WriteHost $WriteHost

        $response = $responseText | ConvertFrom-Json

        if ($response.id -eq $request.id) {
            $handle = $response.result.qReturn.qHandle
            break
        }
        write-host "$(Get-Timestamp) Listening"
        start-sleep -Seconds 1
    }

    if (-not $handle) {
        Write-Host "$(Get-Timestamp) Failed to open app." -ForegroundColor Red
        exit
    }

    Write-Host "$(Get-Timestamp) Opened app with handle: $handle" -ForegroundColor Green
    return $handle

}

function Reload-App {
    param (
        [System.Net.WebSockets.ClientWebSocket]$ws,
        [int]$appHandle,
        [bool]$WriteHost = $true
    )

    Write-Host "$(Get-Timestamp) Try to Reload app ..." -ForegroundColor Cyan

    $request = @{
        jsonrpc = "2.0"
        method  = "DoReload"
        handle  = $appHandle
        params  = @{
            qMode    = 0       # Full reload
            qPartial = $false
            qDebug   = $false
        }
        id = (Get-NextRequestId)
    }

    $response = Send-QlikRequest -client $ws -request $request -WriteHost $WriteHost
    if ($response.result.qReturn) {
            Write-Host "$(Get-Timestamp) App Reloaded " -ForegroundColor Green
    } else {
            Write-Host "$(Get-Timestamp) ERROR App NOT Reloaded " -ForegroundColor Red
    }
}

function Save-App {
    param (
        [System.Net.WebSockets.ClientWebSocket]$ws,
        [int]$appHandle,
        [bool]$WriteHost = $true
    )

    Write-Host "$(Get-Timestamp) Try to Save app ..." -ForegroundColor Cyan

    $request = @{
        jsonrpc = "2.0"
        method  = "DoSave"
        handle  = $appHandle
        params  = @{ }
        id      = (Get-NextRequestId)
    }

    $response = Send-QlikRequest -client $ws -request $request -WriteHost $WriteHost
    if ($response.result) {
            Write-Host "$(Get-Timestamp) App Saved " -ForegroundColor Green
    } else {
            Write-Host "$(Get-Timestamp) ERROR App NOT Saved " -ForegroundColor Red
    }
}

# https://help.qlik.com/en-US/sense-developer/November2024/Subsystems/EngineAPI/Content/Sense_EngineAPI/DiscoveringAndAnalysing/MakeSelections/select-values-in-field.htm
function Select-FieldValues {
    param (
        [System.Net.WebSockets.ClientWebSocket]$client,
        [int]$appHandle,
        [string]$fieldName,
        [array]$values,
        [bool]$WriteHost = $true
    )
    # STEP 1: Get the field object handle
    
    Write-Host "$(Get-Timestamp) Try to select ${fieldName} ..." -ForegroundColor Cyan

    $getFieldReq = @{
        jsonrpc = "2.0"
        method  = "GetField"
        handle  = $appHandle
        params  = @{ qFieldName = $fieldName }
        id      = (Get-NextRequestId)
    }
    $fieldResp = Send-QlikRequest -client $client -request $getFieldReq -WriteHost $WriteHost
    $fieldHandle = $fieldResp.result.qReturn.qHandle

    if (-not $fieldHandle) {
        if ($WriteHost) {
            Write-Host "$(Get-Timestamp) Could not get handle for field: $fieldName" -ForegroundColor Red
        }
        return
    }

    # STEP 2: Prepare the values for selection
    $qFieldValues = @()
    foreach ($value in $values) {
        if (Is-Numeric $value) {
            $qFieldValues += @{
                qText      = $null
                qIsNumeric = $true
                qNumber    = $value
            }
        } else {
            $qFieldValues += @{
                qText      = "$value"
                qIsNumeric = $false
                qNumber    = 0
            }
        }
    }

    # STEP 3: Send the SelectValues request
    $selectReq = @{
        jsonrpc = "2.0"
        method  = "SelectValues"
        handle  = $fieldHandle
        params  = @{
            qFieldValues = $qFieldValues
            qToggleMode  = $false
            qSoftLock    = $false
        }
        id = (Get-NextRequestId)
    }
    # 

    $response = Send-QlikRequest -client $client -request $selectReq -WriteHost $WriteHost
    if ($response.result) {
            Write-Host "$(Get-Timestamp)  Selected: $($values -join ', ')" -ForegroundColor Green
    } else {
            Write-Host "$(Get-Timestamp)  ERROR not Selected: $($values -join ', ')" -ForegroundColor Red
    }
}

function Get-AllAppInfos {
    param (
        [System.Net.WebSockets.ClientWebSocket]$ws,
        [int]$appHandle,
        [bool]$WriteHost = $true
    )

    $request = @{
        jsonrpc = "2.0"
        method  = "GetAllInfos"
        handle  = $appHandle
        params  = @{ }
        id      = (Get-NextRequestId)
    }

    $response = Send-QlikRequest -client $ws -request $request -WriteHost $WriteHost
    if ($response.result) {
            Write-Host "$(Get-Timestamp)  AllInfos Succes " -ForegroundColor Green
    } else {
            Write-Host "$(Get-Timestamp)  ERROR AllInfos Failed " -ForegroundColor Red
    }


    return $response
}


function Get-AppObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebSockets.ClientWebSocket]$ws,

        [Parameter(Mandatory = $true)]
        [int]$appHandle,

        [Parameter(Mandatory = $true)]
        [string]$objectId,

        [int]$requestId = (Get-NextRequestId),

        [bool]$WriteHost = $true
    )

    $request = @{
        jsonrpc = "2.0"
        method  = "GetObject"
        handle  = $appHandle
        params  = @{ qId = $objectId }
        id      = $requestId
    }

    $response = Send-QlikRequest -client $ws -request $request -WriteHost $WriteHost

    if ($response.result) {
            Write-Host "$(Get-Timestamp)  AppObject Succes " -ForegroundColor Green
    } else {
            Write-Host "$(Get-Timestamp)  ERROR AppObject Failed " -ForegroundColor Red
    }

    return $response
}

function Get-ChildInfos {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebSockets.ClientWebSocket]$ws,

        [Parameter(Mandatory = $true)]
        [int]$sheetHandle,

        [int]$requestId = (Get-NextRequestId),

        [bool]$WriteHost = $true
    )

    $request = @{
        jsonrpc = "2.0"
        method  = "GetChildInfos"
        handle  = $sheetHandle
        params  = @{ }
        id      = $requestId
    }

    $response = Send-QlikRequest -client $ws -request $request -WriteHost $WriteHost

    if ($response.result) {
            Write-Host "$(Get-Timestamp)  GetChildInfos Succes " -ForegroundColor Green
    } else {
            Write-Host "$(Get-Timestamp)  ERROR GetChildInfos Failed " -ForegroundColor Red
    }

    return $response
}

function Get-LayoutInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebSockets.ClientWebSocket]$client,

        [Parameter(Mandatory = $true)]
        [int]$objHandle,

        [int]$id = (Get-NextRequestId),

        [bool]$WriteHost = $true
    )

    # Prepare the request payload
    $getlayoutrq = @{
        jsonrpc = "2.0"
        id = $id
        method  = "GetLayout"
        handle = $objHandle
        params = @{}
    }

    try {
        # Send the request and get the response
        $response = Send-QlikRequest -client $client -request $getlayoutrq -WriteHost $WriteHost

        # Check the response for success
        if ($response.result) {
                Write-Host "$(Get-Timestamp)  GetLayout Success" -ForegroundColor Green
            return $response
        }
        else {
                Write-Host "$(Get-Timestamp)  ERROR GetLayout Failed: No result" -ForegroundColor Red
            return $null
        }
    } catch {
        # Handle any errors that occurred during the request
            Write-Host "$(Get-Timestamp)  ERROR GetLayout Request Failed: $_" -ForegroundColor Red
        return $null
    }
}

function Export-DataFromObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebSockets.ClientWebSocket]$client,

        [Parameter(Mandatory = $true)]
        [int]$objHandle,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CSV_C', 'EXPORT_CSV_C', 'CSV_T', 'EXPORT_CSV_T', 'OOXML', 'EXPORT_OOXML', 'PARQUET', 'EXPORT_PARQUET')]
        [string]$qFileType,  # Type of the file to export

        [Parameter(Mandatory = $false)]
        [string]$qPath = "/qHyperCubeDef",  # Path to the definition (mandatory for CSV types)

        [Parameter(Mandatory = $false)]
        [string]$qFileName = 'FileName',  # Name of the exported file (for Qlik Sense Desktop)

        [Parameter(Mandatory = $false)]
        [ValidateSet('P', 'EXPORT_POSSIBLE', 'A', 'EXPORT_ALL')]
        [string]$qExportState = 'A',  # Values to be exported

        [Parameter(Mandatory = $false)]
        [bool]$qServeOnce = $false,  # If the file should be served once (for Qlik Sense Enterprise)

        [int]$id = (Get-NextRequestId),  # Request ID

        [bool]$WriteHost = $true  # Control whether to write output to the host
    )

    # Prepare the export data request payload
    $exportReq = @{
        jsonrpc = "2.0"
        method  = "ExportData"
        handle  = $objHandle
        params  = @{
            qFileType    = $qFileType      # File type to export (e.g., 'EXPORT_OOXML')
            qPath        = $qPath          # Path to object (e.g., '/qHyperCubeDef')
            qFileName    = $qFileName      # Name of the exported file (optional)
            qExportState = $qExportState   # Export state (e.g., 'EXPORT_POSSIBLE' or 'EXPORT_ALL')
            qServeOnce   = $qServeOnce     # Serve the file once (optional)
        }
        id = $id
    }

    try {
        # Send the request and get the response
        $exportResp = Send-QlikRequest -client $client -request $exportReq -WriteHost $WriteHost

        # Check the response for success
        if ($exportResp.result) {
                Write-Host "$(Get-Timestamp)  ExportData Success - URL $($exportResp.result.qUrl)" -ForegroundColor Green
            return $exportResp
        }
        else {
                Write-Host "$(Get-Timestamp)  ERROR ExportData Failed: No result" -ForegroundColor Red
            return $null
        }
    } catch {
        # Handle any errors that occurred during the request
            Write-Host "$(Get-Timestamp)  ERROR ExportData Request Failed: $_" -ForegroundColor Red
        return $null
    }
}

function Get-QlikAppScript {
    param (
        [System.Net.WebSockets.ClientWebSocket]$client,
        [int]$appHandle,
        [bool]$WriteHost = $true
    )

    Write-Host "$(Get-Timestamp) Retrieving load script..." -ForegroundColor Cyan

    $request = @{
        jsonrpc = "2.0"
        id      = (Get-NextRequestId)
        handle  = $appHandle
        method  = "GetScript"
        params  = @{}
    }

    $response = Send-QlikRequest -client $client -request $request -WriteHost $false

    if ($response.result) {
        $script = $response.result.qScript
        Write-Host "$(Get-Timestamp) Script retrieved" -ForegroundColor Green
        return $script
        
    } else {
        Write-Host "$(Get-Timestamp) ERROR retrieving script" -ForegroundColor Red
    }
}


function Get-QlikAppLayout {
    param (
        [System.Net.WebSockets.ClientWebSocket]$ws,
        [int]$appHandle,
        [bool]$WriteHost = $true
    )

    Write-Host "$(Get-Timestamp) Retrieving app layout…" -ForegroundColor Cyan

    $request = @{
        jsonrpc = "2.0"
        id      = (Get-NextRequestId)
        handle  = $appHandle
        method  = "GetAppLayout"
        params  = @()
    }

    $response = Send-QlikRequest -client $ws -request $request -WriteHost $WriteHost
    if ($response.result) {
        return $response
        Write-Host "$(Get-Timestamp) App layout retrieved" -ForegroundColor Green
    } else {
        Write-Host "$(Get-Timestamp) ERROR retrieving App layout" -ForegroundColor Red
    }

}
function Set-QlikAppScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.WebSockets.ClientWebSocket]$client,

        [Parameter(Mandatory = $true)]
        [int]$appHandle,

        [Parameter(Mandatory = $true)]
        [string]$scriptText,

        [bool]$WriteHost = $true
    )

    Write-Host "$(Get-Timestamp) Setting new Qlik script..." -ForegroundColor Cyan

    $request = @{
        jsonrpc = "2.0"
        method  = "SetScript"
        handle  = $appHandle
        params  = @{
            qScript = $scriptText
        }
        id = (Get-NextRequestId)
    }

    try {
        $response = Send-QlikRequest -client $client -request $request -WriteHost $WriteHost

        if ($response.result) {
            Write-Host "$(Get-Timestamp) Script successfully set." -ForegroundColor Green
            return $true
        } else {
            Write-Host "$(Get-Timestamp) ERROR: Script not set." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "$(Get-Timestamp) ERROR during SetScript: $_" -ForegroundColor Red
        return $false
    }
}