$error.Clear() # make sure errors are empty

Set-Location c:\StatusCakeDSC # make sure we're in the right working path

# install the module
copy-item c:\StatusCakeDSC\Modules\StatusCakeDSC $env:programfiles\WindowsPowerShell\Modules -recurse -force

# invoke pester
$results = Invoke-Pester -EnableExit -Verbose -passthru 

# suppress a recurring psget error
$errorlist = $error | Where-Object {
		$_.Exception -notlike "System.Management.Automation.RuntimeException: Unable to find type*" -and # psget throws this occasionally
		$_.Exception.Message -notlike "Threw at*" -and 
		$_.Exception.message -ne "ScriptHalted"   # we throw this in testing retries
	}

if($results.FailedCount -gt 0 -or $errorlist.count -gt 0)  # if tests have failed _or_ thrown errors, exit
{
	Write-Output $errorlist
	Fail-Step "Pester returned $($results.failedcount) failed tests"
}
