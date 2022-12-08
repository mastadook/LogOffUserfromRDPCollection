<#
Written by Clemens Bayer / 07.12.2022
#>

#Enter the connectionbroker as a fqdn
$Connectionbroker = "servername.fqdn"

$user = read-host -prompt 'Enter Username you want to disconnect'

Write-Host "Requesting needed Data now"

$sid = Get-RDUserSession -ConnectionBroker $Connectionbroker | Where-Object -filter {$_.UserName -eq $user} | select -ExpandProperty UnifiedSessionID

if ($sid) {

Write-Host "Session ID is: $sid"

$server = Get-RDUserSession -ConnectionBroker $Connectionbroker | Where-Object -filter {$_.UserName -eq $user} | select -ExpandProperty HostServer

Write-Host "Hostserver is: $server"

Write-Host "Account $user with Session ID $sid can be logged of from Server $server now"

Write-Host -ForegroundColor Green "Log off User?"
Write-Host -ForegroundColor Yellow "y"
Write-Host -ForegroundColor Red "n"

Write-Host -ForegroundColor Yellow "Choose y if you like to LogOff user"
$menu = Read-Host 

if ($menu -eq "y"){

Invoke-RDUserLogoff -HostServer "$server" -UnifiedSessionID $sid -force

Start-Sleep 5

$sidcheck = Get-RDUserSession -ConnectionBroker $Connectionbroker | Where-Object -filter {$_.UserName -eq $user} | select -ExpandProperty UnifiedSessionID

if ($sidcheck) {Write-Host "Something went wrong, Account $user is still logged in with Session $sidcheck, pleease check manually"}

else {Write-Host "Account $user is logged of now!"}}}

else {Write-Host "Account $user is not logged in!"}
