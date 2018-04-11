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
    
    [DScProperty()]
    [PSCredential] $ApiCredential = [PSCredential]::Empty
        
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

        if($this.Ensure -eq "Absent" -and $refObject.ContactID -ne 0)
        {
            # we needed to delete it"
            Write-Verbose ("Deleting Contact Group " + $refObject.ContactID)
            $status = $this.GetApiResponse(('/ContactGroups/Update/?ContactID=' + $this.ContactID), "DELETE", $null)
        }
        else
        {
            # we either need to create or update
            if($refObject.ContactID -eq 0)
            {
                #create
                Write-Verbose ("Creating Contact Group " + $this.GroupName)
                $status = $this.GetApiResponse(('/ContactGroups/Update/'), "PUT", $this.GetObjectToPost())
            }
            else
            {
                # modify
                Write-Verbose ("Modifying Contact Group " + $refObject.ContactID)
                $status = $this.GetApiResponse(('/ContactGroups/Update/?ContactID=' + $this.ContactID), "PUT", $this.GetObjectToPost($refObject.ContactID))
            }

            $status 
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
        $scContact = $this.GetApiResponse("/ContactGroups/", "GET", $null) | Where-Object { $_.Groupname -eq $this.GroupName }
        $returnobject = [StatusCakeContactGroup]::new()

        if(($scContact | Measure-Object | Select-Object -expand Count) -gt 1)
        {            
            throw "Multiple Ids found with the same name. StatusCakeDSC uses Test Name as a unique key, and cannot continue"
        }
        
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
            $returnObject.ContactID = 0  # null is known to misbehave, so let's set this to 0
            $returnobject.GroupName = $this.GroupName
            $returnObject.Email = $this.Email
            $returnObject.Boxcar = $this.Boxcar
            $returnObject.DesktopAlert = $this.DesktopAlert
            $returnobject.mobile = $this.mobile
            $returnobject.Pushover = $this.Pushover
            $returnobject.PingUrl = $this.PingUrl
        }
        
        return $returnobject
    }

    [Object] GetApiResponse($stem, $method = 'GET', $body = $null)
    {
        if($body -ne $null)
        {
            Write-Verbose ($body | convertto-json -depth 4)
        }

        $creds = @{}
        if($this.ApiCredential -eq [PSCredential]::Empty)
        {
            # no Api Key provided, grab 'em off the disk
            if(-not (Test-Path "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.securecreds" ))
            {
                throw "No credentials specified and no .securecreds file found"
            }
            else
            {
                # needs a "find the creds file" function, I suspect
                $creds = Get-Content "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.securecreds" | ConvertFrom-Json 

                # needs converting for secure creds
                $secapikey = ConvertTo-SecureString $creds.ApiKey 
                $this.ApiCredential = [PSCredential]::new($creds.UserName, $secapikey)
            }
        }

        $headers = @{
                API = $this.ApiCredential.GetNetworkCredential().Password; 
                username = $this.ApiCredential.UserName;
            }

        if($method -ne 'GET')
        {
            $httpresponse = Invoke-RestMethod "https://app.statuscake.com/API$stem" `
                -method $method -body $body -headers $headers `
                -ContentType "application/x-www-form-urlencoded" `
                -MaximumRedirection 0
        }
        else
        {
            $httpresponse = Invoke-RestMethod "https://app.statuscake.com/API$stem" `
                -method GET -headers $headers                 
        }

        if(($httpresponse.issues | Measure-Object | Select-Object -expand Count) -gt 0 ) {
            throw ($httpresponse.Issues | out-string)
        }

        return $httpresponse
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