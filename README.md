# StatusCakeDSC

A PowerShell Desired State Configuration (DSC) Provider for simple status checks on [Statuscake.com](http://statuscake.com). Gives PowerShell users a nice, declarative syntax for defining checks as part of their infrastructure-as-code repositories.

## Requirements

- PowerShell/WMF 5.0+
- StatusCake account & API Key
- A check target

## Quick Install

```
iex ([WebClient].DownloadString("https://githubusercontent.com/stopthatastronaut/StatusCakeDSC/master/install.ps1"))
```

## Installing via git clone

- Clone the repo down to your local machine
- Use junction.exe (from the sysinternals resource kit) to junction `c:\Program Files\WindowsPowershell\Modules\StatuscakeDSC` to the corresponding repo location
- Test this has worked correctly by restarting your powershell session and running

`Get-DSCResource -modulename StatusCakeDSC`

## How to use

The quick start:

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
            ContactGroup = "DevOpsEngineers"
        }
    }
}

MyStatusCakeConfig -OutputPath $env:tmp\StatusCake
Start-DSConfiguration $env:tmp\StatusCake -verbose -wait -force
```

Running `Get-DscResource -Module StatusCakeDSC -Syntax` Will give you all your possible parameters.


There will be further documentation available by running `Get-Help about_DSCResource_StatusCakeDSC` as soon as I have time to write it

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

To run the full suite of automatic tests, you will need valid credentials for an Active Statuscake account, in a .creds file. There is a subset of tests that can run without, but for full functionality, you need them.

They also expect two contact groups to exist, called "stopthatastronaut" and "stopthatastronaut2". Change these to match your environment or add some groups to your environment

## Contribs/Reporting bugs

Feel free to submit PRs or bug reports via Github. I don't bite. Much.