# StatusCakeDSC

A PowerShell Desired State Configuration Provider for simple status checks on [Statuscake.com](http://statuscake.com)



## Requirements

- PowerShell/WMF 5.0
- StatusCake account & API Key
- A check target

## Quick Install

```
iex ([WebClient].DownloadString("https://githubusercontent.com/stopthatastronaut/StatusCakeDSC/master/install.ps1"))
```

## How to use

```
configuration MyStatusCakeConfig
{
    Import-DscResource -Name StatusCakeDSC
    
    node(hostname)
    {
        StatusCakeContactGroup DevOpsGroup
        {
            Ensure = "present"
            GroupName = "DevOpsEngineers"
            Email = @(	"oncall1@organisation.com", 
            			"oncall2@organisation.com", 
                        "oncall3@organisation.com")
            Mobile = "+1-111-1111"
            PingUrl = "https://infra.organisation.com/statusping"
        }

        StatusCakeTest WebsiteToCheck
        {
            Ensure = "present"
            Name = "My Website Check"
            Url = "http://www.organisation.com/ping/"
            COntactGroup = "DevOpsEngineers"
        }
    }
}

MyStatusCakeConfig -OutputPath $env:tmp\StatusCake
Start-DSConfiguration $env:tmp\StatusCake -verbose -wait -force
```

## Credentials

You can either Specify UserName and ApiKey directly in your DSC configuration, with the following params

```
StatusCakeContactGroup DevOpsGroup
{
    Ensure = "present"
    GroupName = "DevOpsEngineers"
    Email = @("oncall1@organisation.com", "oncall2@organisation.com", "oncall3@organisation.com")
    Mobile = "+1-111-1111"
    PingUrl = "https://infra.organisation.com/statusping"
    ApiKey = "ASDFGHJKLOIUYTREW"
    UserName = "ExampleUserName"
}
```

or you can create a `.creds` file in the same location as the Module, with the following format

```
{
    "ApiKey":  "ASDFGHJKLOIUYTREW",
    "UserName":  "ExampleUserName"
}
```

Using the `.creds` option does not support multiple StatusCake accounts at this time. We recommend you don't commit credentials to public source control, naturally.

## Testing

To run the full suite of automatic tests, you will need valid credentials in a .creds file. There is a subset of tests that can run without.

## Contribs/Reporting bugs

Feel free to submit PRs or bug reports via Github