[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param(
    [Parameter(Mandatory = $true)]
    $StatusCakeApiKey,
    [Parameter(Mandatory = $true)]
    $StatusCakeUserName
)

Write-Output "Writing .creds and securecreds file"

$secureApiKey = ConvertTo-SecureString $StatusCakeApiKey -asplaintext -force

if(-not (Test-Path "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC"))
{
    New-item -Type Directory "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC" -Force
}

[PSCustomObject]@{
UserName = $StatusCakeUserName;
ApiKey = $StatusCakeApiKey
} | ConvertTo-Json | Out-File "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.creds" -force -verbose

[PSCustomObject]@{
UserName = $StatusCakeUserName;
ApiKey = $secureApiKey | ConvertFrom-SecureString
} | ConvertTo-Json | Out-File "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.securecreds" -force -verbose