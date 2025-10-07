# to run: .\Export-PstContacts.ps1 -PstPath "C:\temp\PSTLOCATIONHERE.pst" -verbose

param(
  [Parameter(Mandatory = $true)]
  [ValidateScript({ Test-Path $_ })]
  [string]$PstPath,

  [string]$OutputCsv = (Join-Path -Path (Split-Path -Path $PstPath -Parent) -ChildPath ("{0}_contacts.csv" -f [IO.Path]::GetFileNameWithoutExtension($PstPath))),

  [switch]$IncludeDistributionLists,
  [switch]$DryRun,
  [string]$FolderPath,       # Example: "\Personal Folders\Contacts"
  [string]$LogPath,          # Example: "C:\Temp\pst_export.log"
  [switch]$ShowRoots,        # Print all top-level stores before processing
  [int]$AttachWaitSeconds = 10,
  [switch]$AggressiveScan    # Force scan of all folders, not only Contacts-typed ones
)

Set-StrictMode -Version 2

if ($LogPath) {
  try {
    Start-Transcript -Path $LogPath -Append -ErrorAction Stop | Out-Null
    Write-Verbose "Transcript started at $LogPath"
  } catch {
    Write-Warning "Could not start transcript. $_"
  }
}

function Get-OutlookApp {
  Write-Verbose "Acquiring Outlook.Application COM"
  $app = $null
  try {
    $app = [Runtime.InteropServices.Marshal]::GetActiveObject('Outlook.Application')
    if ($app) { Write-Verbose "Attached to running Outlook. Version: $($app.Version)" }
  } catch { }

  if (-not $app) {
    try {
      $app = New-Object -ComObject Outlook.Application
      Write-Verbose "Started new Outlook.Application. Version: $($app.Version)"
    } catch {
      $hostBits = if ([Environment]::Is64BitProcess) { '64-bit' } else { '32-bit' }
      $hint = @(
        "Could not create Outlook.Application COM object.",
        "Common causes:",
        " - Outlook not installed or click-to-run isolation blocking COM",
        " - PowerShell bitness does not match Office bitness",
        " - Elevation mismatch between Outlook and PowerShell",
        "Try this:",
        " - Use Windows PowerShell 5.1 that matches Office bitness",
        "   64-bit:  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
        "   32-bit:  C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe",
        " - Start Outlook first, then run the script",
        "Current host is $hostBits at $PSHOME"
      ) -join [Environment]::NewLine
      throw "$hint`nInner: $($_.Exception.Message)"
    }
  }
  return $app
}

function Show-TopLevelStores {
  param([Parameter(Mandatory = $true)][object]$Session)
  try {
    $iMax = $Session.Folders.Count
    Write-Host "Top-level stores loaded: $iMax"
    for ($i = 1; $i -le $iMax; $i++) {
      $root = $Session.Folders.Item($i)
      $fp = $null
      try { $fp = $root.Store.FilePath } catch { $fp = "<no file path>" }
      "{0,2}. {1}  [{2}]" -f $i, $root.Name, $fp | Write-Host
    }
  } catch {
    Write-Warning "Could not list root stores. $($_.Exception.Message)"
  }
}

function Get-RootFolders {
  param([Parameter(Mandatory = $true)][object]$Session)
  $roots = @()
  $count = 0
  try { $count = $Session.Folders.Count } catch { throw "MAPI session not ready. $($_.Exception.Message)" }
  for ($i = 1; $i -le $count; $i++) {
    try {
      $root = $Session.Folders.Item($i)
      if ($null -ne $root) { $roots += $root }
    } catch {
      Write-Warning "Skipping root index $i. $($_.Exception.Message)"
    }
  }
  return $roots
}

function FindStoreByPath {
  param(
    [Parameter(Mandatory = $true)][object]$Session,
    [Parameter(Mandatory = $true)][string]$ResolvedPath
  )
  foreach ($root in Get-RootFolders -Session $Session) {
    try {
      $st = $root.Store
      if ($st -and $st.FilePath -and ($st.FilePath -ieq $ResolvedPath)) { return $st }
    } catch { }
  }
  return $null
}

function Add-PstIfNeeded {
  param(
    [Parameter(Mandatory = $true)][object]$Namespace,
    [Parameter(Mandatory = $true)][string]$PstPath,
    [int]$AttachWaitSeconds = 10
  )

  $resolved = (Resolve-Path $PstPath).Path
  Write-Verbose "Resolved PST path: $resolved"

  $store = FindStoreByPath -Session $Namespace -ResolvedPath $resolved
  $added = $false

  if (-not $store) {
    Write-Verbose "Attaching PST"
    $attached = $false
    try {
      $Namespace.AddStoreEx($resolved, 1)  # 1 = olStoreUnicode
      $attached = $true
    } catch {
      try {
        $Namespace.AddStore($resolved)
        $attached = $true
      } catch {
        throw "Failed to attach PST at $resolved. Inner: $($_.Exception.Message)"
      }
    }

    if ($attached) {
      $added = $true
      $deadline = [DateTime]::UtcNow.AddSeconds($AttachWaitSeconds)
      do {
        Start-Sleep -Milliseconds 250
        $store = FindStoreByPath -Session $Namespace -ResolvedPath $resolved
        if ($store) { break }
      } while ([DateTime]::UtcNow -lt $deadline)
    }
  } else {
    Write-Verbose "PST already attached"
  }

  if (-not $store) {
    throw "PST attached but the store could not be located after waiting $AttachWaitSeconds seconds."
  }
  return @($store, $added)
}

