##### Allow Unsigned
Set-ExecutionPolicy unrestricted

##### Install
Install-Module -Name ExchangeOnlineManagement -Scope AllUsers -Force -AllowClobber
Install-Module -Name MSOnline -Scope AllUsers -Force -AllowClobber
Install-Module -Name AzureAD -Scope AllUsers -Force -AllowClobber
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope AllUsers -Force -AllowClobber
Install-Module -Name MicrosoftTeams -Scope AllUsers -Force -AllowClobber
Install-Module -Name PartnerCenter -AllowClobber -Scope AllUsers -Force
Install-Module -Name Microsoft.Graph.Intune -Scope AllUsers -Force -AllowClobber
Install-Module -Name IntuneBackupAndRestore -Scope AllUsers -Force -AllowClobber
install-module RunAsUser -Scope AllUsers -Force -AllowClobber

### Graph and Graph BETA must both be installed, in this order
Install-Module Microsoft.Graph -Scope AllUsers -Force
Install-Module Microsoft.Graph.Beta -Scope AllUsers -Force -AllowClobber


Install-Module -Name MSCommerce -Scope AllUsers -Force -AllowClobber
Install-Module -Name AIPService -Scope AllUsers -Force -AllowClobber
Install-Module -Name RobustCloudCommand -RequiredVersion 2.0.1
Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -force -allowclobber
Install-Module -Name Microsoft.PowerApps.PowerShell -force -AllowClobber
Install-Module -Name Microsoft.Graph.Entra -Repository PSGallery -Scope CurrentUser -AllowPrerelease -Force -allowclobber
Install-Module PnP.PowerShell -Scope CurrentUser -force -allowclobber


##### Import
Import-Module -Name ExchangeOnlineManagement
Import-Module -Name MSOnline
Import-Module -Name AzureAD
Import-Module -Name Microsoft.Online.SharePoint.PowerShell
Import-Module -Name MicrosoftTeams
Import-Module -Name PartnerCenter
Import-Module -Name Microsoft.Graph.Intune
Import-Module -Name IntuneBackupAndRestore
Import-Module -Name RunAsUser
import-module -Name Microsoft.Graph
import-module -name Microsoft.Graph.Beta
Import-Module -Name MSCommerce
Import-Module -Name AIPService
Import-Module -Name RobustCloudCommand
Import-Module -Name Microsoft.PowerApps.Administration.PowerShell
Import-Module -Name Microsoft.PowerApps.PowerShell
Import-Module -name Microsoft.Graph.Entra
import-module -name pnp.powershell

