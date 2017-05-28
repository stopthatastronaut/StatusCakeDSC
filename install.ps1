$targetpath = "C:\program Files\WindowsPowerShell\Modules\StatusCakeDSC"
$rawfilehost = "https://githubusercontent.com/stopthatastronaut/StatusCakeDSC/master/"

if(!(Test-Path $targetpath))
{
    New-item -Path $targetPath -Type Directory -Force -Verbose
}
else
{
# first, check if we need to install it at all
    $hashfile = iwr -uri ($rawfilehost, "hashes.json" -join "") | select -expand ResponseBody

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

