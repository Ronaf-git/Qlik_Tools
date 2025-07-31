function Get-Timestamp {
    return (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Is-Numeric($v) {
    return ($v -is [int] -or $v -is [double] -or $v -is [decimal] -or $v -is [long])
}

$global:QlikRequestId = 1
function Get-NextRequestId {
    $var = $global:QlikRequestId++
    return ${var}
}