# EmailPurge.ps1
# Connects to Security & Compliance (IPPS) session.
# Prompts for ticket number, sender email (optional), subject, and received date range.
# Runs a targeted compliance search across all mailboxes.
# Confirms search completion, then performs a HardDelete purge.
# Disconnects session on completion.

# Connect once -- outside the confirmation loop
Connect-IPPSSession -EnableSearchOnlySession

do {
    # Prompt the user for the ticket # of this incident
    $IncidentTicket = Read-Host "Please enter the CW ticket #"

    # Sender email is optional -- press Enter to skip
    $UserEmail = Read-Host "Please enter the sender's email address (optional, press Enter to skip)"

    # Prompt the user for the email subject (partial OK)
    $EmailSubject = Read-Host "Please enter the subject of the email (partial is OK)"

    # Prompt for date range (format: mm/dd/yyyy..mm/dd/yyyy)
    $ReceivedDate = Read-Host "Enter date range the email was received (mm/dd/yyyy..mm/dd/yyyy)"

    # Confirm values
    Write-Output " "
    Write-Output "Please confirm the following values are correct:"
    Write-Output " "
    Write-Output "  Ticket #:       $IncidentTicket"
    Write-Output "  Sender Email:   $(if ($UserEmail) { $UserEmail } else { '(not specified)' })"
    Write-Output "  Subject:        $EmailSubject"
    Write-Output "  Received Date:  $ReceivedDate"
    Write-Output " "

    $Confirm = Read-Host "Does the data all look correct? (y/n)"
} while ($Confirm -ne 'y')

# Build KQL query -- From is only added if a sender was provided
$QueryParts = @()
if ($UserEmail)     { $QueryParts += "From:$UserEmail" }
if ($EmailSubject)  { $QueryParts += "Subject:`"$EmailSubject`"" }
if ($ReceivedDate)  { $QueryParts += "Received:$ReceivedDate" }
$SearchQuery = $QueryParts -join " AND "

Write-Output " "
Write-Output "Search query: $SearchQuery"
Write-Output " "

# If a search with the same ticket number already exists, remove it before proceeding
if (Get-ComplianceSearch -Identity "$IncidentTicket" -ErrorAction SilentlyContinue) {
    Write-Output "Search '$IncidentTicket' already exists -- removing it before starting fresh..."
    Remove-ComplianceSearch -Identity "$IncidentTicket" -Confirm:$false
    Start-Sleep -Seconds 3
}

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
