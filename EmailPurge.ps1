# This script performs the following actions:
# Connects to an IPPS session.
# Prompts the user to enter the ticket number for an incident, the user's email address, and the subject of an email.
# Outputs the values entered by the user to confirm they are correct.
# Starts a compliance search using the values entered by the user, searching for emails from the specified email address with the specified subject.
# Prompts the user to confirm when the search has completed.
# Begins a purge of the search results, using a "hard delete" to permanently remove the emails.
# Prompts the user to confirm when the purge has completed.
# Disconnects from the Exchange Online session

do {
Connect-IPPSSession

# Prompt the user for the ticket # of this incident
$IncidentTicket = Read-Host "Please enter the CW ticket #"

# Prompt the user for their email address
$UserEmail = Read-Host "Please enter the email address"

# Prompt the user for the email subject
$EmailSubject = Read-Host "Please enter the subject of the email (partial is OK)"

# Prompt the user for the date range the email was sent between:
$ReceivedDate = Read-Host -Prompt 'Enter date range the email was sent between: (mm/dd/yyyy..mm/dd/yyyy)'


# Output the value of the $UserEmail variable
Write-Output "Please confirm the following values are correct:"
Write-Output " "
Write-Output "Ticket #: $IncidentTicket"
Write-Output "Email: $UserEmail"
Write-Output "Subject: $EmailSubject"
Write-Output "Received Date: $ReceivedDate"

$Confirm = Read-Host -Prompt 'Does the data all look correct? (y/n)'

} while ($Confirm -ne 'y')

# Start compliance search built from above values
$Search=New-ComplianceSearch -Name "$IncidentTicket" -ExchangeLocation All -ContentMatchQuery '(From:$UserEmail) AND (Subject:"$EmailSubject")'
Start-ComplianceSearch -Identity $Search.Identity

Write-Output "Starting Search"

do{
Get-ComplianceSearch
$Confirm2 = Read-Host -Prompt 'Check status of search (you may have to scroll down).....Has it completed? (y/n)'
} while ($Confirm2 -ne 'y')

Write-Output "Beginning purge of emails"

# Start the purge / HardDelete of search results
New-ComplianceSearchAction -SearchName "$IncidentTicket" -Purge -PurgeType HardDelete
do{
Get-ComplianceSearchAction
$Confirm2 = Read-Host -Prompt 'Check status of purge.....Has it completed? Please wait a few minutes before each response (y/n)'
} while ($Confirm2 -ne 'y')

Write-Output "Process complete. Disconnecting session."

# Disconnect session
Disconnect-ExchangeOnline -Confirm:$false