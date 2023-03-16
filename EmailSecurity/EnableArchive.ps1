# Import the Exchange Online PowerShell module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
Connect-ExchangeOnline

# Enable Auto-Expanding Archives for Org
Set-OrganizationConfig -AutoExpandingArchive

# Get a list of all mailbox users in the organization
$MailboxUsers = Get-Mailbox -ResultSize Unlimited

# Enable email archiving for each mailbox user
foreach ($MailboxUser in $MailboxUsers)
{
  Enable-Mailbox -Identity $MailboxUser.Identity -Archive
}

Disconnect-ExchangeOnline -Confirm:$false
Remove-PSSession *
