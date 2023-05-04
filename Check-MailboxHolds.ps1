$Mailbox = Read-Host "Which mailbox would you like to check for holds?"

Write-Output "We are now connecting to ExchangeOnline"
Connect-ExchangeOnline

Write-Output "We are now checking for any mailbox holds."

Get-Mailbox $Mailbox | FL LitigationHold*
Get-Mailbox $Mailbox | FL LitigationHoldEnabled,InPlaceHolds
Get-Mailbox <username> | FL ComplianceTagHoldApplied
Get-Mailbox <username> | FL *HoldApplied*
Get-Mailbox <username> | Select-Object -ExpandProperty InPlaceHolds

Write-Output "We are now checking for any organization holds."
Get-OrganizationConfig | FL InPlaceHolds
Get-OrganizationConfig | Select-Object -ExpandProperty InPlaceHolds
