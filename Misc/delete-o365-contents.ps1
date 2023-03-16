$ScriptStart = Get-Date
$SearchName = 'testdelete-20200818.3'
$Mailbox = 'ieclinicalteam@Sterlinghc.onmicrosoft.com'

#query language
$Query = 'received>=01/01/2010 AND received<=08/09/2020'

write-host "Starting Initial search for $mailbox"
write-host "The query being run is $query"

#Run an initial search to setup counters for the do..while loop and the progress counter
New-ComplianceSearch -Name $SearchName -ExchangeLocation $Mailbox -ContentMatchQuery $Query | Out-Null
Start-ComplianceSearch -Identity $SearchName | Out-Null

Do {
    Start-Sleep -Seconds 2 # Adding 2 sec wait in case of possible timeouts from MS end
    $ComplianceSearch = (Get-ComplianceSearch -Identity $SearchName)
    Write-Host "-- CS $($ComplianceSearch.Status), $($ComplianceSearch.Items)"
} While ($ComplianceSearch.Status -ne 'Completed')

$Iterations = [math]::Ceiling($ComplianceSearch.Items / 100)
$counter = 1

Write-Progress -Activity "Purging emails" -Status "$($ComplianceSearch.Items) items left" -PercentComplete ($counter / $Iterations * 100)
Write-Host "[$counter / $Iterations] $($ComplianceSearch.Items) items left"
$counter++
New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete -Confirm:$false | Out-Null

Do {
    Start-Sleep -Seconds 2
    $PurgeAction = Get-ComplianceSearchAction -Identity "$SearchName`_Purge"
    Write-Host "-- PA $($PurgeAction.Status)"
} While ($PurgeAction.Status -ne 'Completed')

Remove-ComplianceSearch $SearchName -Confirm:$false

#Purge Loop
do {

    New-ComplianceSearch -Name $SearchName -ExchangeLocation $Mailbox -ContentMatchQuery $Query | Out-Null
    Start-ComplianceSearch -Identity $SearchName | Out-Null

    Do {
        Start-Sleep -Seconds 2 # Adding 2 sec wait in case of possible timeouts from MS end
        $ComplianceSearch = (Get-ComplianceSearch -Identity $SearchName)
        Write-Host "-- CS $($ComplianceSearch.Status), $($ComplianceSearch.Items)"
    } While ($ComplianceSearch.Status -ne 'Completed')

    Write-Progress -Activity "Purging emails" -Status "$($ComplianceSearch.Items) items left" -PercentComplete ($counter / $Iterations * 100)
    Write-Host "[$counter / $Iterations] $($ComplianceSearch.Items) items left"
    $counter++
    New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType HardDelete -Confirm:$false | Out-Null

    Do {
        Start-Sleep -Seconds 2
        $PurgeAction = Get-ComplianceSearchAction -Identity "$SearchName`_Purge"
        Write-Host "-- PA $($PurgeAction.Status)"
    } While ($PurgeAction.Status -ne 'Completed')

    Remove-ComplianceSearch $SearchName -Confirm:$false

} while ($ComplianceSearch.Items -gt 0)

$ScriptEnd = Get-Date
$ExecutionTime = $ScriptEnd - $ScriptStart
Write-Host "$ExecutionTime"