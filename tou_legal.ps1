# Version
# 1.0.0
# Made with love by:
# https://github.com/dvrlabs

#TODO:
# Fix bug where cannot delete among us data because it doesnt exist
# Fix bug where crashes on first launch... no clue what causes this.

$appDataFolder = "$env:USERPROFILE\AppData\LocalLow\Innersloth"

$owner = "eDonnes124" # Replace with the repository owner
$repo = "Town-Of-Us-R"   # Replace with the repository name
$outputDir = $env:TEMP # Save to the temp folder
$assetPrefix = "ToU" # Replace with the prefix or string to match

# Step 1: Get the latest release information from GitHub API
$apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"


Add-Type -AssemblyName System.Windows.Forms
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

$inital_msg = @"
This will install the latest release of Town Of Us.
($owner/$repo)

This script may produce a non-working version.
This happens when InnerSloth releases a new version,
but $repo has not released an updated mod
for that version yet.

Before using this script, you must own Among Us on Steam.

You will be prompted for your Steam:
    1. Username
    2. Password
    3. MFA/2FA code 
        (Usually an email)


These credentials are used with SteamCMD.
This script will install SteamCMD.
SteamCMD is an official command-line tool.
It is provided by Valve Corporation.

Do you want to proceed?
"@

# Display a message box with Yes and No options
$result = [System.Windows.Forms.MessageBox]::Show(
    $inital_msg,
    "Confirmation",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

# Handle the user's response
if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Write-Host "Starting install process." -ForegroundColor Green
} else {
    Write-Host "Installation canceled." -ForegroundColor Red
    Write-Host "Goodbye Amogus :(" -ForegroundColor Red
    exit 1
}

$backup_msg = @"
Would you like to backup your current Among Us Data?
It's going to be deleted to make room for the latest version's data.
"@
if (Test-Path $appDataFolder) {

    # Display a message box with Yes and No options
    $result = [System.Windows.Forms.MessageBox]::Show(
        $backup_msg,
        "Confirmation",            # Title
        [System.Windows.Forms.MessageBoxButtons]::YesNo, # Buttons
        [System.Windows.Forms.MessageBoxIcon]::Question  # Icon
    )


    $folderBrowser.Description = "Please select a location to backup your current data to. If there is already a backup there, it will be overwritten."
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $backupSelectedPath = $folderBrowser.SelectedPath
            Write-Host "You selected: $backupSelectedPath" -ForegroundColor Yellow
            Copy-Item -Path $appDataFolder -Destination $backupSelectedPath -Recurse -Force
            Write-Host "Backup saved." -ForegroundColor Green
        } else {
            Write-Host "Continuing without backing up data!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Continuing without backing up data!" -ForegroundColor Yellow
    }

} else {
    Write-Host "Folder not found: $appDataFolder" -ForegroundColor Yellow
    Write-Host "No Among Us data to backup."-ForegroundColor Green
}



Write-Host "Checking for Among Us data to delete: $appDataFolder" -ForegroundColor Cyan
if (Test-Path $appDataFolder) {
    Remove-Item -Recurse -Force $appDataFolder
    Write-Host "Deleted folder: $appDataFolder" -ForegroundColor Green
} else {
    Write-Host "Folder not found: $appDataFolder" -ForegroundColor Yellow
    Write-Host "No Among Us data to delete."-ForegroundColor Green
}


$install_msg = "Please select a directory to install Town Of Us into."
Write-Host $install_msg
$folderBrowser.Description = $install_msg
if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # User clicked OK, get the selected path
    $selectedPathInstall = $folderBrowser.SelectedPath
    Write-Host "You selected: $selectedPathInstall"
} else {
    # User canceled the selection
    Write-Host "No directory selected." -ForegroundColor Yellow
    Write-Host "Installation canceled." -ForegroundColor Red
    Write-Host "Goodbye Amogus :(" -ForegroundColor Red
    exit 1
}


try {
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
    $latestVersion = $releaseInfo.tag_name
    Write-Host "Latest ToU release version: $latestVersion" -ForegroundColor Yellow
} catch {
    Write-Host "Couldn't detect latest verion." -ForegroundColor Yellow
}

