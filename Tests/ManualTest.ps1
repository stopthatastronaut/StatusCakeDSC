configuration StatusCakeExample
{
    Import-DscResource -ModuleName StatusCakeDSC
    node(hostname)
    {
        StatusCakeTest MyTest
        {
            Name = "Manual Test 123456"
            Ensure = "Absent"
            URL = "http://www.domain.com.au/"
            Paused = $true
            CheckRate = 50
        }

        StatusCakeContactGroup MyGroup
        {
            Ensure = "absent"
            GroupName = "Manual Test 654321"
            Email = @("test@test.com", "test2@test.com")
            PingUrl = "http://d.evops.co/ping"
        }
    }
}

StatusCakeExample -outputpath $env:tmp\StatusCake

Start-DscConfiguration -Path $env:tmp\StatusCake -Verbose -Wait -Force