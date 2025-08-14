# ssd_smart_summary.ps1  — PowerShell 5.1 compatible
# Summarizes SMART for SATA + NVMe using smartctl; maps to Storage Spaces PhysicalDisk when possible.
# Outputs a table and saves CSV to Desktop as ssd_smart_summary.csv


#---------------- run timestamp ----------------
# One timestamp per execution, ISO 8601 with offset (e.g., 2025-08-14T07:22:33.1234567-07:00)
$RunAt = (Get-Date).ToString('o')

#---------------- helpers ----------------
function Get-Value { param([string]$Text,[string]$Pattern,[int]$Group=1)
  $m = [regex]::Match($Text,$Pattern,'IgnoreCase,Multiline')
  if($m.Success){ $m.Groups[$Group].Value.Trim() } else { $null }
}
function Get-FirstNumber { param([string]$Line)
  $m = [regex]::Match($Line,'(\d{1,})')
  if($m.Success){ [decimal]$m.Groups[1].Value } else { $null }
}

#---------------- locate smartctl ----------------
# --- ensure smartmontools is installed (winget -> choco fallback) ---
$smartPath = 'C:\Program Files\smartmontools\bin\smartctl.exe'
if (-not (Test-Path $smartPath)) {
  $installed = $false

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing smartmontools via winget..."
    $wgArgs = 'install --id=smartmontools.smartmontools -e --accept-package-agreements --accept-source-agreements --scope machine'
    Start-Process -FilePath 'winget' -ArgumentList $wgArgs -Wait -WindowStyle Hidden | Out-Null
    if (Test-Path $smartPath) { $installed = $true }
  }

  if (-not $installed -and (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing smartmontools via Chocolatey..."
    Start-Process -FilePath 'choco' -ArgumentList 'install smartmontools -y' -Wait -NoNewWindow | Out-Null
    if (Test-Path $smartPath) { $installed = $true }
  }

  if (-not $installed) { throw "smartctl not found and auto-install failed. Please install smartmontools and re-run." }
}

$smart = (Get-Command smartctl -ErrorAction SilentlyContinue).Source
if(-not $smart){ $smart = 'C:\Program Files\smartmontools\bin\smartctl.exe' }
if(-not (Test-Path $smart)){ throw "smartctl not found. Install smartmontools or add it to PATH." }

#---------------- enumerate devices ----------------
$scan = & $smart --scan
$devList = @()
foreach($line in $scan){
  if($line -match '(/dev/\S+|\\\\\.\\PhysicalDrive\d+)'){ $devList += $matches[1] }
}
$devs = $devList | Sort-Object -Unique

#---------------- storage spaces inventory (best effort) ----------------
try { $pd = Get-PhysicalDisk | Select FriendlyName,SerialNumber,UniqueId,DeviceId,HealthStatus } catch { $pd = @() }

$rows = @()

