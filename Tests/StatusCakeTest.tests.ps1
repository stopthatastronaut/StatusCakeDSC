Import-Module Pester

# load it into memory
Invoke-Expression (Get-Content .\Modules\StatusCakeDSC\StatusCakeTest.psm1 -raw)

# generate a unique key for our test check
$uniquekey = ((1..9) | Get-Random -Count 6) -join ""

# make everything verbose
# $PSDefaultParameterValues['*:Verbose'] = $true

Describe "Object and properties" {

}

Describe "Backoff and retry" {
    BeforeEach {        
        $statehash = @{  # a hash to hold some function state
            Failcount = 1
            TimeStamps = @()
            Runcode = $null
        }
    }

    Function Get-RateLimitedThing {}
    Mock Get-RateLimitedThing {
        # returns something after four failures
        $statehash.Failcount = $statehash.Failcount + 1
        $statehash.TimeStamps += ( [DateTimeOffset]::Now.ToUnixTimeMilliSeconds() )

        if ($statehash.failcount -lt 5) {
            throw "threw at $($statehash.failcount)"
            Write-Output $statehash.Failcount
            Write-Verbose " $($statehash.failcount) " 
        }
        else {
            return [pscustomobject]@{ Result = 'success'; PrivateIPAddress = '192.168.1.1'; PublicIpAddress = '203.122.3.4'}
        }
    } -Verifiable

    $sccg = [StatusCakeTest]::New()   

    Context "Basic backoff job" {
        It "Should catch the thrown exception" {
            { $sccg.InvokeWithBackoff( { Get-RateLimitedThing } ) } | Should Not Throw
        }
    }

    Context "Attempting a backoff and retry" {
        It "Should return something" {
            $result = $sccg.InvokeWithBackoff( { Get-RateLimitedThing } )

            $result.Result | Should Be 'success'
        }

        It "Should call the mock four times" {
            Assert-MockCalled "Get-RateLimitedThing" -times 4
        }
    }
    Context "Attempting a backoff and retry with a short limit" {
        It "Should return null because we've gone beyond maxretries" {
            $sccg.MaxRetries = 3
            $result = $sccg.InvokeWithBackoff( { Get-RateLimitedThing } )

            $result | Should Be $null
        }

        It "Should only call the mock three times" {
            Assert-MockCalled "Get-RatelimitedThing" -times 3
        }
    }

    Context "Examining if backoff actually backs off" {
        It "should have an increased backoff timestamp gap as time goes on" {
            $sccg.InvokeWithBackoff( { Get-RateLimitedThing } )

            $gap1 = $statehash.TimeStamps[1] - $statehash.TimeStamps[0]
            $gap2 = $statehash.TimeStamps[2] - $statehash.TimeStamps[1]

            #Write-Host "gap1 : $gap1"
            #Write-Host "gap2 : $gap2"

            $gap2 -gt $gap1 | Should Be $true 
            ($gap2 - $gap1) -gt 250 | Should Be $true
        }
    }

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