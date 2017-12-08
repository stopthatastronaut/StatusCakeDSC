# assuming credentials are in a .creds file

configuration StatusCakeDSCExample
{
    Import-DscResource -ModuleName StatusCakeDSC

    node($env:computername)
    {
        StatusCakeContactGroup ExampleGroup
        {
            Ensure = "present"
            GroupName = "Contacts"
            Email = @('person1@domain.com', 'person2@domain.com')
            PingUrl = "https://mywebhookserver.com/statuscakewebhook"
        }

        StatusCakeTest TestMyWebsite
        {
            Ensure = "present"
            DependsOn = [statuscakecontactgroup]"ExampleGroup"
            Name = "Test d.evops.co"
            URL = "http://d.evops.co/"
            ContactGroup = "Contacts"
        }
    }
}

StatusCakeDSCExample -outputpath $env:tmp\StatusCakeDSC
Start-DscConfiguration -Path $env:tmp\StatusCakeDSC -wait -force -verbose 