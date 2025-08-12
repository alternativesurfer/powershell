# run_ssd_smart_summary.ps1
$out = 'C:\Logs\SSD-SMART'
New-Item -ItemType Directory -Force -Path $out | Out-Null

# Run the summary script
& 'C:\Scripts\ssd_smart_summary.ps1' | Out-Null

# Find the CSV (Desktop from your summary script; fall back to Logs if you changed it)
$src = Join-Path $env:USERPROFILE 'Desktop\ssd_smart_summary.csv'
if(-not (Test-Path $src)) { $src = Join-Path $out 'ssd_smart_summary.csv' }

# Timestamp + rotate 12
if(Test-Path $src){
  $ts = Get-Date -Format yyyyMMdd_HHmmss
  $dst = Join-Path $out "ssd_smart_$ts.csv"
  Copy-Item $src $dst -Force
  Get-ChildItem $out -Filter '*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 12 | Remove-Item -Force
} else {
  Write-Error "CSV not found at $src"
}
