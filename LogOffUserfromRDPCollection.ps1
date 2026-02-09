<#
Written by Clemens Bayer / 07.12.2022
#>

[CmdletBinding()]
param(
    # Enter the connection broker as an FQDN.
    [string]$ConnectionBroker = "servername.fqdn"
)

if ($ConnectionBroker -eq "servername.fqdn") {
    $ConnectionBroker = Read-Host -Prompt "Enter Connection Broker FQDN"
}

do {
    $user = Read-Host -Prompt "Enter Username you want to disconnect"
} while ([string]::IsNullOrWhiteSpace($user))

Write-Host "Requesting needed data now..."

try {
    $sessions = Get-RDUserSession -ConnectionBroker $ConnectionBroker -ErrorAction Stop
} catch {
    Write-Host "Failed to query sessions from $ConnectionBroker. $($_.Exception.Message)"
    return
}

$matchingSessions = $sessions | Where-Object { $_.UserName -eq $user }

if (-not $matchingSessions) {
    Write-Host "Account $user is not logged in!"
    return
}

if ($matchingSessions.Count -gt 1) {
    Write-Host "Multiple sessions found for $user:"
    $matchingSessions |
        Select-Object @{Name = "Index"; Expression = { [array]::IndexOf($matchingSessions, $_) + 1 } }, UnifiedSessionID, HostServer, SessionState |
        Format-Table -AutoSize

    do {
        $selection = Read-Host -Prompt "Enter the session index to log off"
    } while (-not ($selection -as [int]) -or $selection -lt 1 -or $selection -gt $matchingSessions.Count)

    $matchingSessions = @($matchingSessions[$selection - 1])
}

foreach ($session in $matchingSessions) {
    Write-Host "Session ID is: $($session.UnifiedSessionID)"
    Write-Host "Hostserver is: $($session.HostServer)"
    Write-Host "Account $user with Session ID $($session.UnifiedSessionID) can be logged off from Server $($session.HostServer) now"

    $menu = Read-Host -Prompt "Log off user? (y/n)"
    if ($menu -ne "y") {
        Write-Host "Skipping logoff for session $($session.UnifiedSessionID)."
        continue
    }

    Invoke-RDUserLogoff -HostServer $session.HostServer -UnifiedSessionID $session.UnifiedSessionID -Force
}

Start-Sleep 5

$remainingSessions = Get-RDUserSession -ConnectionBroker $ConnectionBroker | Where-Object { $_.UserName -eq $user }
if ($remainingSessions) {
    $remainingIds = ($remainingSessions | Select-Object -ExpandProperty UnifiedSessionID) -join ", "
    Write-Host "Something went wrong, Account $user is still logged in with Session(s) $remainingIds, please check manually."
} else {
    Write-Host "Account $user is logged off now!"
}
