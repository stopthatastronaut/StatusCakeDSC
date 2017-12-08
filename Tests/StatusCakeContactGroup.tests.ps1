ipmo Pester

# load it into memory
iex (gc .\Modules\StatusCakeDSC\StatusCakeContactGroup.psm1 -raw)

Describe "Object and Properties" {
    # inspect the object here
}

Describe "The statuscakecontactgroup HTTP bits" {
    It "Can list out contact groups" {
        { $sccg = [StatusCakeContactGroup]::New()        
            $sccg.GetApiResponse("/ContactGroups/", "GET", $null) } | Should Not Throw
    }

    It "Can create a new contact group" {
        # $VerbosePreference = "Continue"
        $sccg = [StatusCakeContactGroup]::New() 
        $sccg.Email = @('stopthatastronaut@gmail.com', 'stopthatastronaut2@gmail.com')
        $sccg.GroupName = "test add group"
        $sccg.Ensure = "Present"

        $sccg.Set()

        $newgroupID = $sccg.Get().ContactID

        $newgroupID | Should Not Be 0

    }



    It "Can delete a contact group" {
        # $VerbosePreference = "Continue"
        $sccg2 = [StatusCakeContactGroup]::New() 
        $sccg2.Email = @('stopthatastronaut@gmail.com', 'stopthatastronaut2@gmail.com')
        $sccg2.GroupName = "test add group"
        $sccg2.Ensure = "Absent"

        $sccg2.Set()

        # should now be gone, check:
        $sccg3 = [StatusCakeContactGroup]::New() 
        $sccg3.Email = @('stopthatastronaut@gmail.com', 'stopthatastronaut2@gmail.com')
        $sccg3.GroupName = "test add group"
        $sccg3.Ensure = "Absent"

        $sccg3.Get().ContactID | Should Be 0
    }
}


