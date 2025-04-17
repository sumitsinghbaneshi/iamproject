# PowerShell script to download and install Kali Linux WSL to a user-specified drive

# Prompt the user for the desired drive letter
$driveLetter = Read-Host "Enter the drive letter where you want to install Kali Linux WSL (e.g., D):"

# Validate the drive letter (basic check)
if (-not ($driveLetter -match "^[A-Za-z]$")) {
    Write-Error "Invalid drive letter. Please enter a single letter (e.g., D)."
    exit
}

# Construct the installation path
$installationPath = "$($driveLetter):\KaliWSL"

# Create the installation directory if it doesn't exist
if (-not (Test-Path -Path $installationPath -PathType Container)) {
    try {
        Write-Host "Creating installation directory: $($installationPath)"
        New-Item -Path $installationPath -ItemType Directory -Force | Out-Null
    }
    catch {
        Write-Error "Error creating directory '$installationPath': $($_.Exception.Message)"
        exit
    }
} else {
    Write-Host "Installation directory already exists: $($installationPath)"
}

# Download the Kali Linux WSL .wsl file
$url = "https://kali.download/wsl-images/current/kali-linux-2025.1-wsl-rootfs-amd64.wsl"
$outputFile = "$installationPath\kali-rootfs.wsl"

Write-Host "Downloading Kali Linux WSL rootfs to: $($outputFile)"
try {
    Invoke-WebRequest -Uri $url -OutFile $outputFile
    Write-Host "Download complete."
}
catch {
    Write-Error "Error downloading file: $($_.Exception.Message)"
    # Clean up the created directory if download failed
    if (Test-Path -Path $installationPath -PathType Container -Force) {
        Remove-Item -Path $installationPath -Recurse -Force
        Write-Host "Removed the created installation directory due to download failure."
    }
    exit
}

# Import the downloaded .wsl file into WSL
$distributionName = "Kali-User" # You can customize the distribution name

Write-Host "Importing Kali Linux WSL to: $($installationPath)"
try {
    wsl --import $distributionName $installationPath $outputFile
    Write-Host "Kali Linux WSL imported successfully as '$distributionName'."

    # Launch Kali for initial setup (optional)
    Write-Host "Launching Kali Linux for initial setup. Please create your user."
    wsl -d $distributionName

    # Optional: Set default user (you'll need to know the username created inside Kali)
    # $kaliUsername = Read-Host "Enter the username you created inside Kali (optional, for setting default user):"
    # if ($kaliUsername) {
    #     Write-Host "Setting default user to '$kaliUsername' for '$distributionName'."
    #     wsl -d $distributionName -u root bash -c "echo '[user]' | sudo tee /etc/wsl.conf && echo 'default=$kaliUsername' | sudo tee -a /etc/wsl.conf"
    #     Write-Host "Default user set. You might need to restart the WSL instance."
    # }

}
catch {
    Write-Error "Error during import: $($_.Exception.Message)"
    # Clean up the downloaded file and installation directory if import failed
    if (Test-Path -Path $outputFile -Force) {
        Remove-Item -Path $outputFile -Force
    }
    if (Test-Path -Path $installationPath -PathType Container -Force) {
        Remove-Item -Path $installationPath -Recurse -Force
    }
    exit
}

Write-Host "Installation process complete!"
Write-Host "You can now access Kali Linux WSL by running: wsl -d $($distributionName)"