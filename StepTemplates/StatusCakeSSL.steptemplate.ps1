$StepTemplateName = 'StatusCakeSSL'
$StepTemplateDescription = 'StatusCakeSSL description'
$StepTemplateParameters = @(
    @{
        'Name' = 'Ensure';
        'Label' = 'Ensure Presence';
        'HelpText' = "Should the test be present, or absent? (default: Present)";
        'DefaultValue' = 'Present';
        "DisplaySettings" = @{
            "Octopus.ControlType" = "Select";
            "Octopus.SelectOptions" = "Present`nAbsent"
         }
    },
    @{
        'Name' = 'TestName';
        'Label' = 'Test Name';
        'HelpText' = "Name of the test. Must be unique";
        'DefaultValue' = 'New StatusCake SSL Test';
        "DisplaySettings" = @{
            "Octopus.ControlType" = "SingleLineText";
        }
    },
    @{
        'Name' ='CheckRate';
        'Label' = 'Check Rate';
        'HelpText' = 'The rate at which StatusCake checks your endpoint'
        'DefaultValue' = '1800'
        "DisplaySettings" = @{
            "Octopus.ControlType" = "Select";
            "Octopus.SelectOptions" = "300\n600\n1800\n3600\n86400\n2073600"
        }
    },
    @{
        'Name' = 'ContactGroup';
        'Label' = 'Contact Group';
        'HelpText' = "Name of the contact group alerted by this test";
        'DefaultValue' = '';
        "DisplaySettings" = @{
            "Octopus.ControlType" = "SingleLineText";
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
        'Name' = 'Ensure'
        'Label' = 'Ensure Existence'
        'HelpText' = 'Is this test present or absent?'
        'DefaultValue' = 'Present'
        'DisplaySettings' = @{
            "Octopus.ControlType" = "Select"
            "Octopus.SelectOptions" = "Present\nAbsent"
        }

    },
    @{
        'Name' = 'FirstReminderInDays'
        'Label' = 'First Reminder (days)'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = '30'
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText"
        }
    },
    @{
        'Name' = 'SecondReminderInDays'
        'Label' = 'Second Reminder (days)'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = '7'
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText"
        }
    },
    @{
        'Name' = 'FinalReminderInDays'
        'Label' = 'Final Reminder (days)'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = '1'
        'DisplaySettings' = @{
            "Octopus.ControlType" = "SingleLineText"
        }
    },
    @{
        'Name' = 'AlertOnExpiration'
        'Label' = 'Final Reminder (days)'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = $true
        'DisplaySettings' = @{
            "Octopus.ControlType" = "Checkbox"
        }
    },
    @{
        'Name' = 'AlertOnProblems'
        'Label' = 'Final Reminder (days)'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = $true
        'DisplaySettings' = @{
            "Octopus.ControlType" = "Checkbox"
        }
    },
    @{
        'Name' = 'AlertOnReminders'
        'Label' = 'Final Reminder (days)'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = $true
        'DisplaySettings' = @{
            "Octopus.ControlType" = "Checkbox"
        }
    },
    @{
        'Name' = 'AlertMixed'
        'Label' = 'Alert on Mixed Content'
        'HelpText' = 'How many days before expiry should the reminders arrive?'
        'DefaultValue' = $true
        'DisplaySettings' = @{
            "Octopus.ControlType" = "Checkbox"
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

Function Test-StepTemplateInputIsValid
{
    [CmdletBinding()]
    param()
}

Function Invoke-StatusCakeStepTemplate
{
    [CmdletBinding()]
    param()

    Test-StepTemplateInputIsValid

    $class = Get-DSCResourceAsClassString -ResourceName StatusCakeSSL
    Invoke-Expression $class # load it into local scope

    $secstring = $TestApiKey | ConvertTo-SecureString -AsPlainText -Force
    $TestApiCredential = [PSCredential]::new($TestUserName, $secstring)

}

Invoke-Command -ScriptBlock { Invoke-StatusCakeStepTemplate } # called this way so we can mock Invoke-Command and test better
