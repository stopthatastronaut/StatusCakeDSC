ipmo Pester

# load it into memory
iex (gc .\Modules\StatusCakeDSC\StatusCakeContactGroup.psm1 -raw)

Describe "Object and Properties" {

}

Describe "The statuscakecontactgroup HTTP bits" {
    It "Can list out contact groups" {
        { $sccg = [StatusCakeContactGroup]::New()        
            $sccg.GetApiResponse("/ContactGroups/", "GET", $null) } | Should Not Throw
    }

    It "Can create a new contact group" {

    }

    It "Can delete a contact group" {

    }
}


