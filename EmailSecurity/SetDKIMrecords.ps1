###########################################################################################
####-------This Script was created on 1/27/21 and updated on 1/27/21 by Ian Hart-------####
####                                                                                   ####
#### This Script will first check to see if DKIM is enabled.  If so, it will check the ####
#### Selector 1 and 2 Key Sizes.  If either are 1024 it will attempt to rotate them to ####
#### 2048.  If both are 2048 it will let you know.  If it was not enabled - it will    ####
#### attempt to set the DKIM to "Enabled" and then rotate the keys to 2048.  Will show ####
#### Errors if it fails - so please read error messages if received.                   ####
###########################################################################################
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline

#Sets several variables so you can see a list of all Domains Available to Exchange#
$AllDoms = Get-AcceptedDomain
Write-Host "Here is a list of the domains within Exchange 365" -ForegroundColor DarkYellow
$AllDoms.DomainName | Write-Host -ForegroundColor Green

#User input for the Domain name - must be spelled correctly
$Domain = Read-Host "Which Domain would you like to Setup DKIM for?"

#This will Enable DKIM, but only if the CNAME records were added to DNS
$GetCNAME = Get-DkimSigningConfig -Identity $Domain

#If the domain is DKIM enabled - check Key Size - rotate if not 2048#
if($GetCNAME.Enabled -eq $True){
    Write-Host -ForegroundColor Green "DKIM is already Enabled ... checking Keysize ..." `n

    if($GetCNAME.Selector1KeySize -eq "1024" -OR $GetCNAME.Selector2KeySize -eq "1024"){
        Write-Host "The Selector 1 Key Size is" $GetCNAME.Selector1KeySize
        Write-Host "The Selector 2 Key Size is" $GetCNAME.Selector2KeySize `n
        Write-Host -ForegroundColor Green "Attempting to Rotate the Keysize - Standbye" `n
        Rotate-DkimSigningConfig -KeySize 2048 -Identity $Domain 2>$null
        Write-Host -ForegroundColor Green "Rotation Completed - it may take a week before the rotation appears"
        }
    if($GetCNAME.Selector1KeySize -eq "2048" -and $GetCNAME.Selector2KeySize -eq "2048"){
        Write-Host "It appears that both Key Sizes are 2048 - Great!"
        Write-Host "The Selector 1 Key Size is" $GetCNAME.Selector1KeySize
        Write-Host "The Selector 2 Key Size is" $GetCNAME.Selector2KeySize
        
        }
#If not enabled - set DKIM to enabled and then rotate keys#
}else{
    Write-Host -ForegroundColor Green "DKIM is Disabled - Attempting to Enable Right Meow"
    Set-DkimSigningConfig -Identity $Domain -Enabled $True
    Write-Host -ForegroundColor Green "DKIM has been set - if not - please check the Error Generated - make sure the domain was spelled correctly AND that the CNAME records were added"
    Write-Host -ForegroundColor Green "Now Attempting to Rotate the KeySizes - they will not both change until one rotation is completed (usually two weeks)"
    Rotate-DkimSigningConfig -KeySize 2048 -Identity $Domain 2>$null
    Write-Host -Foreground Green "Here are your new Key Sizes - it is okay if one is still 1024 - it will stay until the next rotation"

    Write-Host "The Selector 1 Key Size is" $GetCNAME.Selector1KeySize
    Write-Host "The Selector 2 Key Size is" $GetCNAME.Selector2KeySize
    }
    Remove-PSSession *


