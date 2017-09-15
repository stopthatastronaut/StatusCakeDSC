ipmo Pester

# load it into memory
iex (gc .\Modules\StatusCakeDSC\StatusCakeTest.psm1 -raw)

# generate a unique key for our test check
$uniquekey = ((1..9) | get-Random -Count 6) -join ""

Describe "Object and properties" {

}

Describe "Validation" {
    It "Throws if you provide a basic user but no basic pass" {
        { $sccg = [StatusCakeTest]::New()   
        $sccg.BasicPass = "P@ssword1!"
        $sccg.Validate() } | Should Throw
    }

    It "Vice Versa" {
        { $sccg = [StatusCakeTest]::New()   
            $sccg.BasicUser = "UserName"
            $sccg.Validate() } | Should Throw
    }

    It "Should not throw if you have both" {
        { $sccg = [StatusCakeTest]::New()   
            $sccg.BasicPass = "P@ssword1!"
            $sccg.BasicUser = "UserName"
            $sccg.Validate() } | Should Not Throw
    }
}

Describe "The statuscaketest bits" {
    $sccg = [StatusCakeTest]::New()   

    $NewTestName = "Pester Test $uniquekey"

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
            $sccg.CheckRate = 50
            $sccg.Name = $newTestName
            $sccg.URL = 'https://www.google.com/'
            $sccg.Paused = $true
            $sccg.TestType = 'HTTP'
            $sccg.ContactGroup = @("stopthatastronaut", "stopthatastronaut2")

            $sccg.Set() } | Should Not Throw
    }

    # give it a quick rest
    Start-Sleep -Seconds 5

    It "should have the test we just created" {
        $sccg.Get() | select -expand TestID | Should Not Be 0
    }

    It "the test we just created should be valid" {

    }

    It "Should be able to find the test by name" {
        $sccg.GetApiResponse("/Tests/", "GET", $null) | ? { $_.WebSiteName -eq $NewTestName } | Should Not Be $null
    }

    It "Should not throw if we try to create it again" {
        { $sccg.Set() } | Should Not Throw 
    }

    It "Can delete a test" {
        {   $sccg.Ensure = 'Absent'
            $sccg.Set() } | Should Not Throw            
    }

    # give it a quick rest
    Start-Sleep -Seconds 5

    It "should not have the test we just created" {
        $sccg.GetApiResponse("/Tests/", "GET", $null) | ? { $_.WebSiteName -eq $NewTestName } | Should Be $null
    }
}


