# Moves all messages from Inbox\inbox-bak to the primary Inbox
# Runs with Graph application permissions. No user credentials required.

# Target mailbox and folder names
$UserUpn = 'EMAIL@domain.com'
$SourceChildFolderName = 'inbox-bak'

# Connect to Graph using the app registration
Connect-MgGraph -TenantId 'TENANT-ID' -ClientId 'CLIENT/APP ID' -CertificateThumbprint 'CERT THUMBPRINT'
Select-MgProfile -Name 'v1.0'


# 1) Resolve the well-known Inbox
$Inbox = Get-MgUserMailFolder -UserId $UserUpn -MailFolderId 'inbox'
if (-not $Inbox) { throw "Could not resolve Inbox for $UserUpn." }

# 2) Find the child folder named inbox-bak directly under Inbox
$Bak = Get-MgUserMailFolderChildFolder -UserId $UserUpn -MailFolderId $Inbox.Id -All |
       Where-Object { $_.DisplayName -eq $SourceChildFolderName }

if (-not $Bak) { throw "Folder '$SourceChildFolderName' was not found directly under Inbox for $UserUpn." }

Write-Host "Moving items from '$($Bak.DisplayName)' to 'Inbox' for $UserUpn ..."

# 3) Move all messages, with simple retry on throttling
$moveCount = 0
Get-MgUserMailFolderMessage -UserId $UserUpn -MailFolderId $Bak.Id -All -Property 'id' -PageSize 100 |
ForEach-Object {
    $msg = $_
    $attempts = 0
    while ($true) {
        try {
            Move-MgUserMessage -UserId $UserUpn -MessageId $msg.Id -DestinationId $Inbox.Id | Out-Null
            $moveCount++
            if (($moveCount % 200) -eq 0) { Write-Host "Moved $moveCount items..." }
            break
        } catch {
            $attempts++
            $err = $_.Exception.Message
            if ($err -match 'StatusCode: 429' -and $attempts -lt 6) {
                Start-Sleep -Seconds 8
            } else {
                throw
            }
        }
    }
}

Write-Host "Done. Moved $moveCount messages from '$($Bak.DisplayName)' to Inbox."

# 4) Quick check for leftovers
$remaining = Get-MgUserMailFolderMessage -UserId $UserUpn -MailFolderId $Bak.Id -PageSize 1
if ($remaining) {
    Write-Warning "Some items remain in '$($Bak.DisplayName)'. Rerun or investigate large or locked items."
} else {
    Write-Host "Source folder is now empty."
}

Disconnect-MgGraph
