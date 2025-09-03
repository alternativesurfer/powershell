# Ensures winget is available; installs it if missing, then updates all apps silently.

$ErrorActionPreference = 'Stop'

function Test-Winget {
    return [bool](Get-Command winget.exe -ErrorAction SilentlyContinue)
}

function Install-WingetIfMissing {
    if (Test-Winget) { return }

    Write-Host "winget not found. Installing via winget-install from PowerShell Gallery..."

    # Make sure TLS 1.2/NuGet/PSGallery trust are set so there are no prompts.
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        }

        $repo = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
        if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        }
    } catch {
        Write-Warning "Prep for Install-Script encountered: $($_.Exception.Message) - continuing."
    }

    # Install the winget-install helper script without prompts, then run it.
    Install-Script winget-install -Scope CurrentUser -Force -ErrorAction Stop

    # Find where the script landed and execute it (no prompts).
    $scriptPath = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Scripts\winget-install.ps1'
    if (-not (Test-Path $scriptPath)) {
        $scriptPath = Join-Path $env:ProgramFiles 'WindowsPowerShell\Scripts\winget-install.ps1'
    }

    if (-not (Test-Path $scriptPath)) {
        # Fallback to whatever PowerShell knows about the command
        $cmd = Get-Command winget-install -CommandType ExternalScript, Script -ErrorAction SilentlyContinue
        if ($cmd) { $scriptPath = $cmd.Source }
    }

    if (-not (Test-Path $scriptPath)) {
        throw "Couldn't locate winget-install.ps1 after Install-Script."
    }

    # Run the installer script in-process; most versions are non-interactive when run this way.
    & $scriptPath

    # Make sure the path containing winget is available to this session.
    $env:PATH += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"

    # Wait briefly for registration to finish and verify availability.
    $deadline = (Get-Date).AddSeconds(60)
    while (-not (Test-Winget)) {
        if (Get-Date -gt $deadline) {
            throw "winget still not found after installation."
        }
        Start-Sleep -Seconds 2
    }

    Write-Host "winget installed successfully."
}

# --- Main flow ---
try {
    if (-not (Test-Winget)) {
        Install-WingetIfMissing
    } else {
        Write-Host "winget already installed; proceeding to updates."
    }

    # Optional but recommended: refresh sources first
    try { & winget.exe source update | Out-Null } catch { }

    # Your exact update command:
    & winget.exe update --all --silent --accept-package-agreements --accept-source-agreements
}
catch {
    Write-Error $_
    exit 1
}
