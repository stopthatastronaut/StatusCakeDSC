enum Ensure
{
    Absent
    Present
}

enum Location
{
    PRIVATE
    AU
    CA
    DE
    IN
    NL
    SG
    UK
    US
}

[DscResource()]
class StatusCakeSSL
{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Name
    
    [DScProperty()]
    [PSCredential] $ApiCredential = [PSCredential]::Empty

    [DscProperty()]
    [PSCredential]$BasicCredential = [PSCredential]::Empty

    [DscProperty()]
    [int] $CheckRate = 300  

    [DscProperty()]
    [string] $Url

    [DscProperty()]
    [Location] $Location

    [DscProperty()]
    [boolean] $AlertSmaller
    [DscProperty()]
    [boolean] $AlertBigger
	[DscProperty()]
    [boolean] $AlertSlower


    [DScProperty()]
    [string[]] $ContactGroup
    [DscProperty()]
    [int] $MaxRetries = 5

    [DscProperty(NotConfigurable)]
    [int] $id  

    [DscProperty(NotConfigurable)]
    [int[]] $ContactGroupID 

    
    [void] Set()
    {        
        $refObject = $this.Get()
        $testOK = $this.Test()
        $status = $null

        if($this.Ensure -eq [Ensure]::Absent -and $refObject.id -ne 0)
        {
            # we need to delete it"
            Write-Verbose ("Deleting Test " + $this.Name + " ID: " + $refObject.id)
            $status = $this.GetApiResponse(("/Pagespeed/Update?id=$($refObject.id)"), 'DELETE', $null)
        }
        elseif($this.Ensure -eq [Ensure]::Present)
        {
            if($refObject.id -eq 0)
            {
                # we need to create it                
                Write-Verbose ("Creating SSL Check " + $this.Name)
                $status = $this.GetApiResponse(('/Pagespeed/Update'), "PUT", $this.GetObjectToPost(0, $this.ResolveContactGroups($this.contactGroup)))
            }
            else
            {
                # we need to update it
                Write-Verbose ("Updating SSL Check " + $this.Name)
                $status = $this.GetApiResponse(('/Pagespeed/Update'), "PUT", $this.GetObjectToPost($refObject.id, $this.ResolveContactGroups($this.contactGroup)))
            }
                
        }

        if($null -ne $status)
        {
            Write-Verbose ("Status returned from API: " + ($status | ConvertTo-json -depth 4))
        }        
    }        
    
