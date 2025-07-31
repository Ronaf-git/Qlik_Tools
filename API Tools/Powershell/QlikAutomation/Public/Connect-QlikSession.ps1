function Connect-QlikSession {
    param (
        [uri]$Url,
        [string]$CookieName
    )

    if ($Url.Scheme -eq 'ws') {
        # If it's a ws or wss URL, connect directly
        return Connect-WebSocket -URL $Url
    }

    # For https/http URLs, retrieve session and cookie
    $session = Invoke-WebRequest -Uri "https://$($Url.Host)/hub" -SessionVariable session -UseDefaultCredentials

    $cookieValue = ($session | Get-WebSessionCookies | Where-Object { $_.Name -eq $CookieName }).Value

    if ($cookieValue) {
        $cookie = "$CookieName=$cookieValue"
        return Connect-WebSocket -URL $Url -cookie $cookie
    } else {
        Write-Warning "Cookie '$CookieName' not found. Connecting without a cookie."
        return Connect-WebSocket -URL $Url
    }
}
