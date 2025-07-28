<#
.SYNOPSIS
    Uninstall Intel network adapters & drivers, then auto‑install new drivers after reboot.

.DESCRIPTION
    1. Scans for PnP network devices where Manufacturer or FriendlyName contains "Intel".
    2. Uninstalls each matching device.
    3. Scans the online driver store for Intel network driver packages and removes them.
    4. Creates a one‑time Scheduled Task that runs at startup to scan & install new drivers.
    5. Optionally reboots the machine.

.PARAMETER Reboot
    If specified, will schedule the rescan task and then reboot in 15 seconds.

.EXAMPLE
    # Dry‑run to see what would be removed or scheduled
    .\Refresh-IntelNet.ps1 -WhatIf

    # Actually remove, schedule driver rescan, then reboot
    .\Refresh-IntelNet.ps1 -Reboot
#>

[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
param(
    [switch]$Reboot
)

function Uninstall-IntelNetDevices {
    Write-Host "`n==> Scanning for Intel network adapters..." -ForegroundColor Cyan
    $devices = Get-PnpDevice -Class Net | Where-Object {
        ($_.Manufacturer -like '*Intel*') -or ($_.FriendlyName -like '*Intel*')
    }

    if (-not $devices) {
        Write-Warning "No Intel network adapters found."
        return
    }

    foreach ($dev in $devices) {
        Write-Host "  • Found: $($dev.FriendlyName) [$($dev.InstanceId)]" -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($dev.InstanceId, 'Uninstall PnP device')) {
            # Uninstall the device (this will also remove it from Device Manager)
            Remove-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false
            Write-Host "    → Device uninstalled." -ForegroundColor Yellow
        }
    }
}

function Uninstall-IntelNetDrivers {
    Write-Host "`n==> Scanning driver store for Intel network packages..." -ForegroundColor Cyan
    $drivers = Get-WindowsDriver -Online | Where-Object {
        ($_.ProviderName -like '*Intel*') -and ($_.ClassName -eq 'Net')
    }

    if (-not $drivers) {
        Write-Warning "No Intel network driver packages found in the store."
        return
    }

    foreach ($drv in $drivers) {
        Write-Host "  • Found: $($drv.PublishedName)" -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($drv.PublishedName, 'Remove driver package')) {
            Remove-WindowsDriver -Online -Driver $drv.PublishedName
            Write-Host "    → Driver package removed." -ForegroundColor Yellow
        }
    }
}

function Schedule-DriverRescan {
    <#
    Creates a one‑time Scheduled Task named "IntelNetDriverRescan" that:
      • Runs at system startup
      • Executes: pnputil /scan-devices && schtasks /Delete /TN IntelNetDriverRescan /F
    #>
    $taskName = 'IntelNetDriverRescan'
    $action   = "cmd.exe /c `"pnputil /scan-devices && schtasks /Delete /TN $taskName /F`""
    $create  = "schtasks /Create /SC ONSTART /TN $taskName /TR $action /RL HIGHEST /F"

    Write-Host "`n==> Scheduling one‑time driver rescan at next boot..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess($taskName, 'Create scheduled task')) {
        Invoke-Expression $create
        Write-Host "    → Task '$taskName' created." -ForegroundColor Yellow
    }
}

# Ensure we’re elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# Main
Uninstall-IntelNetDevices
Uninstall-IntelNetDrivers

if ($Reboot) {
    Schedule-DriverRescan
    Write-Host "`nAll set. Rebooting in 15 seconds to trigger driver re‑install..." -ForegroundColor Magenta
    Shutdown.exe /r /t 15 /c "Rebooting to auto‑install new Intel network driver"
}
else {
    Write-Host "`nDone. If you’d like Windows to fetch & install a fresh Intel driver, re‑run with -Reboot." -ForegroundColor Cyan
}
