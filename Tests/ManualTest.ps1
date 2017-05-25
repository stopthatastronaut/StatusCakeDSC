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
    }
}

StatusCakeExample -outputpath $env:tmp\StatusCake

Start-DscConfiguration -Path $env:tmp\StatusCake -Verbose -Wait -Force