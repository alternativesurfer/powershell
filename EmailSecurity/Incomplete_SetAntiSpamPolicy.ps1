####################################################
####################################################
####################################################
# This script was modified on 6/10/21 by Ian Hart  #
####################################################
# This script will log into the desired tenant and #
# check to see whether or not an Anti-Spam Policy #
# already exists.  If it does - user will need to  #
# review to see if it matches the reccomendations. #
# If not, the script will create a default policy. #
####################################################
####################################################

#Import the Exchange Module
#Import-Module ExchangeOnlineManagement

#Connect to ExchangeOnline
#Connect-ExchangeOnline

#Creating Variables for Statements
#First Variable is to see if there are other policies besides the Default name#
$AntiSpam = Get-HostedConnectionFilterPolicy | Where {$_.Identity -ne "Default"}
#Second Variable is to get the count of other policies besides the default
$Count = $AntiSpam | Measure-Object

#This is a write out of all the Current Policies
Write-Host "Checking to see if there are other policies besides the Uncustomizable 'Microsoft365 AntiSpam Default'" -ForegroundColor Green
$AntiSpam | Select -Property Name, IsDefault, Enabled, WhenChanged

#Begins the IF Statements and Scripting Procedure#
#If there are no policies, besides the default, then it is automatically created#