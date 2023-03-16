####################################################
####################################################
####################################################
# This script was modified on 2/23/21 by Ian Hart  #
####################################################
# This script will log into the desired tenant and #
# check to see whether or not an Anti-Phish Policy #
# already exists.  If it does - user will need to  #
# review to see if it matches the reccomendations. #
# If not, the script will create a default policy. #
####################################################
####################################################

#Import the Exchange Module
Import-Module ExchangeOnlineManagement

#Connect to ExchangeOnline
Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh

#Grouping of code creates variables and informs the user that the Script is checking for Policies besides the default
Write-Host "Checking to see if there are other policies besides the Uncustomizable 'Microsoft365 AntiPhishing Default'" -ForegroundColor Green
$AntiPhishPol = Get-AntiPhishPolicy | Where {$_.IDentity -ne "Office365 AntiPhish Default"}
$AntiPhishPol | Select -Property Name, IsDefault, Enabled, WhenChanged
$count = $AntiPhishPol | Measure-Object
$Domains = (Get-AcceptedDomain).DomainName


#Begins the If statements determining whether or not a policy should be created.
#If there are no policies, besides the default, then it is automatically created.
#It will also apply this to all domains
#If there is a policy in place, it will review the policy and ask the user if they want to create a PCG Default one regardless.
If($count.count -eq 0)
    {
    Write-Host "There are 0 Existing Policies ... creating the PCG Default now, which aligns to the Microsoft Recommendation: Standard edition" -Foreground Green
    New-AntiPhishPolicy -Name "PCG Default AntiPhishing" `
                        -AdminDisplayName "This is the default policy created by Ian's script at PCG" `
                        -EnableOrganizationDomainsProtection $true `
                        -TargetedUserProtectionAction "Quarantine" `
                        -TargetedDomainProtectionAction "Quarantine" `
                        -EnableSimilarUsersSafetyTips $true `
                        -EnableSimilarDomainsSafetyTips $true `
                        -EnableUnusualCharactersSafetyTips $true `
                        -EnableMailboxIntelligence $true `
                        -EnableMailboxIntelligenceProtection $true `
                        -MailboxIntelligenceProtectionAction "Quarantine" `
                        -EnableSpoofIntelligence $true `
                        -EnableUnauthenticatedSender $true `
                        -AuthenticationFailAction "Quarantine" `
                        -PhishThresholdLevel "2"
    Write-Host "Policy has been created" -ForegroundColor Green
    New-AntiPhishRule -Name "PCG Default APR" `
                      -AntiPhishPolicy "PCG Default AntiPhishing" `
                      -Comments "This is the default policy created by Ian's script at PCG" `
                      -recipientDomainIs $Domains `
                      -Enabled $true `
                      -Priority 0
    }
else
    {
    Write-Host "It appears that there is already a policy in place, please review the following policy" -ForegroundColor Red
    Start-Sleep -Seconds 3
    $AntiPhishPol | Out-Host
    Start-Sleep -Seconds 5
    $Answer = Read-Host "Would you like to create the PCG Default Anyway? - Select Y (Yes) or N (No)"
    If($Answer -contains "y")
        {
        Write-Host "Creating the PCG Default now, which aligns to the Microsoft Recommendation: Standard edition" -ForegroundColor Green
        
        New-AntiPhishPolicy -Name "PCG Default AntiPhishing" `
                     -AdminDisplayName "This is the default policy created by Ian's script at PCG" `
                     -EnableOrganizationDomainsProtection $true `
                     -TargetedUserProtectionAction "Quarantine" `
                     -TargetedDomainProtectionAction "Quarantine" `
                     -EnableSimilarUsersSafetyTips $true `
                     -EnableSimilarDomainsSafetyTips $true `
                     -EnableUnusualCharactersSafetyTips $true `
                     -EnableMailboxIntelligence $true `
                     -EnableMailboxIntelligenceProtection $true `
                     -MailboxIntelligenceProtectionAction "Quarantine" `
                     -EnableSpoofIntelligence $true `
                     -EnableUnauthenticatedSender $true `
                     -AuthenticationFailAction "Quarantine" `
                     -PhishThresholdLevel "2"
        Write-Host "Policy has been created" -ForegroundColor Green
        New-AntiPhishRule -Name "PCG Default APP" `
                      -AntiPhishPolicy "PCG Default AntiPhishing" `
                      -Comments "This is the default policy created by Ian's script at PCG" `
                      -Enabled $true `
                      -recipientDomainIs $Domains `
                      -Priority 0
        Start-Sleep -Seconds 5
        }
    else
        {
        Write-Host "Exiting Script - No Policies have been created" -ForegroundColor Red
        }
    }