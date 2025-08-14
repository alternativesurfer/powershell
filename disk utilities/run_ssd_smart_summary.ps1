# run_ssd_smart_summary.ps1 — email the CSV via SMTP using DPAPI-encrypted creds

# ---- CONFIG ----
$SmtpServer = 'smtp.gmail.com'
$SmtpPort   = 587           # STARTTLS
$From       = 'SENDER@DOMAIN.com'
$To         = 'RECIPIENT@DOMAIN.com'
$Subject    = "Weekly Drive Endurance Report - Host: $env:COMPUTERNAME"
$Body       = "Attached is the latest SSD SMART summary.`r`nGenerated: $(Get-Date -Format o)`r`nHost: $env:COMPUTERNAME"

# Path to encrypted credential created in the one-time setup
$credPath = 'C:\Secure\MailCreds\gmail_smtp.cred.xml'

# ---- RUN THE SUMMARY SCRIPT ----
& 'C:\Scripts\ssd_smart_summary.ps1' | Out-Null

# ---- LOCATE THE CSV ----
$src = Join-Path $env:USERPROFILE 'Desktop\ssd_smart_summary.csv'
if (-not (Test-Path $src)) { throw "CSV not found at $src." }

# ---- SEND MAIL ----
try {
  if (-not (Test-Path $credPath)) { throw "Credential file not found: $credPath" }
  $Cred = Import-Clixml -Path $credPath

  # Ensure TLS 1.2
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  Send-MailMessage `
    -SmtpServer $SmtpServer `
    -Port $SmtpPort `
    -UseSsl `
    -Credential $Cred `
    -From $From `
    -To $To `
    -Subject $Subject `
    -Body $Body `
    -Attachments $src `
    -DeliveryNotificationOption OnFailure

  Write-Host "Email sent to $To with attachment: $src"
}
catch {
  Write-Error "Failed to send email: $($_.Exception.Message)"
}
################