function Get-AllFolders {
  param([Parameter(Mandatory = $true)][object]$Folder)
  $results = @($Folder)
  foreach ($sub in $Folder.Folders) {
    $results += Get-AllFolders -Folder $sub
  }
  return $results
}

function Get-ContactFoldersByType {
  param([Parameter(Mandatory = $true)][object]$Folder)
  $results = @()
  if ($Folder.DefaultItemType -eq 2) { $results += $Folder }  # 2 = Contacts
  foreach ($sub in $Folder.Folders) {
    $results += Get-ContactFoldersByType -Folder $sub
  }
  return $results
}

function Test-HasContactItem {
  param(
    [Parameter(Mandatory = $true)][object]$Folder,
    [int]$Probe = 50
  )
  try {
    $items = $Folder.Items
    $seen = 0
    $it = $items.GetFirst()
    while ($null -ne $it -and $seen -lt $Probe) {
      $seen++
      try {
        $mc = $it.MessageClass
        if ($mc -and ($mc -like 'IPM.Contact*' -or $mc -like 'IPM.DistList*')) { return $true }
      } catch { }
      try { $it = $items.GetNext() } catch { $it = $null }
    }
  } catch { }
  return $false
}

function Resolve-FolderPath {
  param(
    [Parameter(Mandatory = $true)][object]$Root,
    [Parameter(Mandatory = $true)][string]$FolderPath
  )
  $cur = $Root
  $parts = $FolderPath.Trim() -split '\\' | Where-Object { $_ -ne '' }
  foreach ($p in $parts) {
    if ($cur.Name -ieq $p) { continue }
    $next = $null
    foreach ($f in $cur.Folders) {
      if ($f.Name -ieq $p) { $next = $f; break }
    }
    if (-not $next) { throw "Folder path not found: $FolderPath" }
    $cur = $next
  }
  return $cur
}

# Main
$sw = [System.Diagnostics.Stopwatch]::StartNew()
Write-Verbose "Launching and logging on to MAPI"
$ol = Get-OutlookApp
$ns = $ol.Session
$ns.Logon($null, $null, $false, $false)

if ($ShowRoots) {
  Show-TopLevelStores -Session $ns
}

$tuple = Add-PstIfNeeded -Namespace $ns -PstPath $PstPath -AttachWaitSeconds $AttachWaitSeconds
$store = $tuple[0]
$addedStore = [bool]$tuple[1]
$root = $store.GetRootFolder()
Write-Verbose "Root folder: $($root.FolderPath)"

# Choose folders
$targetFolders = @()

if ($FolderPath) {
  Write-Verbose "Limiting to folder path: $FolderPath"
  $sel = Resolve-FolderPath -Root $root -FolderPath $FolderPath
  $targetFolders = @($sel)
} else {
  if ($AggressiveScan) {
    Write-Verbose "Aggressive scan enabled. Will examine every folder."
    $targetFolders = Get-AllFolders -Folder $root
  } else {
    $typed = Get-ContactFoldersByType -Folder $root
    if ($typed.Count -gt 0) {
      $targetFolders = $typed
    } else {
      Write-Verbose "No Contacts-typed folders found. Falling back to aggressive scan of all folders."
      $targetFolders = Get-AllFolders -Folder $root
    }
  }
}

if (-not $targetFolders -or $targetFolders.Count -eq 0) {
  throw "No folders were found to scan."
}

Write-Verbose ("Folders selected: {0}" -f $targetFolders.Count)

# If we are scanning all folders, try to prune to only those that appear to contain contacts
if (-not $FolderPath -and ($AggressiveScan -or ($targetFolders -and $targetFolders[0] -ne $null -and $targetFolders[0].DefaultItemType -ne 2))) {
  Write-Verbose "Probing folders for contact items..."
  $probeList = New-Object System.Collections.Generic.List[object]
  $idx = 0
  foreach ($f in $targetFolders) {
    $idx++
    Write-Progress -Activity "Probing folders" -Status $f.FolderPath -PercentComplete (($idx / [double]$targetFolders.Count) * 100)
    if ($f.DefaultItemType -eq 2 -or (Test-HasContactItem -Folder $f -Probe 50)) {
      $probeList.Add($f) | Out-Null
    }
  }
  Write-Progress -Activity "Probing folders" -Completed
  $targetFolders = $probeList
  Write-Verbose ("Folders likely containing contacts: {0}" -f $targetFolders.Count)
}

