param (
    [string]$NuGetPath = "C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet",
    [string]$NuGetApiKey
)

if (!(Test-Path -Path "$NuGetPath\nuget.exe")) {
    if (!(Test-Path -Path $NuGetPath)) {
        New-Item -ItemType "Directory" -Path $NuGetPath -force -verbose | Out-Null
    }

    Write-Output "Downloading the NuGet Executable..."
    (New-Object System.Net.WebClient).DownloadFile("https://nuget.org/nuget.exe", "$NuGetPath\nuget.exe")
}

# find the current published version
$pver = (Find-Module StatusCakeDSC | Select -expand version)

# find the current manifest version

$mver = (iex (gc .\Modules\StatusCakeDSC\StatusCakeDSC.psd1 -raw)).ModuleVersion


if($mver -gt $pver)
{

    Write-Output "Version has incremented. Publishing to PSGallery"

    Write-Output "Installing the NuGet Package Provider..."
    Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force -Verbose

    Write-Output "Trusting the PSGallery Repository..."
    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted" -Verbose

    Write-Output "Publishing the StatusCakeDSC Module..."
    Publish-Module -Path "./Modules/StatusCakeDSC" -NuGetApiKey $NuGetApiKey -verbose # -FormatVersion $newversion 

    git tag -a "$mver" -m "Version $mver release"
    git push --tags

}
else {
    Write-Output "Version not incremented, declining to publish"
}