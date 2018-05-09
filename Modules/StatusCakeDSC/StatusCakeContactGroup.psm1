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
    [string[]] $mobile = @()

    [DscProperty()]
    [int] $MaxRetries = 5
    
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
        if($null -ne $diff)
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
        
        if($null -ne $sccontact)
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
            Write-Verbose "I found no contact group with this name in StatusCake"
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

    [Object] GetApiResponse($stem, $method, $body)
    {
        if($null -ne $body)
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
                $creds = Get-Content "$env:ProgramFiles\WindowsPowerShell\Modules\StatusCakeDSC\.securecreds" | ConvertFrom-Json 

                $secapikey = ConvertTo-SecureString $creds.ApiKey 
                $this.ApiCredential = [PSCredential]::new($creds.UserName, $secapikey)
            }
        }

        $headers = @{
            API = $this.ApiCredential.GetNetworkCredential().Password; 
            username = $this.ApiCredential.UserName
        }

        if($method -ne 'GET')
        {
            $splat = @{ 
                uri = "https://app.statuscake.com/API$stem";
                method = $method;
                body = $body;
                headers = $headers;
                ContentType = "application/x-www-form-urlencoded";
            }
        }
        else
        {
            $splat = @{
                uri = "https://app.statuscake.com/API$stem";
                method = "GET";
                headers = $headers;
            }
        }
 
        try {   
            $h = Invoke-WebRequest @splat -UseBasicParsing
            $httpresponse = $this.CopyObject($h)
            $httpresponse | Add-Member -MemberType NoteProperty -Name body -Value ($h.Content | ConvertFrom-Json)
        }
        catch{
            if($Error.Exception)
            {
                # if PS 6, we're shot. this'll work for PS5
                $r = $_.Exception.Response
                $httpresponse = $this.copyObject($r)
                $httpresponse | Add-Member -MemberType NoteProperty -Name body -Value ($r.Content | ConvertFrom-Json)
            }
            else {
                throw "No usable response received"
            }  

        }

        # SSL checks don't have an issues array like Tests. They have a Message field and a Success bool
        if($httpresponse.statuscode -ne 200 ) {
            throw ($httpresponse.body.message | out-string)
        }

        return $httpresponse.body 
    }

    [object] CopyObject([object]$from)
    {
        $to = [pscustomobject]@{}
        foreach ($p in Get-Member -In $from -MemberType Property -Name *)
        {  trap {
                Add-Member -In $To -MemberType NoteProperty -Name $p.Name -Value $From.$($p.Name) -Force
                
                continue
            }
            $to.$($p.Name) = $from.$($p.Name)
            # we know this throws, remove its error
            $Error.RemoveAt(0)
        }
        return $to
    }

    [Object] InvokeWithBackoff([scriptblock]$ScriptBlock) {
        
        $backoff = 1
        $retrycount = 0
        $returnvalue = $null
        while($returnvalue -eq $null -and $retrycount -lt $this.MaxRetries) {
            try {
                $returnvalue = Invoke-Command $ScriptBlock
            }
            catch
            {
                Write-Verbose ($error | Select-Object -first 1 )
                Start-Sleep -MilliSeconds ($backoff * 500)
                $backoff = $backoff + $backoff
                $retrycount++
                Write-Verbose "invoking a backoff: $backoff. We have tried $retrycount times"
            }
        }
    
        return $returnvalue
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

        if($null -ne $this.Boxcar)
        {
            $r | Add-Member -MemberType NoteProperty -Name Boxcar -Value $this.Boxcar
        }

        if($null -ne $this.Pushover)
        {
            $r | Add-Member -MemberType NoteProperty -Name Pushover -Value $this.Pushover
        }

        if($null -ne $this.PingUrl)
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