# https://hodgkins.io/five-tips-for-writing-dsc-resources-in-powershell-version-5
param([switch]$EnableExit)

Import-Module pester

# async test runner, because of DSC caching

Import-Module PSScriptAnalyzer

<#
$excludedRules = @(
    'PSUseShouldProcessForStateChangingFunctions', 
    'PSUseSingularNouns', 
    'PSAvoidUsingConvertToSecureStringWithPlainText'
    ) 
#>

<#
$results = Invoke-ScriptAnalyzer ./Modules -recurse # -exclude $excludedRules

Write-Output $results
Write-Output "PSScriptAnalyzer found $($results.length) issues"
Write-Host 
#>


function Invoke-PesterJob
{
    [CmdletBinding(DefaultParameterSetName = 'LegacyOutputXml')]
    param(
        [Parameter(Position=0,Mandatory=0)]
        [Alias('Path', 'relative_path')]
        [object[]]$Script = '.',

        [Parameter(Position=1,Mandatory=0)]
        [Alias("Name")]
        [string[]]$TestName,

        [Parameter(Position=2,Mandatory=0)]
        [switch]$EnableExit,

        [Parameter(Position=3,Mandatory=0, ParameterSetName = 'LegacyOutputXml')]
        [string]$OutputXml,

        [Parameter(Position=4,Mandatory=0)]
        [Alias('Tags')]
        [string[]]$Tag,

        [string[]]$ExcludeTag,

        [switch]$PassThru,

        [object[]] $CodeCoverage = @(),

        [Switch]$Strict,

        [Parameter(Mandatory = $true, ParameterSetName = 'NewOutputSet')]
        [string] $OutputFile,

        [Parameter(ParameterSetName = 'NewOutputSet')]
        [ValidateSet('LegacyNUnitXml', 'NUnitXml')]
        [string] $OutputFormat = 'NUnitXml',

        [Switch]$Quiet,

        [object]$PesterOption,

        [Pester.OutputTypes]$Show = 'All'
    )
    $params = $PSBoundParameters
    
    Start-Job -ScriptBlock { Set-Location $using:pwd; Invoke-Pester @using:params } |
    Receive-Job -Wait -AutoRemoveJob
}

if($EnableExit)
{
    Invoke-PesterJob -EnableExit
}
else
{
    Invoke-PesterJob
}