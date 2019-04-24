Set-StrictMode -Version Latest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$runner = "$here\$sut"

Import-Module PowerShellGet # load ahead of time so we can mock it

$creds = Get-Content "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.securecreds" | ConvertFrom-Json
$secapikey = ConvertTo-SecureString $creds.ApiKey
$testcredential = [PSCredential]::new($creds.UserName, $secapikey)

Describe "StatusCakeTest" {
    It "Can set a test" {
        # set some vars
        {
            $Ensure = "Present"
            $TestName = "A pester-driven StatusCakeTest"
            $TestUrl = "https://statuscakedsc.d.evops.co/"
            $TestApiKey = $testcredential.GetNetworkCredential().Password
            $TestUserName = $testcredential.GetNetworkCredential().UserName

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

            .$runner
        } | Should Not Throw
    }
}

Describe "We install the module ahead of time" {

    $stubclass = @'
# stubbed out so we can innocuously call the class from the step template
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


        .$runner

        Assert-MockCalled Install-Module
    }
}
