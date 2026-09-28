Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "                Revert to DHCP" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Detecting active network adapters:" -ForegroundColor Yellow
Write-Host "---------------------------------------------------"
Write-Host ("{0,-7} {1}" -f "Index", "Adapter Name (Description)")
Write-Host ("{0,-7} {1}" -f "-----", "--------------------------")

Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {
    "{0,-7} {1} ({2})" -f $_.InterfaceIndex, $_.Name, $_.InterfaceDescription
}
Write-Host "---------------------------------------------------"
Write-Host ""

$Idx = Read-Host "Enter the [Index] number of your adapter to restore"
if ([string]::IsNullOrWhiteSpace($Idx)) {
    Write-Host "[ERROR] Index cannot be empty!" -ForegroundColor Red
    Pause
    exit
}

$TargetAdapter = Get-NetAdapter -InterfaceIndex $Idx -ErrorAction SilentlyContinue
if (-not $TargetAdapter) {
    Write-Host "[ERROR] Invalid Index number!" -ForegroundColor Red
    Pause
    exit
}

Write-Host ""
Write-Host "Reconfiguring network via DHCP, please wait..." -ForegroundColor Yellow
Write-Host "---------------------------------------------------"

try {
    Set-NetIPInterface -InterfaceIndex $Idx -Dhcp Enabled -ErrorAction Stop
    Set-DnsClientServerAddress -InterfaceIndex $Idx -ResetServerAddresses -ErrorAction Stop
    
    Write-Host "Renewing IP address from your router..." -ForegroundColor Yellow
    Update-NetIPAddress -InterfaceIndex $Idx -ErrorAction SilentlyContinue
    Clear-DnsClientCache
    
    Write-Host "---------------------------------------------------"
    Write-Host "🎉 SUCCESS! DHCP Restored. Current Active Settings:" -ForegroundColor Green
    Write-Host "---------------------------------------------------"
    Get-NetIPConfiguration -InterfaceIndex $Idx
} catch {
    Write-Host "[ERROR] Failed to restore DHCP: $_" -ForegroundColor Red
}

Write-Host ""
Pause
