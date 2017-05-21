ipmo Pester

# load it into memory
iex (gc .\Modules\StatusCakeDSC\StatusCakeTest.psm1 -raw)

Describe "Object and properties" {

}

Describe "The statuscaketest HTTP bits" {
    $sccg = [StatusCakeTest]::New()   
    It "Can list out tests" {
        {      
            $sccg.GetApiResponse("/Tests/", "GET", $null) } | Should Not Throw
    }

    It "Can create a new test" {
        {
            $sccg.Ensure = 'Present'
            $sccg.CheckRate = 50
            $sccg.Name = 'Pester Test'
            $sccg.URL = 'https://www.google.com/'
            $sccg.Paused = $true
            $sccg.TestType = 'HTTP'

            $sccg.Set() } | Should Not Throw
    }

    It "Can delete a test" {
        {
            $sccg.Ensure = 'Absent'
            $sccg.Set() } | Should Not Throw
            
    }
}


