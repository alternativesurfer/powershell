# EmailPurge.ps1
# Connects to Security & Compliance (IPPS) session.
# Prompts for ticket number, sender email, subject, and received date range.
# Runs a targeted compliance search across all mailboxes.
# Confirms search completion, then performs a HardDelete purge.
# Disconnects session on completion.

# Connect once -- outside the confirmation loop
Connect-IPPSSession

do {
    # Prompt the user for the ticket # of this incident
    $IncidentTicket = Read-Host "Please enter the CW ticket #"

    # Prompt the user for the sender's email address
    $UserEmail = Read-Host "Please enter the sender's email address"

    # Prompt the user for the email subject (partial OK)
    $EmailSubject = Read-Host "Please enter the subject of the email (partial is OK)"

    # Prompt for date range (format: mm/dd/yyyy..mm/dd/yyyy)
    $ReceivedDate = Read-Host "Enter date range the email was received (mm/dd/yyyy..mm/dd/yyyy)"

    # Confirm values
    Write-Output " "
    Write-Output "Please confirm the following values are correct:"
    Write-Output " "
    Write-Output "  Ticket #:       $IncidentTicket"
    Write-Output "  Sender Email:   $UserEmail"
    Write-Output "  Subject:        $EmailSubject"
    Write-Output "  Received Date:  $ReceivedDate"
    Write-Output " "

    $Confirm = Read-Host "Does the data all look correct? (y/n)"
} while ($Confirm -ne 'y')

# Build the KQL query -- double quotes used so variables expand correctly
# ReceivedDate is included in the search query
$SearchQuery = "(From:$UserEmail) AND (Subject:`"$EmailSubject`") AND (Received:$ReceivedDate)"

Write-Output " "
Write-Output "Search query: $SearchQuery"
Write-Output " "

# Create and start the compliance search
$Search = New-ComplianceSearch -Name "$IncidentTicket" -ExchangeLocation All -ContentMatchQuery $SearchQuery
Start-ComplianceSearch -Identity $Search.Identity
Write-Output "Search started: $IncidentTicket"

# Poll until user confirms the search is complete -- filtered to this ticket only
do {
    Get-ComplianceSearch -Identity "$IncidentTicket" | Select-Object Name, Status, Items, Size | Format-Table -AutoSize
    $Confirm2 = Read-Host "Has the search completed? (y/n)  -- 'n' refreshes status"
} while ($Confirm2 -ne 'y')

Write-Output " "
Write-Output "Beginning HardDelete purge of search results..."

# Purge the results
New-ComplianceSearchAction -SearchName "$IncidentTicket" -Purge -PurgeType HardDelete -Confirm:$false

# Poll until user confirms the purge is complete -- filtered to this ticket only
do {
    Get-ComplianceSearchAction -Identity "${IncidentTicket}_Purge" | Select-Object Name, Status, Results | Format-Table -AutoSize
    $Confirm3 = Read-Host "Has the purge completed? (y/n)  -- 'n' refreshes status (allow a few minutes between checks)"
} while ($Confirm3 -ne 'y')

Write-Output " "
Write-Output "Process complete. Disconnecting session."

# Disconnect
Disconnect-ExchangeOnline -Confirm:$false
