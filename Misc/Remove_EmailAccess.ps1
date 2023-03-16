#Run the script then type in the user's display name:  Example -  Ian Hart - Type in:  ihart
$user = read-host
Set-CASMailbox $user -PopEnabled $False -ImapEnabled $False -MAPIEnabled $False -OWAEnabled $False -ActiveSyncEnabled $False