###########################################################################################
####-------This Script was created on 1/27/21 and updated on 1/27/21 by Ian Hart-------####
###                                                                                     ###
### The purpose is to check domains within an Exchange Tenant to first see if DKIM      ###
### has been established and setup.  If it is enabled it will list the following four   ###
### records: SPF, DMARC, Selector1 and Selector2. It will also show the "Enabled" status###
###                                                                                     ###
### If it is NOT ENABLED then it will list the current SPF as well as the two Selector  ###
### CNAME  records that will need to be added to the managed Domain's Name Servers      ###
###########################################################################################
#Import Exchange Online Module
Import-Module ExchangeOnlineManagement

#Connects to the Tenants Exchange Online (MFA Allowed)
Connect-ExchangeOnline

#Sets several variables so you can see a list of all Domains Available to Exchange#
$AllDoms = Get-AcceptedDomain
Write-Host "Here is a list of the domains within Exchange 365" -ForegroundColor DarkYellow
$AllDoms.DomainName | Write-Host -ForegroundColor Green

#Takes User input to set the Domain
$Domain = Read-Host "What is the name of the Domain you are checking?"

#Setting the SPF Variable
$SPF = (nslookup -q=txt $Domain 2>$null | Select-String "spf1")
#Setting the DMARC Variable
$DMARC = (nslookup -q=txt _dmarc.$Domain 2>$null | Select-String "DMARC1")
#Setting DKIM Selector Variables
$Sel1 = nslookup -q=cname selector1._domainkey.$Domain 2>$null | Select-String "canonical name"
$Sel2 = nslookup -q=cname selector2._domainkey.$Domain 2>$null | Select-String "canonical name"

#Set CNAME Variable and retrieve the CNAME records based on whether or not the domain's status is Enabled or Disabled
#If it IS NOT enabled - it will pull the CNAME records you need to add as well as the CURRENT SPF record 
$GetCNAME = Get-DkimSigningConfig -Identity $Domain
if($GetCNAME.Enabled -eq $false){
    Write-Host -ForegroundColor RED "DKIM has not yet been setup" `n
    Write-Host -ForegroundColor Yellow "Your CNAME Records for $Domain are:" `n
    $GetCNAME.Selector1CNAME
    $GetCNAME.Selector2CNAME

    Write-Host -ForegroundColor Yellow "Your Current SPF Record for $Domain is:" `n
    "$SPF"

#If it is enabled it will then grab the two CNAME Records for DKIM, SPF Record, and DMARC record for the enabled domain
}else{
    $GetCNAME | FL
    Write-Host -ForegroundColor Green "Please check manually as DKIM Appears to be enabled or this is not a Domain `n"
   

    Write-Host -ForegroundColor Yellow "Your Active SPF Record for $Domain is: `n
    $SPF" `n

    Write-Host -ForegroundColor Yellow "Your Active DMARC Record for $Domain is: `n
    $DMARC" `n

    Write-Host -ForegroundColor Yellow "Your Active Selector Records for $Domain are: `n
    $Sel1 `n
    $Sel2" `n

$GetCNAME
    }
Remove-PSSession *

