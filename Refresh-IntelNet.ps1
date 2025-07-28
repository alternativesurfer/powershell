<#
.SYNOPSIS
    Uninstall Intel network drivers & auto‑reinstall fresh ones at next reboot.

.DESCRIPTION
    • Finds all Intel network adapters via WMI (Win32_PnPSignedDriver).  
    • For each one: pnputil /delete-driver <InfName> /uninstall /force  
    • Optionally schedules a one‑time startup task to run pnputil /scan-devices.  
    • Optionally reboots to trigger the installation.

.PARAMETER Reboot
    If passed, schedules the rescan task and then reboots after 15 s.

.EXAMPLE
    # Dry‑run
    .\Refresh-IntelNet.ps1 -WhatIf

    # Remove drivers, schedule rescan & reboot
    .\Refresh-IntelNet.ps1 -Reboot
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]$Reboot
)

function Get-IntelNetDrivers {
    <#
    Returns objects with DeviceName and InfName for Intel NICs.
    #>
    Get-WmiObject Win32_PnPSignedDriver `
      -Filter "DeviceClass='Net' AND Manufacturer LIKE '%Intel%'" |
    Select-Object DeviceName, InfName
}

function Remove-IntelNetDrivers {
    Write-Host "`n==> Removing Intel network drivers…" -ForegroundColor Cyan

    $drivers = Get-IntelNetDrivers
    if (-not $drivers) {
        Write-Warning "No Intel network drivers found."
        return
    }

    foreach ($drv in $drivers) {
        $inf = $drv.InfName
        $dev = $drv.DeviceName
        Write-Host "  • $dev (`$inf`)" -ForegroundColor Green

        if ($PSCmdlet.ShouldProcess("$dev [$inf]", 'Uninstall & delete driver')) {
            pnputil.exe /delete-driver $inf /uninstall /force | Out-Null
            Write-Host "    → Removed." -ForegroundColor Yellow
        }
    }
}

function Schedule-DriverRescan {
    $taskName = 'IntelNetDriverRescan'
    # Will scan for new devices and then delete itself
    $action = 'pnputil /scan-devices && schtasks /Delete /TN ' + $taskName + ' /F'
    $tr     = "cmd.exe /c `"$action`""
    $create = "schtasks /Create /SC ONSTART /TN $taskName /TR `"$tr`" /RL HIGHEST /F"

    Write-Host "`n==> Scheduling one‑time driver rescan at next boot…" -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess($taskName, 'Create scheduled task')) {
        Invoke-Expression $create
        Write-Host "    → Task '$taskName' created." -ForegroundColor Yellow
    }
}

#— Ensure elevation —
$winId     = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($winId)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit 1
}

#— Main execution —
Remove-IntelNetDrivers

if ($Reboot) {
    Schedule-DriverRescan
    Write-Host "`nRebooting in 15 seconds to install new drivers…" -ForegroundColor Magenta
#    Shutdown.exe /r /t 15 /c "Refreshing Intel network drivers"
}
else {
    Write-Host "`nDone. To auto‑install fresh drivers, re‑run with -Reboot." -ForegroundColor Cyan
}
