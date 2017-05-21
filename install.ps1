$targetpath = "C:\program Files\WindowsPowerShell\Modules\StatusCakeDSC"
$rawfilehost = "https://githubusercontent.com/stopthatastronaut/StatusCakeDSC/master/"

if(!(Test-Path $targetpath))
{
    New-item -Path $targetPath -Type Directory -Force -Verbose
}

# files required

@(
    "StatusCakeDSC.psd1",
    "StatusCakeDSC.psm1",
    "StatusCakeTest.psm1",
    "StatusCakeContactGroup.pms1"
) | % {
    iwr -uri ("$rawfilehost", $_ -join "") -OutFile ($targetpath, $_ -join "\") -verbose
}

