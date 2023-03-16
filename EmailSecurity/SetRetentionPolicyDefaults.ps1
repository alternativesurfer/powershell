#########################################################
#########################################################
###   This Script was Modified on 2/12/21 by Ian Hart ###
#########################################################
# The purpose of this script is to create a default     #
# organizational wide retention policy of 7 years for   #
# All Users within all locations.  You will notice that #
# A Teams policy must be created separately.            #
#########################################################
#########################################################


#Import the proper Azure Module (install if it isn't already) then connect to Tenant
Import-Module ExchangeOnlineManagement
Connect-IPPSSession
Start-Sleep -Seconds 5
#Setting Counters and Variables outside of Statement
$Answer = ''
$ValidAnswer = @('D','T','E')
$Comment = "This was a defualt Policy made by PCG"
$DefName = "PCG Default Retention"
$TeamName = "PCG Teams Retention"
$Policies = Get-RetentionCompliancePolicy | Where {$_.Enabled -eq $true} | Select -Property Name,Enabled,Workload,Mode
$EnabledPols = $Policies.count

#Start of Script
Write-Host "You currently have $EnabledPols Enabled Policies" -ForegroundColor Green
$Policies | Out-Host

#Loops through the script as long as $Answer = ''.  It then creates the Default policies you want it to.
#Creates policies named "PCG Default Retention" and "PCG Teams Retention"
While ($Answer -eq '')
    {
    $Answer = Read-Host "Would you like to create a Default Policy (D), Teams Policy (T), or Exit (E)? - Please Press D,T, or E"
    if ($Answer -notin $ValidAnswer)
        {
        [console]::Beep(1000, 300)
        Write-warning ('Your Answer is not valid.' -f $Answer)
        Write-Warning "Please Try Again and choose D, T, or E."

        $Answer = ''
        pause
        }
    switch ($Answer)
        {
        'D' {

            New-RetentionCompliancePolicy -Name $DefName -Enabled $True -ExchangeLocation All -ModernGroupLocation All -OneDriveLocation All -SharePointLocation All -PublicFolderLocation All -Comment $Comment
            New-RetentionComplianceRule -Name "7YearAll" -Policy $DefName -RetentionComplianceAction Keep -RetentionDuration 2556
            $Answer = ''
            
            }
        'T' {

            New-RetentionCompliancePolicy -Name $TeamName -Enabled $True -TeamsChannelLocation All -TeamsChatLocation All -Comment $Comment
            New-RetentionComplianceRule -Name "7YearTeams" -Policy $TeamName -RetentionComplianceAction Keep -RetentionDuration 2556
            $Answer=''
            }
        'E' {

            Write-Host "You are exiting this script: Here are you current policies" -ForegroundColor Yellow
            $Policies | Out-Host
            }
    }
}
