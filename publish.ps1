param (
    [string]$NuGetApiKey
)

Write-Output "Installing the NuGet Package Provider..."
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force

Write-Output "Trusting the PSGallery Repository..."
Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"

Write-Output "Publishing the StatusCakeDSC Module..."
Publish-Module -Path "./Modules/StatusCakeDSC" -NuGetApiKey $NuGetApiKey
