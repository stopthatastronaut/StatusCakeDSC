param (
    [string]$NuGetPath = "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet",
    [string]$NuGetApiKey
)

if (!(Test-Path -Path "$NuGetPath\nuget.exe")) {
    if (!(Test-Path -Path $NuGetPath)) {
        New-Item -ItemType "Directory" -Path $NuGetPath | Out-Null
    }

    Write-Output "Downloading the NuGet Executable..."
    (New-Object System.Net.WebClient).DownloadFile("https://nuget.org/nuget.exe", "$NuGetPath\nuget.exe")
}

Write-Output "Installing the NuGet Package Provider..."
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force

Write-Output "Trusting the PSGallery Repository..."
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"

Write-Output "Publishing the StatusCakeDSC Module..."
Publish-Module -Path "./Modules/StatusCakeDSC" -NuGetApiKey $NuGetApiKey
