ipmo Pester

# load it into memory
iex (gc .\Modules\StatusCakeDSC\StatusCakeTest.psm1 -raw)

# generate a unique key for our test check
$uniquekey = ((1..9) | get-Random -Count 6) -join ""

Describe "Object and properties" {

}

Describe "validation" {

}

Describe "The statuscaketest HTTP bits" {
    $sccg = [StatusCakeTest]::New()   

    $NewTestName = "Pester Test $uniquekey"

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

            $sccg.Set() } | Should Not Throw
    }

    # give it a quick rest
    Start-Sleep -Seconds 5

    It "should have the test we just created" {
        $sccg.Get() | select -expand TestID | Should Not Be 0
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


