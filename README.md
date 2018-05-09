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

## Installing via PSGallery

The excellent [CVandal](https://github.com/cvandal) has added PSGallery publishing to the resource, so you should be able to insall the resource using `Install-Module StatusCakeDSC`

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

NOTE: As of version 2.0, credentials are protected in PSCredential Objects 

#### v1.x

You can either Specify UserName and ApiKey directly in your DSC configuration, or you can use a locally-stored file (useful for testing).

To pass your credentials in the normal way:

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

To use the .creds option, you'll need a `.creds` file in the module's root directory, with the following content:

```
{
    "ApiKey":  "ASDFGHJKLOIUYTREW",
    "UserName":  "ExampleUserName"
}
```

Using the `.creds` option does not support multiple StatusCake accounts, and is best reserved for testing purposes. We recommend you don't commit credentials to public source control, naturally.

#### v2+

You can either Specify UserName and ApiKey directly in your DSC configuration, with the following params

```
$secureapikey = ConvertTo-SecureString "ASDFGHJKLOIUYTREW" -asplaintext -force # not recommended. See note below.
$apicreds = [PSCredential]::new("ExampleUserName", $secureapikey)


StatusCakeContactGroup DevOpsGroup
{
    Ensure = "present"
    GroupName = "DevOpsEngineers"
    Email = @("oncall1@organisation.com", "oncall2@organisation.com", "oncall3@organisation.com")
    Mobile = "+1-111-1111"
    PingUrl = "https://infra.organisation.com/statusping"
    ApiCredential = $apicreds
}
```

or you can create a `.securecreds` file in the same location as the Module, with the following format. The secure string will be decrypted with the local machine's default key (using `ConvertTo-SecureString`). Strings serialized with another key will fail here, so take care.

```
{
    "ApiKey":  "serializedsecurestringrepresentationofyourapikey",
    "UserName":  "ExampleUserName"
}
```

You can use [createcredsfile.ps1](createcredsfile.ps1) to create securecreds files. This script will prompt for your credentials and drop them into `%ProgramFiles%\WindowsPowerShell\Modules\StatusCakeDSC`.

More information on securing credentials with PSCredential Objects, see the [following link](https://docs.microsoft.com/en-us/powershell/dsc/securemof)

## A note on API keys and rate limits

At the time of writing (Dec 2017), Statuscake free accounts have rate limiting applied which makes the resource misbehave, throwing 500 errors. Paid accounts have no such limitation. We'll update this readme if and when that changes.

Backoff and retry for rate-limits is a flagged-off feature at present, since limiting in the API is not granular.

## Testing

To run the full suite of automatic tests, you will need valid credentials for an Active Statuscake account, in a .creds o .securecreds file. There is a subset of tests that can run without, but for full functionality, you need them.

They also expect two contact groups to exist, called "stopthatastronaut" and "stopthatastronaut2". Change these to match your environment or add some groups to your environment.

## Contribs/Reporting bugs

Feel free to submit PRs or bug reports via Github. I don't bite. Much.

## Publishing to the PS Gallery

This Module has Continuous Publishing configured via Octopus Deploy.

Any commit on `master` will trigger an [Octopus Deploy](https://octopus.com/) instance using [TakoFukku](https://github.com/stopthatastronaut/Takofukku). That instance will run tests and, if successful, run a publishing step.

The publishing step checks the latest version available on PS Gallery, and compares that to the version in StatusCakeDSC.psd1. If the manifest version is higher than the published version, Octopus then attempts to publish the new version to the Gallery, and tries to tag the commit on github. Be aware that incrementing the version will attempt to publish the module immediately.