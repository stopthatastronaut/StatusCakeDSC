Set-StrictMode -Version Latest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$runner = "$here\$sut"

Import-Module PowerShellGet # load ahead of time so we can mock it

Describe "StatusCakeTest" {
    Mock Invoke-WebRequest {   # Gettting tests and they don't exist
        return [pscustomobject]@{
            StatusCode = 200;
            StatusDescription = "OK";
            "Content-Type" = "application/json";
            Content = '{ "WebsiteName": "Not A pester-driven StatusCakeTest"}';
            Headers = @{ "Content-Type" = "application/json" }
        }
    } -ParameterFilter { $Method -eq "GET" -and $URI -like "*/Tests/"}

    Mock Invoke-WebRequest {   # posting a test
        return [pscustomobject]@{
            StatusCode = 200;
            StatusDescription = "OK";
            "Content-Type" = "application/json";
            Content = '{"MockedContent": "My mockedcontentishere", "issues":"I have no issues"}';
            Headers = @{ "Content-Type" = "application/json" }
        }
    } -ParameterFilter { $Method -eq "POST" -and $URI -like "*/Tests/"}

    Mock Invoke-WebRequest {
        return [pscustomobject]@{
            content = '{ GroupName: "Pester Test", Emails: [ "team@trafficcake.com" ], Mobiles: [], Boxcar: "", Pushover: "gZh7mBkRIH4CsxWDwvkLBwlEZpxfpZ", ContactID: 5, PingURL: "", DesktopAlert: 1 }'
        }
    } -ParameterFilter { $Method -eq "GET" -and $URI -like "*/ContactGroups"}

    It "Sends a post where we want it to go" {

        # set some vars
        $Ensure = "Present"
        $TestName = "A pester-driven StatusCakeTest"
        $TestUrl = "https://statuscakedsc.d.evops.co/"
        $TestApiKey = "API-1234567890"
        $TestUserName = "statuscakedsc@d.evops.co"

        .$runner

        Assert-MockCalled Invoke-WebRequest
    } -Skip
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
