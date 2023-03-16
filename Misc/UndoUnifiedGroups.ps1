param($Mailbox) #Must be the first statement in your script.
 
while (!$Mailbox) { [string]$mailbox = Read-Host "Enter mailbox name" }
 
$mbname = Get-Mailbox -Identity $Mailbox -ErrorAction SilentlyContinue
 
if (!$mbname) { Write-Error "Mailbox $Mailbox not found" -Category OperationStopped -ErrorAction Stop }
 
$manager = (get-user $mbname.UserPrincipalName).manager
 
while (!$manager) { [string]$manager = Read-Host "Groups need at least one Manager, please enter name" }
 
$delegates = Get-MailboxPermission $mbname.UserPrincipalName | ? {$_.IsInherited -ne $true -and $_.User -ne "NT AUTHORITY\SELF"}
 
$trustees = Get-RecipientPermission $mbname.UserPrincipalName
 
 
 
Remove-Mailbox $mbname.UserPrincipalName -Confirm:$true
 
sleep 5
 
# Create new DG with the same email address and name, and set at least one manager
 
$DG = New-DistributionGroup -Name $mbname.Name -DisplayName $mbname.DisplayName -ManagedBy $manager -PrimarySmtpAddress $mbname.PrimarySMTPAddress -Alias $mbname.Alias
 
# Configure the rest of the settings as needed
 
Set-DistributionGroup $DG.Identity -GrantSendOnBehalfTo $mbname.grantsendonbehalfto -MailTip $mbname.MailTip -EmailAddresses $($mbname.EmailAddresses | ? {$_ -notlike "sip:*"})
 
# Add each person that had rights on the shared mailbox as member of the DG
 
foreach ($delegate in $delegates) { Add-DistributionGroupMember -Identity $DG.Identity -Member $delegate.user }
 
# Add Send As permissions
 
foreach ($trustee in $trustees) { Add-RecipientPermission -Identity $DG.Identity -Trustee $trustee.Trustee -AccessRights $trustee.AccessRights -Confirm:$false } 