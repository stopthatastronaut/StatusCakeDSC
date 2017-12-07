enum Ensure
{
    Absent
    Present
}

[DscResource()]
class StatusCakeContactGroup
{

    [DscProperty(Key)]
    [string]$GroupName
    [DscProperty(Mandatory)]
    [Ensure] $Ensure
    [DscProperty()]   
    
    # if these two are unset, it will look for a .creds file in the module directory
    [string] $apiKey
    [DscProperty()]
    [string] $UserName
        
    [DscProperty()]
    [bool] $DesktopAlert
    [DscProperty()]
    [string[]] $Email
    [DscProperty()]
    [string] $Boxcar
    [DscProperty()]
    [string] $Pushover
    [DscProperty()]
    [string] $PingUrl
    [DscProperty()]
    [string[]] $mobile
    
    [DscProperty(NotConfigurable)] # if it exists, we use this to update it
    [nullable[int]] $ContactID = $null
    
    # Sets the desired state of the resource.
    [void] Set()
    {
        $refObject = $this.Get()

        if($this.Ensure -eq "Absent")
        {
            # we neded to delete it"
            Write-Verbose ("Deleting Contact Group " + $this.ContactID)
            $status = $this.GetApiResponse(('/ContactGroups/Update/?ContactID=' + $this.ContactID), "DELETE", $null)
        }
        else
        {
            # we either need to create or update
            if($this.ContactID -eq $null)
            {
                #create
                Write-Verbose ("Creating Contact Group " + $this.GroupName)
                $status = $this.GetApiResponse(('/ContactGroups/Update/'), "PUT", $this.GetObjectToPost())
            }
            else
            {
                # modify
                Write-Verbose ("Modifying Contact Group " + $this.ContactID)
                $status = $this.GetApiResponse(('/ContactGroups/Update/?ContactID=' + $this.ContactID), "PUT", $this.GetObjectToPost($this.ContactID))
            }
        }
    }        
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {        
        $contactOK = $true # assume it's fine
        $refObject = $this.Get()
        
        Write-Verbose ("Checking Contact Group ID " + $this.ContactID)

        # do they differ?
        $diff = Compare-Object $refObject $this   # this is pretty much useless
        if($diff -ne $null)
        {
            Write-Verbose "Found differences in shallow compare"
            $contactOK = $false
        }
        else
        {
            Write-Verbose "Found no differences by shallow compare"
        }

        if($this.Boxcar -ne $refObject.Boxcar)
        {
            Write-Verbose "Boxcar spec differs"
            $contactOK = $false
        }

        if($this.Pushover -ne $refObject.Pushover)
        {
            Write-Verbose "Pushover spec has changed"
            $contactOK = $false
        }

        if($this.PingUrl -ne $refObject.PingUrl)
        {
            Write-Verbose "PingUrl spec has changed"
            $contactOK = $false
        }

        if($this.DesktopAlert -eq $refObject.DesktopAlert)
        {
            Write-Verbose "Desktop alert spec has changed"
            $contactOK = $false
        }
        
        if($this.Email -ne $refObject.Email)
        {
            Write-Verbose "Email list has changed"
            $contactOK = $false
        }

        if($this.mobile -ne $refObject.mobile)
        {
            Write-verbose "Mobile Numbers have changed"
            $contactOK = $false
        }
        return $contactOK
    }    

    # Gets the resource's current state.
    [StatusCakeContactGroup] Get()
    {    
        # does it exist?
        $scContact = $this.GetApiResponse("/ContactGroups/", "GET", $null) | ? { $_.Groupname -eq $this.GroupName }
        $returnobject = [StatusCakeContactGroup]::new()

        
        if($sccontact -ne $null)
        {
            # it exists in StatusCake
            Write-Verbose ("I found a contact group with ID " +  $scContact.contactID)
            $returnobject.Ensure = [Ensure]::Present
            $returnObject.ContactID = $sccontact.ContactId
            $this.ContactID = $sccontact.ContactID
            $returnobject.GroupName = $scContact.Groupname
            $returnobject.Email = $scContact.Emails
            $returnobject.Boxcar = $scContact.Boxcar
            $returnobject.DesktopAlert = ($scContact.DesktopAlert -eq 1)
            $returnobject.mobile = $scContact.mobiles
            $returnobject.Pushover = $scContact.pushover
            $returnObject.PingUrl = $scContact.PingUrl 
        }
        else
        {
            # it does not exist in Statuscake
            Write-verbose "I found no contact group with this name in StatusCake"
            $returnObject.Ensure = [Ensure]::Absent
            # everything else can be null or default, I think
        }

        
        return $this 
    }

    [Object] GetApiResponse($stem, $method = 'GET', $body = $null)
    {
        if($body -ne $null)
        {
            Write-Verbose ($body | convertto-json -depth 4)
        }

        $creds = @{}
        if(-not $this.ApiKey)
        {
            # no Api Key provided, grab 'em off the disk
            if(-not (Test-Path "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.creds" ))
            {
                throw "No credentials specified and no .creds file found"
            }
            else
            {
                $creds = gc "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.creds" | ConvertFrom-Json 

                $this.ApiKey = $creds.ApiKey
                $this.UserName = $creds.UserName
            }
        }
        if($method -ne 'GET')
        {
            return irm "https://app.statuscake.com/API$stem" `
                -method $method -body $body -headers @{API = $this.ApiKey; username = $this.UserName} `
                -ContentType "application/x-www-form-urlencoded"
        }
        else
        {
            return irm "https://app.statuscake.com/API$stem" `
                -method GET -headers @{API = $this.ApiKey; username = $this.UserName}                 
        }
    }

    [Object] GetObjectToPost($contactID)
    {
        $da = 0
        if($this.DesktopAlert -eq $true)
        {
            Write-Verbose "Setting Desktop alert property to 1"
            $da = 1
        }

        $r =  @{
            GroupName = $this.GroupName
            Desktopalert = $da
            Email = ($this.Email -join ",")
        }

        if($this.Boxcar -ne $null)
        {
            $r | Add-Member -MemberType NoteProperty -Name Boxcar -Value $this.Boxcar
        }

        if($this.Pushover -ne $null)
        {
            $r | Add-Member -MemberType NoteProperty -Name Pushover -Value $this.Pushover
        }

        if($this.PingUrl -ne $null)
        {
            $r | Add-Member -MemberType NoteProperty -Name PingUrl -Value $this.PingUrl
        }

        if($this.Mobile.Length -ne 0)
        {
            $r | Add-Member -MemberType NoteProperty -Name Mobile -Value ($this.mobile -join ",")
        }

        if($contactID -ne 0)
        {
            $r | Add-Member -MemberType NoteProperty -Name ContactID -Value $contactID    
            Write-Verbose "Adding ContactID: $contactID to outgoing body"        
        }
        return $r
    }

    [Object] GetObjectToPost()
    {
        return $this.GetObjectToPost(0)
    }
}