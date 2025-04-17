#Requires -RunAsAdministrator
# Automation Script for System Speed Improvement

# --- Configuration ---
$DaysToDeleteTempFiles = -7 # Delete temporary files older than 7 days
$ChromeCachePath = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Cache"
$EnableVerboseOutput = $true # Set to $false to suppress detailed output

# --- Helper Function for Verbose Output ---
function Write-VerboseLog ($Message) {
    if ($EnableVerboseOutput) {
        Write-Verbose $Message
    }
}

# --- 1. Clean User Temporary Files (%TEMP%) ---
Write-Host "Cleaning user temporary files..."
Get-ChildItem -Path "$env:TEMP" -Force | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays($DaysToDeleteTempFiles)} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Write-Host "User temporary files cleaned."
Write-VerboseLog "Removed temporary files older than $($DaysToDeleteTempFiles) days from '$env:TEMP'."

# --- 2. Clean System Temporary Files (C:\Windows\Temp) ---
Write-Host "Cleaning system temporary files..."
Get-ChildItem -Path "C:\Windows\Temp" -Force | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays($DaysToDeleteTempFiles)} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Write-Host "System temporary files cleaned."
Write-VerboseLog "Removed temporary files older than $($DaysToDeleteTempFiles) days from 'C:\Windows\Temp'."

# --- 3. Run Disk Cleanup ---
Write-Host "Running Disk Cleanup..."
Start-Process -Wait -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1"
# Note: You might need to configure a Disk Cleanup profile first using 'cleanmgr /sageset:1'
# and select the items you want to clean. This will save the settings to index 1.
Write-Host "Disk Cleanup completed (profile 1)."

# --- 4. Optimize Drives (Defragmentation for HDDs) ---
Write-Host "Optimizing drives..."
$DrivesToOptimize = Get-WmiObject -Class Win32_Volume | Where-Object {$_.DriveLetter} | Select-Object -ExpandProperty DriveLetter

foreach ($Drive in $DrivesToOptimize) {
    Write-VerboseLog "Checking optimization status for drive '$Drive'..."
    $Status = Invoke-Expression "Optimize-Volume -DriveLetter '$Drive' -Analyze -Verbose -Confirm:\$false -ErrorAction SilentlyContinue"
    if ($Status -like "*Needs Optimization*") {
        Write-Host "Optimizing drive '$Drive'..."
        Invoke-Expression "Optimize-Volume -DriveLetter '$Drive' -Defrag -Verbose -Confirm:\$false -ErrorAction SilentlyContinue"
        Write-Host "Drive '$Drive' optimized."
    } else {
        Write-VerboseLog "Drive '$Drive' does not need optimization."
    }
}
Write-Host "Drive optimization completed."

# --- 5. (Basic) Manage Startup Programs (Listing - Requires Manual Disabling) ---
Write-Host "Listing startup programs (you'll need to disable manually via Task Manager)..."
Get-StartupApps | Select-Object Name, CommandLine | Format-Table -AutoSize
Write-Host "Open Task Manager (Ctrl+Shift+Esc -> Startup) to disable unnecessary programs."

Write-Host "Automation script completed."