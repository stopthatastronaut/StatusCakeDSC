Import-Module Pester

# load it into memory
Invoke-Expression (gc .\Modules\StatusCakeDSC\StatusCakeSSL.psm1 -raw)


# generate a unique key for our test check
$uniquekey = ((1..9) | get-Random -Count 6) -join ""

Describe "Object and properties" {

}

Describe "The StatusCakeSSL bits" {
    $sccg = [StatusCakeSSL]::New()   

    $NewTestName = "Pester Test $uniquekey"
      
    It "Can list out SSL Checks using the internal method" {
        {       
            $sccg.GetApiResponse("/SSL/", "GET", $null) } | Should Not Throw
    }

    It "Fails well when creating an SSL check when ContactGroup doesn't exist" {
        {
            $sccg.Ensure                = "Present"
            $sccg.CheckRate             = 300
            $sccg.Name                  = "https://www.$uniquekey.net"
            $sccg.AlertOnExpiration     = $false
            $sccg.AlertOnProblems       = $false
            $sccg.AlertOnReminders      = $false
            $sccg.FirstReminderInDays   = 30;
            $sccg.SecondReminderInDays  = 6
            $sccg.FinalReminderInDays   = 1
            $sccg.ContactGroup          = @("ContactGroupThatDoesntExist")
            $sccg.get() } | Should throw "You have specified a contact group that doesn't exist, cannot proceed."

            # we expect this to throw an error, but we check the stack for errors later. Remove the most recent.
            

            if($error[0] -like "You have specified a contact group that*")
            {
                $error.RemoveAt(0)
            }
    }

    It "Should be able to create SSL check" {
        {
            $sccg.Ensure                = "Present"
            $sccg.CheckRate             = 300
            $sccg.Name                  = "https://www.$uniquekey.net"
            $sccg.AlertOnExpiration     = $false
            $sccg.AlertOnProblems       = $false
            $sccg.AlertOnReminders      = $false
            $sccg.FirstReminderInDays   = 30;
            $sccg.SecondReminderInDays  = 6
            $sccg.FinalReminderInDays   = 1
            $sccg.ContactGroup          = @("ExistingContactGroup")
            $sccg.set() } | Should not throw
    }

    It "Should be able to change SSL check" {
        {
            $sccg.Ensure                = "Present"
            $sccg.CheckRate             = 300
            $sccg.Name                  = "https://www.$uniquekey.net"
            $sccg.AlertOnExpiration     = $false
            $sccg.AlertOnProblems       = $true
            $sccg.AlertOnReminders      = $true
            $sccg.FirstReminderInDays   = 25;
            $sccg.SecondReminderInDays  = 7
            $sccg.FinalReminderInDays   = 4
            $sccg.ContactGroup          = @("ExistingContactGroup")
            $sccg.set() } | Should not throw
    }
    
    It "Should be able to delete an SSL check" {   # This test only works against a premium account. commenting out temporarily until we can add a reasonable mock
        
        do {
            Write-Output "Waiting for test https://www.$uniquekey.net to exist..."
            $statusCakeSSLTest = [StatusCakeSSL]::New()
            $statusCakeSSLTest.Name                 = "https://www.$uniquekey.net"
            $statusCakeSSLTest.Ensure               = "Present"
            $statusCakeSSLTest.CheckRate            = 300
            $statusCakeSSLTest.AlertOnExpiration    = $false
            $statusCakeSSLTest.AlertOnProblems      = $true
            $statusCakeSSLTest.AlertOnReminders     = $true
            $statusCakeSSLTest.FirstReminderInDays  = 25;
            $statusCakeSSLTest.SecondReminderInDays = 7
            $statusCakeSSLTest.FinalReminderInDays  = 4
            $statusCakeSSLTest.ContactGroup         = @("ExistingContactGroup")
    
            $found = $statusCakeSSLTest.Test()
            if (-not $found) {
                Write-Output "SSL Test $($statusCakeSSLTest.Name) not yet created. Waiting 3 seconds"
                Start-Sleep -seconds 3
            }
        } while (-not $found)

        $sccg.Name          = "https://www.$uniquekey.net"
        $sccg.Ensure        = 'Absent'
        $sccg.ContactGroup  = @("ExistingContactGroup")
        $sccg.Set() 
    }
}
