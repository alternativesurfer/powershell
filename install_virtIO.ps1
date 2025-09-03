# Powershell script to install virtio drivers and qemu agent for proxmox virtual machines
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Virtio guest tools installer url
$installer_url = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"

function download_file {
    [CmdletBinding()]
	param(
		[Parameter()]
		[string] $url
	)

    # Download file and save to temp directory
    Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\$( Split-Path -Path $url -Leaf )" | Out-Null
    # Start the installer or executable
    Start-Process -FilePath "$env:TEMP\$( Split-Path -Path $url -Leaf )" -ArgumentList "/quiet /passive /norestart" -Wait
    # Delete the file afterwards
    Remove-item "$env:TEMP\$( Split-Path -Path $url -Leaf )"
}

# Download and install the virtio installer
download_file($installer_url)