foreach($dev in $devs){
  $out = & $smart -x $dev 2>$null | Out-String

  $isNVMe = ($dev -like "*/nvme*") -or ($out -match 'NVMe')

  $model  = Get-Value $out 'Device Model:\s*(.+)$'; if(-not $model){ $model = Get-Value $out 'Model Number:\s*(.+)$' }
  $serial = Get-Value $out 'Serial Number:\s*([^\r\n]+)'
  $cap    = Get-Value $out 'User Capacity:\s*[0-9,]+\s+bytes\s+\[([^\]]+)\]'

  $temp = Get-Value $out 'Current Temperature:\s*(\d+)\s*C'
  if(-not $temp){ $temp = Get-Value $out 'Temperature(?:_Celsius)?:\s*(\d+)' }

  $poh = Get-Value $out 'Power-on Hours\s+(\d+)\s'
  if(-not $poh){ $poh = Get-Value $out 'Power On Hours:\s*(\d+)' }

  # SMART overall health (optional)
  $health = $null
  if($out -match 'SMART overall-health.*?:\s*(.+)$'){ $health = $Matches[1].Trim() }

  #---------------- endurance used (%) ----------------
  $usedPct = $null
  if($isNVMe){
    # e.g., "Percentage Used: 1%"
    $usedPct = Get-Value $out 'Percentage Used:\s*(\d+)\s*%'
  } else {
    # Prefer Device Statistics line (solid and unambiguous):
    # "0x07  0x008  1               1  N--  Percentage Used Endurance Indicator"
    $usedPct = Get-Value $out '^\s*0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s+\d+\s+(\d+)\s+[A-Z-]+\s+Percentage Used Endurance Indicator'
    if(-not $usedPct){
      # Fallback: SMART attribute 202 "Percent_Lifetime_Remain"
      $a202 = ($out -split "`n") | Where-Object { $_ -match '^\s*202\s+Percent_Lifetime_Remain' } | Select-Object -First 1
      if($a202){
        # Try to infer remaining vs used
        $nums = [regex]::Matches($a202,'(\d+)') | ForEach-Object { [int]$_.Groups[1].Value }
        if($nums.Count -ge 2){
          $norm = $nums[1]; # normalized "VALUE" often 100..0 remaining
          if($norm -ge 0 -and $norm -le 100){ $usedPct = 100 - $norm }
        }
      }
    }
  }

  #---------------- host writes (TB) ----------------
  [decimal]$tbw = 0
  if($isNVMe){
    # NVMe: "Data Units Written: N" (1 DU = 512,000 bytes)
    $du = Get-Value $out 'Data Units Written:\s*([0-9,]+)'
    if($du){ $units = [decimal]($du -replace ',',''); $tbw = [math]::Round(($units * 512000) / 1e12, 2) }
  } else {
    # SATA: prefer Device Statistics "Logical Sectors Written"
    $lswLine = ($out -split "`n") | Where-Object { $_ -match '\bLogical Sectors Written\b' } | Select-Object -First 1
    if($lswLine){
      # This line has offsets + size + VALUE; capture the VALUE column reliably:
      # "0x01  0x018  6    246370875994  ---  Logical Sectors Written"
      $val = Get-Value $lswLine '^\s*0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s+\d+\s+(\d+)'
      if($val){ $tbw = [math]::Round(([decimal]$val * 512) / 1e12, 2) }
    } else {
      # Fallback to SMART attributes like 241/246 "Total_LBAs_Written"
      $a241 = ($out -split "`n") | Where-Object { $_ -match '^\s*24[16]\s+.*Total_LBAs_Written' } | Select-Object -First 1
      if($a241){
        $nums = [regex]::Matches($a241,'(\d+)') | ForEach-Object { [decimal]$_.Groups[1].Value }
        if($nums.Count -ge 1){
          $raw = $nums[$nums.Count-1]  # RAW_VALUE is usually last number
          $tbw = [math]::Round(($raw * 512) / 1e12, 2)
        }
      }
    }
  }

  #---------------- map to Storage Spaces PhysicalDisk ----------------
  $pdName = $null; $pdHealth = $null
  if($serial -and $pd.Count){
    $match = $pd | Where-Object {
      ($_.SerialNumber -and $_.SerialNumber -like "*$serial*") -or
      ($_.UniqueId     -and $_.UniqueId     -like "*$serial*")
    } | Select-Object -First 1
    if(-not $match -and $serial.Length -gt 8){
      $tail = $serial.Substring($serial.Length-8,8)
      $match = $pd | Where-Object {
        ($_.SerialNumber -and $_.SerialNumber -like "*$tail*") -or
        ($_.UniqueId     -and $_.UniqueId     -like "*$tail*")
      } | Select-Object -First 1
    }
    if($match){ $pdName = $match.FriendlyName; $pdHealth = $match.HealthStatus }
  }

  $rows += [pscustomobject]@{
    Device           = $dev
    Model            = $model
    Serial           = $serial
    Capacity         = $cap
    EnduranceUsedPct = if($usedPct -ne $null){ [int]$usedPct } else { $null }
    HostTBWritten    = $tbw
    TempC            = if($temp){ [int]$temp } else { $null }
    PowerOnHours     = if($poh){ [int]$poh } else { $null }
    SmartHealth      = $health
    PD_FriendlyName  = $pdName
    PD_Health        = $pdHealth
  }
}

  #---------------- Generate CSV Output ----------------
$rows = $rows | Sort-Object PD_FriendlyName, Model
$rows | Format-Table -Auto   # keep on-screen table unchanged

$csvPath = Join-Path $env:USERPROFILE "Desktop\ssd_smart_summary.csv"

# --- One-time upgrade: if the existing CSV lacks DateRun, add it using the file's last write time ---
if (Test-Path $csvPath) {
  $hdr = (Get-Content -Path $csvPath -TotalCount 1)
  if ($hdr -and $hdr -notmatch '(?i)\bDateRun\b') {
    try {
      $existing = Import-Csv -Path $csvPath
      $stamp = (Get-Item $csvPath).LastWriteTime.ToString('o')
      foreach ($r in $existing) {
        if (-not $r.PSObject.Properties['DateRun']) {
          $r | Add-Member -NotePropertyName DateRun -NotePropertyValue $stamp
        }
      }
      # Preserve existing column order, but put DateRun first to match future exports
      $cols = @('DateRun') + ($existing[0].PSObject.Properties.Name | Where-Object { $_ -ne 'DateRun' })
      $existing | Select-Object $cols | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath
    } catch {
      Write-Warning "Could not upgrade existing CSV to include DateRun: $_"
    }
  }
}

# --- Append the current run, with DateRun added but not shown in the on-screen table ---
$exportRows = $rows | Select-Object @{Name='DateRun';Expression={$RunAt}}, *
if (Test-Path $csvPath) {
  $exportRows | Export-Csv -NoTypeInformation -Encoding UTF8 -Append -Path $csvPath
} else {
  $exportRows | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath
}
"Saved: $csvPath"
