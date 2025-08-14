# One-time setup (same user the task will run as)

$credDir  = 'C:\Secure\MailCreds'
$credPath = Join-Path $credDir 'gmail_smtp.cred.xml'
New-Item -ItemType Directory -Force -Path $credDir | Out-Null

$User = 'USERNAME@domain.com'
$SecurePass = Read-Host "Enter Gmail App Password for $User" -AsSecureString
$Cred = New-Object System.Management.Automation.PSCredential($User, $SecurePass)
$Cred | Export-Clixml -Path $credPath

# --- FIXED ACLS (quote + brace the variable) ---
$me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name  # e.g. 'MYPC\USERNAME'

icacls 'C:\Secure\MailCreds'                /inheritance:r `
  /grant:r "${me}:(OI)(CI)F" "BUILTIN\Administrators:(OI)(CI)F" | Out-Null

icacls 'C:\Secure\MailCreds\gmail_smtp.cred.xml' /inheritance:r `
  /grant:r "${me}:F" "BUILTIN\Administrators:F" | Out-Null
