configuration StatusCakeExample
{
    param([pscredential]$apicredential)
    Import-DscResource -ModuleName StatusCakeDSC
    node(hostname)
    {
        StatusCakeTest MyTest
        {
            Name = "Manual Test 123456"
            Ensure = "Present"
            URL = "https://github.com/stopthatastronaut"
            Paused = $true
            CheckRate = 50
            ApiCredential = $apicredential 
        }

        StatusCakeContactGroup MyGroup
        {
            Ensure = "absent"
            GroupName = "Manual Test 654321"
            Email = @("test@test.com", "test2@test.com")
            PingUrl = "http://d.evops.co/ping"
            ApiCredential = $apicredential 
        }
    }
}

# load credentials
$creds = Get-Content .\..\.securecreds -raw | convertfrom-json 

$secpassword = ConvertTo-SecureString $creds.ApiKey 
$credential = [PSCredential]::new($creds.UserName, $secpassword)

$configdata= @{ 
    AllNodes = @(     
            @{  
                NodeName = $env:COMPUTERNAME;
                PSDscAllowPlainTextPassword = $true;
            }; 
        );    
    }

StatusCakeExample -outputpath $env:tmp\StatusCake -apicredential $credential -ConfigurationData $configdata 

Start-DscConfiguration -Path $env:tmp\StatusCake -Verbose -Wait -Force