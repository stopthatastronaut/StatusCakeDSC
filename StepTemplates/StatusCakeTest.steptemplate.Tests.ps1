Set-StrictMode -Version Latest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$runner = "$here\$sut"

Import-Module PowerShellGet # load ahead of time so we can mock it

$creds = Get-Content "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.securecreds" | ConvertFrom-Json
$secapikey = ConvertTo-SecureString $creds.ApiKey
$testcredential = [PSCredential]::new($creds.UserName, $secapikey)

$stubclass = @'
# stubbed out so we can innocuously call the class during testing
class StatusCakeTest
{
    [string]$Ensure
    [string]$Name
    [string]$Url
    [PSCredential]$ApiCredential
    [string]$ContactGroup

    [void]Set()
    {
        # I do nothing
    }
}
'@

Describe "StatusCakeTest, Live fire testing" {
    It "Can set a test" {
        # set some vars
        {
            $Ensure = "Present"
            $TestName = "A pester-driven StatusCakeTest"
            $TestUrl = "https://statuscakedsc.d.evops.co/"
            $TestApiKey = $testcredential.GetNetworkCredential().Password
            $TestUserName = $testcredential.GetNetworkCredential().UserName
            $ContactGroup = "ExistingGroup"

            .$runner
        } | Should Not Throw

    }

    It "Can set the test again without throwing" {
        # set some vars
        {
            $Ensure = "Present"
            $TestName = "A pester-driven StatusCakeTest"
            $TestUrl = "https://statuscakedsc.d.evops.co/"
            $TestApiKey = $testcredential.GetNetworkCredential().Password
            $TestUserName = $testcredential.GetNetworkCredential().UserName
            $ContactGroup = "ExistingGroup"

            .$runner
        } | Should Not Throw
    }

    It "Can remove the test" {
        # set some vars
        {
            $Ensure = "Absent"
            $TestName = "A pester-driven StatusCakeTest"
            $TestUrl = "https://statuscakedsc.d.evops.co/"
            $TestApiKey = $testcredential.GetNetworkCredential().Password
            $TestUserName = $testcredential.GetNetworkCredential().UserName
            $ContactGroup = "ExistingGroup"

            .$runner
        } | Should Not Throw
    }
}

Describe "We install the module ahead of time" {

    Mock Invoke-Command {} # stops us running the entire thing
    . $runner # dot sourced

    Mock Get-Content { return $stubclass } # intercepts our module load
    Mock Install-Module {} -Verifiable
    Mock Get-Module { return $null }
    It "Calls the Install-Module Mock" {

        # set some vars
        $Ensure = "Present"
        $TestName = "A pester-driven StatusCakeTest"
        $TestUrl = "https://statuscakedsc.d.evops.co/"
        $TestApiKey = "API-1234567890"
        $TestUserName = "statuscakedsc@d.evops.co"


        { Install-StatusCakeDSCIfRequired } | Should Not Throw

        Assert-MockCalled Install-Module
    }
}

Describe "Checking Powershell Version" {

    Mock Invoke-Command {} # stops us running the entire thing
    . $runner # dot sourced
    Mock Get-PSVersionTable {
        return [PSCustomObject]@{
            PSVersion = [PSCustomObject]@{
                Major = 4
            }
        }
    }

    It "Throws if our powershell version is -lt 5" {
        { Test-PSVersionSupported } | Should Throw "This Step Template requires PowerShell v5 or greater"
    }
}
