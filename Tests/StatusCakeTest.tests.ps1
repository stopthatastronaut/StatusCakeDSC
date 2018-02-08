Import-Module Pester

# load it into memory
Invoke-Expression (Get-Content .\Modules\StatusCakeDSC\StatusCakeTest.psm1 -raw)

# generate a unique key for our test check
$uniquekey = ((1..9) | Get-Random -Count 6) -join ""

# make everything verbose
# $PSDefaultParameterValues['*:Verbose'] = $true

Describe "Object and properties" {

}

Describe "The statuscaketest bits" {
    $sccg = [StatusCakeTest]::New()   

    $NewTestName = "Pester Test $uniquekey"
    Write-Output "New Test name is $NewTestName"

    It "Can resolve a ContactGroup called 'stopthatastronaut'" {

        $sccg.ResolveContactGroups(@("stopthatastronaut")).length | Should BeGreaterThan 0
    }

    It "Can list out tests using the internal method" {
    {      
            $sccg.GetApiResponse("/Tests/", "GET", $null) } | Should Not Throw
    }

    It "Can create a new test" {
        {
            $sccg.Ensure = 'Present'
            $sccg.CheckRate = 350
            $sccg.Name = $NewTestName
            $sccg.URL = 'https://www.google.com/'
            $sccg.Paused = $true
            $sccg.TestType = 'HTTP'
            $sccg.ContactGroup = @("stopthatastronaut", "stopthatastronaut2")

            $sccg.Set() } | Should Not Throw
    }

    # give it a quick rest
    Start-Sleep -Seconds 5

    It "should have the test we just created" {
        $sccg.Get() | Select-Object -expand TestID | Should Not Be 0
    }

    It "the test we just created should be valid" {

    }

    It "Should be able to find the test by name" {
        $sccg.GetApiResponse("/Tests/", "GET", $null) | Where-Object { $_.WebSiteName -eq $NewTestName } | Should Not Be $null
    }

    It "Should not throw if we try to create it again" {
        { $sccg.Set() } | Should Not Throw 
    }

    It "doesn't react if nothing has changed" {        
        $sccg.Test() | Should Be $true
    }

    It "Can detect if the checkrate has changed" {
        $sccg.CheckRate = 250
        $sccg.Test() | Should Be $false
    }

    It "Can detect if ConfirmationServers has changed" {
        $sccg.ConfirmationServers = 7
        $sccg.Test() | Should Be $false
    }

    It "Can detect if ContactGroups have changed" {
        $sccg.ContactGroup = @("stopthatastronaut")
        $sccg.Test() | Should Be $false
    }

    It "Can detect if AlertDelayRate changes" {
        $sccg.AlertDelayRate = 65
        $sccg.Test() | Should Be $false
    }

    It "Can detect presence/absence at this point" {
        $sccg.Ensure = 'Absent'        
        $sccg.Test() | Should Be $false
    }

    It "Can delete a test" {
        {   $sccg.Ensure = 'Absent'
            $sccg.Set() } | Should Not Throw            
    }

    # give it a quick rest
    Start-Sleep -Seconds 5

    It "should not have the test we just created" {
        $sccg.GetApiResponse("/Tests/", "GET", $null) | Where-Object { $_.WebSiteName -eq $NewTestName } | Should Be $null
    }
}


# remove the verbose preference, for test troubleshooting
# $PSDefaultParameterValues.Remove('*:Verbose')