# Use a user-accessible directory
$steamCmdDir = Join-Path $env:USERPROFILE "SteamCMD"
$tou_version = "TownOfUs_"+$latestVersion
$installDir = Join-Path $selectedPathInstall $tou_version
$appID = "945360"  # Among Us AppID
$betaBranch = "public-previous"  # Replace with the actual branch name if different

# Prompt the user for Steam credentials
$steamUser = Read-Host "Enter your Steam username"
$SecureSteamPassword = Read-Host "Enter your Steam password" -AsSecureString
$steamPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureSteamPassword)
)


# Step 1: Check if SteamCMD is installed
$steamCmdExe = Join-Path $steamCmdDir "steamcmd.exe"

if (-Not (Test-Path -Path $steamCmdExe)) {
    Write-Host "SteamCMD is not installed. Proceeding with download and installation..." -ForegroundColor Yellow

    # Create SteamCMD directory if it doesn't exist
    if (-Not (Test-Path -Path $steamCmdDir)) {
        New-Item -ItemType Directory -Path $steamCmdDir -Force
        Write-Host "Created SteamCMD directory at $steamCmdDir" -ForegroundColor Green
    }

    # Download SteamCMD
    $steamCmdZip = Join-Path $steamCmdDir "steamcmd.zip"
    if (-Not (Test-Path -Path $steamCmdZip)) {
        Write-Host "Downloading SteamCMD..." 
        Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile $steamCmdZip
    }

    # Extract SteamCMD
    Write-Host "Extracting SteamCMD..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($steamCmdZip, $steamCmdDir)
    Write-Host "SteamCMD installed" -ForegroundColor Green
} else {
    Write-Host "SteamCMD is already installed at $steamCmdDir." -ForegroundColor Yellow
}

# Step 2: Create SteamCMD Script
$steamCmdScript = @"
login $steamUser $steamPassword
force_install_dir $installDir
app_update $appID -beta $betaBranch
quit
"@
$steamCmdScriptPath = Join-Path $steamCmdDir "steamcmd_script.txt"
Set-Content -Path $steamCmdScriptPath -Value $steamCmdScript

# Step 3: Run SteamCMD
Write-Host "Running SteamCMD to download the beta branch..."
Start-Process -NoNewWindow -Wait -FilePath $steamCmdExe -ArgumentList "+runscript $steamCmdScriptPath"

$exePath = Join-Path $installDir "Among Us.exe"

# Step 4: Verify Installation
if (Test-Path -Path $exePath) {
    Write-Host "$betaBranch version of Among Us successfully downloaded to $installDir"
} else {
    Write-Error "Failed to download the beta version of Among Us."
}

Write-Host "Script complete."
Remove-Item -Path $steamCmdScriptPath -Force

# Step 5: Download the latest release of Town Of Us


try {
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

    # Step 2: Check if there are assets attached to the release
    if ($releaseInfo.assets.Count -eq 0) {
        Write-Error "No assets found for the latest release."
        exit 1 
    }

    # Step 2: Retrieve the version of the latest release
    $latestVersion = $releaseInfo.tag_name
    Write-Host "Latest release version: $latestVersion" -ForegroundColor Yellow

    # Step 3: Filter the assets based on the prefix match
    $matchedAsset = $releaseInfo.assets | Where-Object { $_.name -like "$assetPrefix*" }

    if (-not $matchedAsset) {
        Write-Error "No asset found matching the prefix '$assetPrefix'."
        exit 1 
    }

    # Step 4: Download the matched asset
    $assetName = $matchedAsset.name
    $assetUrl = $matchedAsset.browser_download_url
    $zipPath = Join-Path -Path $outputDir -ChildPath $assetName

    Write-Host "Downloading $assetName from $assetUrl..."
    Invoke-WebRequest -Uri $assetUrl -OutFile $zipPath -Headers @{ "User-Agent" = "PowerShell" }
    Write-Host "Downloaded to $zipPath"

    # Create a temporary extraction directory
    $tempExtractDir = Join-Path -Path $env:TEMP -ChildPath "TempExtract"
    if (-not (Test-Path $tempExtractDir)) {
        New-Item -ItemType Directory -Path $tempExtractDir | Out-Null
    }

    # Extract ZIP contents
    Write-Host "Extracting contents of $zipPath to $tempExtractDir..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempExtractDir)
    Write-Host "Extraction complete."



    # Find and copy nested contents
    $nestedFolder = Get-ChildItem -Path $tempExtractDir -Directory | Select-Object -First 1
    if ($nestedFolder) {
        Write-Host "Found nested folder: $($nestedFolder.FullName)"
        Copy-Item -Path (Join-Path $nestedFolder.FullName '*') -Destination $installDir -Recurse -Force
        Write-Host "Contents copied to $installDir."
    } else {
        Write-Error "No folder found in the extracted ZIP archive."
    }

    # Cleanup temporary directory
    Remove-Item -Path $tempExtractDir -Recurse -Force
    Write-Host "Temporary extraction folder cleaned up."



} catch {
    Write-Error "Failed to retrieve or download the latest release: $_"
}