if (-not $targetFolders -or $targetFolders.Count -eq 0) {
  throw "No folders with contact items were found."
}

$rows = New-Object System.Collections.Generic.List[object]
$folderIndex = 0
$totalItemsProcessed = 0

foreach ($cf in $targetFolders) {
  $folderIndex++
  $fp = $cf.FolderPath
  Write-Verbose "Scanning folder [$folderIndex/$($targetFolders.Count)]: $fp"

  $items = $null
  try {
    $items = $cf.Items
  } catch {
    Write-Warning "Failed to access items in $fp. $_"
    continue
  }

  $i = 0
  $item = $items.GetFirst()
  while ($null -ne $item) {
    $i++
    $totalItemsProcessed++
    Write-Progress -Activity "Exporting contacts" -Status "Folder: $fp  Item: $i" -PercentComplete (($folderIndex / [double]$targetFolders.Count) * 100)

    try {
      $mc = $null
      try { $mc = $item.MessageClass } catch { $mc = $null }
      if ($mc -and ($mc -like 'IPM.Contact*')) {
        if (-not $DryRun) {
          $rows.Add([pscustomobject]@{
            'First Name'               = $item.FirstName
            'Middle Name'              = $item.MiddleName
            'Last Name'                = $item.LastName
            'Full Name'                = $item.FullName
            'Company'                  = $item.CompanyName
            'Job Title'                = $item.JobTitle
            'Email Address'            = $item.Email1Address
            'Email 2 Address'          = $item.Email2Address
            'Email 3 Address'          = $item.Email3Address
            'Mobile Phone'             = $item.MobileTelephoneNumber
            'Business Phone'           = $item.BusinessTelephoneNumber
            'Business Phone 2'         = $item.Business2TelephoneNumber
            'Home Phone'               = $item.HomeTelephoneNumber
            'Home Phone 2'             = $item.Home2TelephoneNumber
            'Other Phone'              = $item.OtherTelephoneNumber
            'Business Fax'             = $item.BusinessFaxNumber
            'Home Fax'                 = $item.HomeFaxNumber
            'Web Page'                 = $item.WebPage
            'Business Street'          = $item.BusinessAddressStreet
            'Business City'            = $item.BusinessAddressCity
            'Business State'           = $item.BusinessAddressState
            'Business Postal Code'     = $item.BusinessAddressPostalCode
            'Business Country/Region'  = $item.BusinessAddressCountry
            'Home Street'              = $item.HomeAddressStreet
            'Home City'                = $item.HomeAddressCity
            'Home State'               = $item.HomeAddressState
            'Home Postal Code'         = $item.HomeAddressPostalCode
            'Home Country/Region'      = $item.HomeAddressCountry
            'Other Street'             = $item.OtherAddressStreet
            'Other City'               = $item.OtherAddressCity
            'Other State'              = $item.OtherAddressState
            'Other Postal Code'        = $item.OtherAddressPostalCode
            'Other Country/Region'     = $item.OtherAddressCountry
            'Categories'               = $item.Categories
            'Notes'                    = $item.Body
            'Folder'                   = $fp
          })
        }
      }
      elseif ($IncludeDistributionLists -and $mc -and ($mc -like 'IPM.DistList*')) {
        if (-not $DryRun) {
          for ($m = 1; $m -le $item.MemberCount; $m++) {
            $mem = $item.GetMember($m)
            $rows.Add([pscustomobject]@{
              'Full Name'     = $mem.Name
              'Email Address' = $mem.Address
              'Notes'         = "From distribution list: $($item.DLName)"
              'Folder'        = $fp
            })
          }
        }
      }
    } catch {
      Write-Warning "Error on item $i in $fp. $_"
    } finally {
      try { $item = $items.GetNext() } catch { $item = $null }
    }
  }

  Write-Verbose "Folder complete: $fp. Items seen: $i"
}

if ($DryRun) {
  Write-Host "Dry run complete. Folders processed: $($targetFolders.Count). Items seen: $totalItemsProcessed"
} else {
  if ($rows.Count -eq 0) { throw "No contacts to export." }
  Write-Verbose "Writing CSV to $OutputCsv"
  $rows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
  Write-Host ("Exported {0} rows to {1}" -f $rows.Count, $OutputCsv)
}

try {
  if ($addedStore) {
    Write-Verbose "Removing attached PST store"
    $ns.RemoveStore($root)
  }
} catch {
  Write-Warning "Could not remove store. $_"
}

$sw.Stop()
Write-Verbose ("Elapsed: {0:n1} seconds" -f $sw.Elapsed.TotalSeconds)

if ($LogPath) {
  try { Stop-Transcript | Out-Null } catch {}
}
