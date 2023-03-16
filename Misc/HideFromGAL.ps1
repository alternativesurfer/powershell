 #This script changes groups in a specific list to be Hidden in GAL
 #CSV is an imported list of the Groups by Identity Name
 #The path is local
 #$csv = Get-Content -Path C:\Users\ian\Desktop\HideGroups.csv 
 foreach ($line in $csv) {
    Set-UnifiedGroup -Identity $line -HiddenFromAddressListsEnabled $True
    }