# Display a message box with Yes and No options
$result = [System.Windows.Forms.MessageBox]::Show(
    "Would you like to create a Desktop shortcut?",
    "Confirmation",            # Title
    [System.Windows.Forms.MessageBoxButtons]::YesNo, # Buttons
    [System.Windows.Forms.MessageBoxIcon]::Question  # Icon
)


if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    # Define the path for the desktop
    $desktopPath = [Environment]::GetFolderPath("Desktop")

    # Define the shortcut name and target
    $shortcutName = "ToU_" + $latestVersion + "_.lnk"
    $shortcutPath = Join-Path -Path $desktopPath -ChildPath $shortcutName

    $targetPath = $exePath

    # Create the COM object for WScript.Shell
    $wshShell = New-Object -ComObject WScript.Shell

    # Create the shortcut
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $targetPath
    $shortcut.Description = "Town Of Us (Among Us mod) " + $latestVersion
    # $shortcut.WorkingDirectory = "C:\Path\To\Your"  # Optional: Set the working directory
    # $shortcut.IconLocation = "C:\Path\To\Your\Icon.ico"  # Optional: Set an icon
    $shortcut.Save()

Write-Host "Shortcut created at: $shortcutPath" -ForegroundColor Green
} else {
    Write-Host "No shortcuts taken." -ForegroundColor Yellow
}


Write-Host "Installation Complete." -ForegroundColor Green




# Function to get the Steam installation path from the registry
function Get-SteamPath {
    # Define possible registry paths for Steam
    $registryPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", # Machine-wide installation
        "HKCU:\Software\Valve\Steam"             # User-specific installation
    )

    foreach ($path in $registryPaths) {
        try {
            # Query the registry for the InstallPath value
            $steamPath = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue).InstallPath
            if ($steamPath -and (Test-Path $steamPath)) {
                # Return the full path to Steam.exe if found
                return Join-Path -Path $steamPath -ChildPath "Steam.exe"
            }
        } catch {
            # Continue to the next registry path if an error occurs
            continue
        }
    }

    # If no path was found, return $null
    return $null
}

# Get the path to Steam.exe dynamically
$steamExePath = Get-SteamPath

if (-not $steamExePath -or -not (Test-Path $steamExePath)) {
    Write-Error "Steam.exe not found in registry. Exiting script."
} else {
    # Check if Steam is running
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue

    if ($steamProcess) {
        Write-Host "Steam is running. Restarting..." -ForegroundColor Yellow
        # Stop the Steam process
        Stop-Process -Name "steam" -Force
        Start-Sleep -Seconds 5  # Wait for a few seconds to ensure the process stops completely
    } else {
        Write-Host "Steam is not running. Starting Steam..." -ForegroundColor Green
    }

    # Start Steam
    Start-Process -FilePath $steamExePath
    Write-Host "Steam has been restarted successfully." -ForegroundColor Green
    Write-Host "Please log back into Steam before continuing!!!" -ForegroundColor Yellow
    pause
}



$result = [System.Windows.Forms.MessageBox]::Show(
    "Would you like to run the executable and start Town of Us (Among us) now?",
    "Confirmation",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Start-Process -FilePath $exePath
    Write-Host "Among Us is now running." -ForegroundColor Green
    Write-Host "Please wait, first time takes a few minutes to load." -ForegroundColor Yellow
} else {
    Write-Host "To play, you can double-click the game at $exePath. Make sure Steam is running." -ForegroundColor Yellow
}


pause
