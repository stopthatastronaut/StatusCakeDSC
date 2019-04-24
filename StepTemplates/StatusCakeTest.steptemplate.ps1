$StepTemplateName = 'StatusCakeTest'
$StepTemplateDescription = 'Adds, removes, or updates Tests on StatusCake'
$StepTemplateParameters = @(
    @{
        'Name' = 'Ensure';
        'Label' = 'Ensure Presence';
        'HelpText' = "Should the test be present, or absent? (default: Present)";
        'DefaultValue' = 'Present';
        "DisplaySettings" = @{
            "Octopus.ControlType" ="Select";
            "Octopus.SelectOptions" = "Present\nAbsent"
         }
    },
    @{
        'Name' = 'TestName';
        'Label' = 'Test Name';
        'DefaultValue' = 'New StatusCake Test';
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText";
        }
    },
    @{
        'Name' = 'ContactGroup';
        'Label' = 'Contact Group';
        'DisplaySettings' = @{
            "Octopus.ControlType" = "MultiLineText";
        }
    },
    @{
        'Name' = 'TestApiKey';
        'Label' = 'API Key';
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText";
        }
    },
    @{
        'Name' = 'TestUserName';
        'Label' = 'UserName';
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText";
        }
    },
    @{
        'Name' = 'TestUrl';
        'Label' = 'URL';
        'HelpText' = "HTTP or HTTPS URL at which the test should be directed";
        'DefaultValue' = 'https://';
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText";
        }
    }
)
Set-StrictMode -Version Latest

Write-Debug "Starting Step Template $StepTemplateName ('$StepTemplateDescription') with $($StepTemplateParameters.Count) parameters"

if(-not (Get-Module StatusCakeDSC -ListAvailable))
{
    Write-Verbose "Installing StatusCakeDSC"
    Install-Module StatusCakeDSC -Force -Verbose
}

if($PSVersionTable.PSVersion.Major -lt 5)
{
    throw "This Step Template requires PowerShell v5 or greater"
}

Write-Verbose "Loading StatusCakeDSC Classes"
$modulePath = Get-DSCResource StatusCakeTest | Sort-Object -Property Version -Descending | Select-Object -first 1 | Select-Object -expand ParentPath
$moduleClass = "$modulePath\StatusCakeTest.psm1"

Invoke-Expression (Get-Content $moduleClass -raw)

$secstring = $TestApiKey | ConvertTo-SecureString -AsPlainText -Force
$TestApiCredential = [PSCredential]::new($TestUserName, $secstring)

$StepStatusCakeTest = [StatusCakeTest]::new()

$StepStatusCakeTest.Ensure         = $Ensure
$StepStatusCakeTest.Name           = $TestName
$StepStatusCakeTest.URL            = $TestUrl
$StepStatusCakeTest.ApiCredential  = $TestApiCredential
$StepStatusCakeTest.ContactGroup   = "ExistingContactGroup"

$StepStatusCakeTest.Set()