    [bool] Test()
    {        
        $testOK = $true # assume it's fine
        $refobject = $this.Get()

        if($this.Ensure -ne $refObject.Ensure)
        {
            Write-Verbose ("Ensure differs, expecting: '{0}' but seeing: '{1}'" -f $this.Ensure, $refObject.Ensure)
            $testOK = $false
        }

        if($this.Name -ne $refobject.Name)
        {
            Write-Verbose ("Test Name has changed, expecting: '{0}' but seeing: '{1}'" -f $this.Name, $refobject.Name)
            $testOK = $false
        }

        if($this.Url -ne $refobject.Url)
        {
            Write-Verbose ("Url has changed, expecting: '{0}' but seeing: '{1}'" -f $this.Name, $refobject.Name)
            $testOK = $false
        }

        if($this.CheckRate -ne $refobject.CheckRate)
        {
            Write-Verbose ("Check rate differs, expecting: '{0}' but seeing: '{1}'" -f $this.CheckRate, $refobject.CheckRate)
            $testOK = $false
        }

        if($this.ContactGroup -ne $refObject.ContactGroup)
        {
            $ExpectedContactGroups = $this.ContactGroup | ? { $_ }
            $ActualContactGroups = $refObject.ContactGroup | ? { $_ }
            Write-Verbose ("Contact Groups have Changed, expecting: '{0}' but seeing: '{1}'" -f $ExpectedContactGroups,  $ActualContactGroups)
            $testOK = $false
        }

        if($this.AlertSmaller -ne $refObject.AlertSmaller)
        {
            Write-Verbose ("AlertSmaller have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.AlertSmaller, $refObject.AlertSmaller)
            $testOK = $false
        }


        if($this.AlertBigger -ne $refObject.AlertBigger)
        {
            Write-Verbose ("AlertBigger have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.AlertBigger, $refObject.AlertBigger)
            $testOK = $false
        }

        if($this.AlertSlower -ne $refObject.AlertSlower)
        {
            Write-Verbose ("AlertSlower have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.AlertSlower, $refObject.AlertSlower)
            $testOK = $false
        }

        return $testOK
    }

    [void] Validate()
    {
        write-verbose "Starting Validation" 
        if($this.CheckRate -ge 24000)
        {
            throw "Checkrate cannot be larger than 24000"
        }

        if($this.CheckRate -le 0)
        {
            throw "Checkrate cannot be zero or negative"
        }
        if($this.ContactGroup -ne $null)
        {
            $CheckContactGroupId = $this.ResolveContactGroups($this.contactGroup)    
            if ($($CheckContactGroupId.count) -eq 0){
                throw "You have specified a contact group that doesn't exist, cannot proceed."
            }
        }
        write-verbose "Finishing Validation" 
    }
  
    [StatusCakeSSL] Get()
    {        
        # first things first, validate
        $this.Validate();
        
        # does it exist?
        $checkId = $this.GetApiResponse("/Pagespeed/", "GET", $null) | Where-Object {$_.domain -eq $this.Name} | Select-Object -expand id
        $returnobject = [StatusCakeSSL]::new()      

        # need a check here for duped by name
        if(($checkId | Measure-Object | Select-Object -expand Count) -gt 1)
        {
            throw "Multiple Ids found with the same name. StatusCakeDSC uses Test Name as a unique key, and cannot continue"
        }

        if(($checkId | Measure-Object | Select-Object -expand Count) -le 0)
        {
            Write-Verbose "Looks like our check doesn't exist"
            # check doesn't exist      
            $returnObject.Ensure = [Ensure]::Absent
            $returnobject.Name = $this.Name #is property: domain
            $returnobject.Url = $this.Url
            $returnobject.CheckRate = $this.CheckRate
            $returnobject.AlertSmaller = $this.AlertSmaller 
            $returnobject.AlertBigger = $this.AlertBigger 
            $returnobject.AlertSlower = $this.AlertSlower  
            $returnobject.ContactGroup = $this.ContactGroup
            $returnobject.id = 0 # null misbehaves
            #$this.TestID = 0
        }
        else
        {
            Write-Verbose "Check exists, fetching details from remote"
            $sslDetails = $this.GetApiResponse("/Pagespeed/?id=$checkId", 'GET', $null)    
                                    
            $returnObject.Ensure = [Ensure]::Present
            $returnobject.Name = $this.Name
            $returnobject.Url = $this.website_url
            $returnobject.CheckRate = $this.checkrate
            $returnobject.AlertSmaller = $sslDetails.alert_smaller
            $returnobject.AlertBigger= $sslDetails.alert_bigger
            $returnobject.AlertSlower = $sslDetails.alert_slower
            $returnobject.ContactGroup = $this.ResolveContactGroupIdsToNames($sslDetails.contact_groups)
            $returnObject.id = $CheckID
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

    [int[]] ResolveContactGroups([string[]]$cgNames)
    {
        Write-Verbose "Resolving Contact Groups ($cgNames) to IDs"
        $groups = $this.GetApiResponse("/ContactGroups", 'GET', $null)
        $r = @()
        for($x=0;$x -lt $cgNames.Length;$x++) {
            Write-Verbose (" - Resolving group name " + $cgNames[$x])
            $r += ($groups | Where-Object { $_.GroupName -eq $cgNames[$x] } | Select-Object -expand ContactID)
        }
        Write-Verbose (" - Found Contact Groups " + ($r -join ","))
        return $r
    }

    [string[]] ResolveContactGroupIdsToNames([int[]]$contactGroupIds)
    {
        Write-Verbose "Resolving Contact Groups ($contactGroupIds) to names"
        $groups = $this.GetApiResponse("/ContactGroups", 'GET', $null)
        $r = @()
        for($x=0;$x -lt $contactGroupIds.Length;$x++) {
            Write-Verbose (" - Resolving group id " + $contactGroupIds[$x])
            $r += ($groups | Where-Object { $_.ContactID -eq $contactGroupIds[$x] } | Select-Object -expand GroupName)
        }
        Write-Verbose (" - Found Contact Groups " + ($r -join ","))
        return $r
    }

    [Object] GetObjectToPost([int]$id, [int[]]$ContactGroupID)
    {
        $p = 0
        if($this.paused -eq $true)
        {
            $p = 1
        }
		[String] $alertAt = ([string]$this.FinalReminderInDays + ',' + [string]$this.SecondReminderInDays + ',' + [string]$this.FirstReminderInDays)


        $r = @{
          name = $this.Name #required - String
          website_url = $this.Url #required - String
          checkrate = $this.CheckRate #required - integer
          contact_groups = ($ContactGroupID -join ",") #required - but can be an empty string
          alert_smaller = $this.AlertSmaller
          alert_bigger = $this.AlertBigger
          alert_slower = $this.AlertSlower
          location_iso = $this.Location
          #paused = $p
        }
        
        if($this.BasicCredential -ne [PSCredential]::Empty)
        {
            Write-Verbose "Adding Basic Password and user"
            $r.Add("BasicUser", $this.BasicCredential.UserName)
            $r.Add("BasicPass", $this.BasicCredential.GetNetworkCredential().Password)
        }
        
        if($id -ne 0)
        {
            Write-Verbose "Adding a checkID to post object, as we're updating"
            $r.add("id", $id)
        }
        return $r
    }
}
