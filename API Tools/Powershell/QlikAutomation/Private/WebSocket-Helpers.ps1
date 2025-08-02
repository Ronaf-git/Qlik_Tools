function Send-QlikRequest {
    param (
        [System.Net.WebSockets.ClientWebSocket]$client,
        [hashtable]$request,
        [bool]$WriteHost = $true
    )
    # wrapper for exchange with Qlik Websocket
    $json = ConvertTo-Json $request -Depth 10
    Send-JsonMessage -client $client -json $json -WriteHost $WriteHost
    $response = Receive-JsonMessage -client $client -WriteHost $WriteHost

    return $response | ConvertFrom-Json
}

function Connect-WebSocket {
    param (
        [uri]$URL,           # WebSocket URL
        [string]$cookie      # Cookie for the request header (optional)
    )

    Write-Host "$(Get-Timestamp) Try to connect to websocket ${URL}..." -ForegroundColor Cyan

    try {
        $client = [System.Net.WebSockets.ClientWebSocket]::new()

        if ($cookie) {
            $headersProperty = $client.GetType().GetProperty("Options")
            $headers = $headersProperty.GetValue($client, $null)
            $headers.SetRequestHeader("Cookie", $cookie)
        }

        $connectionTask = $client.ConnectAsync($URL, [System.Threading.CancellationToken]::None)
        $connectionTask.Wait()

        if ($client.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
            Write-Host "$(Get-Timestamp) Connexion WebSocket Success." -ForegroundColor Green
        } else {
            Write-Host "$(Get-Timestamp) Connexion WebSocket Failed." -ForegroundColor Red
        }

        $origin = "$($URL.Scheme)://$($URL.Host)"
        if ($URL.IsDefaultPort -eq $false) {
            $origin += ":$($URL.Port)"
        }
        $client | Add-Member -MemberType NoteProperty -Name "WebSocketOrigin" -Value $origin
        return $client
    }
    catch {
    if ($_.Exception -is [AggregateException]) {
        $_.Exception.InnerExceptions | ForEach-Object {
            Write-Error "$(Get-Timestamp) WebSocket Error: $($_.ToString())"
        }
    } else {
        Write-Error "$(Get-Timestamp) Error trying to connect to WebSocket : $_"
    }
}
}



<#
.SYNOPSIS
    Gets all session cookies associated with a WebRequest session.

.DESCRIPTION
    Returns all cookies stored in a WebRequestSession object (e.g., from Invoke-WebRequest).

.EXAMPLE
    PS C:\> $Response = Invoke-WebRequest -Uri https://www.google.com -SessionVariable Session
    PS C:\> $Session | Get-WebSessionCookies

.INPUTS
    [Microsoft.PowerShell.Commands.WebRequestSession]

.OUTPUTS
    [System.Net.Cookie]

.LINK
    https://www.reddit.com/r/PowerShell/comments/8dfyqy/grab_all_cookies_from_websession_object/?rdt=44170
#>
function Get-WebSessionCookies {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [Alias('Session', 'InputObject')]
        [ValidateNotNull()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebRequestSession
    )
    begin {}
    process {
        $CookieContainer = $WebRequestSession.Cookies
        try {
            [hashtable] $Table = $CookieContainer.GetType().InvokeMember("m_domainTable",
                [System.Reflection.BindingFlags]::NonPublic -bor
                [System.Reflection.BindingFlags]::GetField -bor
                [System.Reflection.BindingFlags]::Instance,
                $null,
                $CookieContainer,
                @()
            )
            Write-Output $Table.Values.Values
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {}
}

function Close-WebSocket {
    param (
        [System.Net.WebSockets.ClientWebSocket]$client
    )

    if ($client -ne $null -and $client.State -eq 'Open') {
        try {
            # Close the WebSocket gracefully
            $client.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Closing connection", [System.Threading.CancellationToken]::None).Wait()
            Write-Host "$(Get-Timestamp) WebSocket connection closed successfully."
        }
        catch {
            Write-Host "$(Get-Timestamp) An error occurred while closing the WebSocket: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "$(Get-Timestamp) WebSocket client is not connected or already closed."
    }

    # Dispose the WebSocket client
    $client.Dispose()
    Write-Host "$(Get-Timestamp) WebSocket client disposed."
}

# -- Functions: Send and receive JSON over WebSocket --
function Send-JsonMessage {
    param (
        [System.Net.WebSockets.ClientWebSocket]$client,
        [string]$json,
        [bool]$WriteHost = $true
    )
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $client.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).Wait()

    if ($WriteHost) {
        Write-Host "====== $(Get-Timestamp) - Sending Request JSON =====" -ForegroundColor Cyan
        Write-Host $json
        Write-Host "=======================================================" -ForegroundColor Cyan
    }
}


function Receive-JsonMessage {
    param (
        [System.Net.WebSockets.ClientWebSocket]$client,
        [bool]$WriteHost = $true
    )

    $buffer = [byte[]]::new(4096)
    $messageStream = New-Object System.IO.MemoryStream

    do {
        $segment = [System.ArraySegment[byte]]::new($buffer)
        $result = $client.ReceiveAsync($segment, [System.Threading.CancellationToken]::None).Result
        $messageStream.Write($buffer, 0, $result.Count)
    } while (-not $result.EndOfMessage)

    $messageStream.Seek(0, 'Begin') | Out-Null
    $reader = New-Object System.IO.StreamReader($messageStream, [System.Text.Encoding]::UTF8)
    $received = $reader.ReadToEnd()

    if ($WriteHost) {
        Write-Host "========= $(Get-Timestamp) - Received JSON =========" -ForegroundColor Magenta
        try {
            $jsonObject = $received | ConvertFrom-Json
            $prettyJson = $jsonObject | ConvertTo-Json -Depth 15
            Write-Host $prettyJson
        } catch {
            Write-Host "$(Get-Timestamp) - Error. Received (raw): $received" -ForegroundColor Red
        }
        Write-Host "=======================================================" -ForegroundColor Magenta
    }

    return $received
}