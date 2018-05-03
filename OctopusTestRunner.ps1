$error.Clear() # make sure errors are empty

cd c:\StatusCakeDSC # make sure we're in the right working path

# install the module
copy-item c:\StatusCakeDSC\Modules\StatusCakeDSC $env:programfiles\WindowsPowerShell\Modules -recurse -force

# invoke pester
$failcount = Invoke-Pester -EnableExit -Verbose

# suppress a recurring psget error
$errorlist = $error | ? {$_.Exception -notlike "System.Management.Automation.RuntimeException: Unable to find type*" -and $_.Exception.Message -notlike "Threw at*"}

if($failcount -gt 0 -or $errorlist.count -gt 0)  # if tests have failed _or_ thrown errors, exit
{
	Write-Host $errorlist
	Fail-Step "Pester returned $failcount failed tests"
}

