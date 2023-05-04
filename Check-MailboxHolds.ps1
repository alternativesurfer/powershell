#Import Exchange Online Module
Import-Module ExchangeOnlineManagement

Write-Output "We are now connecting to ExchangeOnline"

#Connects to the Tenants Exchange Online (MFA Allowed)
Connect-ExchangeOnline

#Takes User input to select the mailbox for lookup
$Mailbox = Read-Host "Which mailbox would you like to check for holds?"


Write-Output "We are now checking for any mailbox holds....."

Write-Output "Litigation Holds:"
Get-Mailbox $Mailbox | FL LitigationHold*

Write-Output "In-Place User Holds:"
Get-Mailbox $Mailbox | FL LitigationHoldEnabled,InPlaceHolds

Write-Output "Compliance Holds:"
Get-Mailbox $Mailbox | FL ComplianceTagHoldApplied

Write-Output "Misc Holds:"
Get-Mailbox $Mailbox | FL *HoldApplied*

Write-Output "Delay Holds:"
Get-Mailbox $Mailbox | Select-Object -ExpandProperty InPlaceHolds

Write-Output "We are now checking for any organization holds...."

Write-Output "In-Place Org Holds:"
Get-OrganizationConfig | FL InPlaceHolds

Write-Output "Listing Org Hold GUIDs:"
Get-OrganizationConfig | Select-Object -ExpandProperty InPlaceHolds

#Lookup info about any GUID Holds
do{
$Confirm = Read-Host -Prompt 'Are there are any hold GUIDs listed? (y/n)'

} while ($Confirm -ne 'y')
Connect-IPPSSession

$HoldGUID = Read-Host "Please enter a GUID for lookup (excluding the prefix)"
$CaseHold = Get-CaseHoldPolicy $HoldGUID
Get-ComplianceCase $CaseHold.CaseId | FL Name
$CaseHold | FL Name,ExchangeLocation

#End The Session
Disconnect-ExchangeOnline -Confirm:$false
Get-PSSession | Disconnect-PSSession