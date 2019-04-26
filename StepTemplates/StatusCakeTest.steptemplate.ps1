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
        'Label' = 'Contact Group Names, separated with newlines';
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
    },
    @{
        'Name' = 'FindString';
        'Label' = 'String to find in the page';
        'HelpText' = "The test should look for this string in the returned text";
        'DefaultValue' = '';
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText";
        }
    }
)
Write-Debug "Starting Step Template $StepTemplateName ('$StepTemplateDescription') with $($StepTemplateParameters.Count) parameters"

Function Install-StatusCakeDSCIfRequired
{
    [CmdletBinding()]
    param()
    if(-not (Get-Module StatusCakeDSC -ListAvailable))
    {
        Write-Verbose "Installing StatusCakeDSC"
        Install-Module StatusCakeDSC -Force -Verbose
    }
}

Function Test-PSVersionSupported
{
    [CmdletBinding()]
    param()
    if((Get-PSVersionTable | % PSVersion | % Major) -lt 5)
    {
        throw "This Step Template requires PowerShell v5 or greater"
    }
}

Function Get-PSVersionTable
{
    return $PSVersionTable
}

Function Get-DSCResourceModulePath
{
    [CmdletBinding()]
    param($ResourceName)

    Write-Verbose "Loading $ResourceName Classes"
    $modulePath = Get-DSCResource $ResourceName | Sort-Object -Property Version -Descending | Select-Object -first 1 | Select-Object -expand ParentPath
    $moduleClass = "$modulePath\$ResourceName.psm1"
    return $moduleClass
}
Function Get-DSCResourceAsClassString # so we can load a stub during testing
{
    [CmdletBinding()]
    param($ResourceName)

    Test-PSVersionSupported
    Install-StatusCakeDSCIfRequired

    $modulePath = Get-DSCResourceModulePath $ResourceName
    return Get-Content $modulePath -raw -Verbose
}

Function Invoke-StatusCakeStepTemplate # the init func
{
    [CmdletBinding()]
    param()

    $class = Get-DSCResourceAsClassString -ResourceName StatusCakeTest
    Invoke-Expression $class # load it into local scope

    $secstring = $TestApiKey | ConvertTo-SecureString -AsPlainText -Force
    $TestApiCredential = [PSCredential]::new($TestUserName, $secstring)

    $StepStatusCakeTest = [StatusCakeTest]::new()

    $StepStatusCakeTest.Ensure         = $Ensure
    $StepStatusCakeTest.Name           = $TestName
    $StepStatusCakeTest.URL            = $TestUrl
    $StepStatusCakeTest.ApiCredential  = $TestApiCredential
    $StepStatusCakeTest.ContactGroup   = $ContactGroup -split "`r`n"
    if($FindString -ne "")
    {
        $StepStatusCakeTest.FindString = $FindString
    }

    $StepStatusCakeTest.Set()

}

Invoke-Command -ScriptBlock { Invoke-StatusCakeStepTemplate } # called this way so we can mock Invoke-Command and test better
