enum Ensure
{
    Absent
    Present
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
    [boolean] $AlertOnExpiration
    [DscProperty()]
    [boolean] $AlertOnProblems
	[DscProperty()]
    [boolean] $AlertOnReminders

    [DscProperty()]
    [int] $FirstReminderInDays = 30 

	[DscProperty()]
    [int] $SecondReminderInDays = 7  

	[DscProperty()]
    [int] $FinalReminderInDays = 1  

    [DScProperty()]
    [string[]] $ContactGroup
    [DscProperty()]
    [int] $MaxRetries = 5
    [int] $MaxRetries = 10

    [DscProperty()]
    [bool] $paused =  $false

    [DscProperty(NotConfigurable)]
    [int] $id  

    [DscProperty(NotConfigurable)]
    [int[]] $ContactGroupID 

    
    [void] Set()
    {        
        $refObject = $this.Get()
        $testOK = $this.Test()

        if($this.Ensure -eq [Ensure]::Absent -and $refObject.id -ne 0)
        {
            # we need to delete it"
            Write-Verbose ("Deleting Test " + $this.Name + " ID: " + $refObject.id)
            $status = $this.GetApiResponse(("/SSL/Update?id=$($refObject.id)"), 'DELETE', $null)
        }
        else
        {
            if($refObject.id -eq 0)
            {
                # we need to create it                
                Write-Verbose ("Creating SSL Check " + $this.Name)
                $status = $this.GetApiResponse(('/SSL/Update'), "PUT", $this.GetObjectToPost(0, $this.ResolveContactGroups($this.contactGroup)))
            }
            else
            {
                # we need to update it
                Write-Verbose ("Updating SSL Check " + $this.Name)
                $status = $this.GetApiResponse(('/SSL/Update'), "PUT", $this.GetObjectToPost($refObject.id, $this.ResolveContactGroups($this.contactGroup)))
            }
                
        }
        Write-Verbose ("Status returned from API: " + ($status | ConvertTo-json -depth 4))
        
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
            Write-Verbose ("Domain Name has changed, expecting: '{0}' but seeing: '{1}'" -f $this.Name, $refobject.Name)
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

        if($this.AlertOnExpiration -ne $refObject.AlertOnExpiration)
        {
            Write-Verbose ("AlertOnExpiration have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.AlertOnExpiration, $refObject.AlertOnExpiration)
            $testOK = $false
        }


        if($this.AlertOnProblems -ne $refObject.AlertOnProblems)
        {
            Write-Verbose ("AlertOnProblems have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.AlertOnProblems, $refObject.AlertOnProblems)
            $testOK = $false
        }

        if($this.AlertOnReminders -ne $refObject.AlertOnReminders)
        {
            Write-Verbose ("AlertOnReminders have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.AlertOnReminders, $refObject.AlertOnReminders)
            $testOK = $false
        }

        if($this.FirstReminderInDays -ne $refObject.FirstReminderInDays)
        {
            Write-Verbose ("FirstReminderInDays have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.FirstReminderInDays, $refObject.FirstReminderInDays)
            $testOK = $false
        }

        if($this.SecondReminderInDays -ne $refObject.SecondReminderInDays)
        {
            Write-Verbose ("SecondReminderInDays have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.SecondReminderInDays, $refObject.SecondReminderInDays)
            $testOK = $false
        }

        if($this.FinalReminderInDays -ne $refObject.FinalReminderInDays)
        {
            Write-Verbose ("FinalReminderInDays have Changed, expecting: '{0}' but seeing: '{1}'" -f $this.FinalReminderInDays, $refObject.FinalReminderInDays)
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
        $checkId = $this.GetApiResponse("/SSL/", "GET", $null) | Where-Object {$_.domain -eq $this.Name} | Select-Object -expand id
        $returnobject = [StatusCakeSSL]::new()      

        # need a check here for duped by name
        if(($checkId | Measure-Object | Select -expand Count) -gt 1)
        {
            throw "Multiple Ids found with the same name. StatusCakeDSC uses Test Name as a unique key, and cannot continue"
        }

        if(($checkId | Measure-Object | Select -expand Count) -le 0)
        {
            Write-Verbose "Looks like our check doesn't exist"
            # check doesn't exist      
            $returnObject.Ensure = [Ensure]::Absent
            $returnobject.Name = $this.Name #is property: domain
            #$returnobject.paused = $this.paused
            $returnobject.AlertOnExpiration = $this.AlertOnExpiration 
            $returnobject.AlertOnProblems = $this.AlertOnProblems 
            $returnobject.AlertOnReminders = $this.AlertOnReminders  
            $returnobject.FirstReminderInDays = $this.FirstReminderInDays  
            $returnobject.SecondReminderInDays = $this.SecondReminderInDays 
			$returnobject.FinalReminderInDays = $this.FinalReminderInDays 
            $returnobject.ContactGroup = $this.contactGroup
            $returnobject.id = 0 # null misbehaves
            #$this.TestID = 0
        }
        else
        {
            Write-Verbose "Check exists, fetching details from remote"
            $sslDetails = $this.GetApiResponse("/SSL/?id=$checkId", 'GET', $null)    
                                    
            $returnObject.Ensure = [Ensure]::Present
            $returnobject.Name = $this.Name
            #$returnobject.paused = $sslDetails.paused 
            $returnobject.AlertOnExpiration = $sslDetails.alert_expiry 
            $returnobject.AlertOnProblems = $sslDetails.alert_broken 
            $returnobject.AlertOnReminders = $sslDetails.alert_reminder
            $returnobject.FirstReminderInDays = $sslDetails.alert_at.split(',')[2]
            $returnobject.SecondReminderInDays = $sslDetails.alert_at.split(',')[1]
			$returnobject.FinalReminderInDays = $sslDetails.alert_at.split(',')[0]
            $returnobject.ContactGroup = $this.ResolveContactGroupIdsToNames($sslDetails.contact_groups)
            $returnObject.id = $CheckID
            #$this.TestID = $CheckID
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
            $h = Invoke-WebRequest @splat
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
          domain = $this.Name #required - String
          checkrate = $this.CheckRate #required - integer
          contact_groups = ($ContactGroupID -join ",") #required - but can be an empty string
          alert_at = $alertAt #required - String FinalReminderInDays, SecondReminderInDays, FirstReminderInDays.
          alert_expiry = $this.AlertOnExpiration #required - Boolean
          alert_reminder = $this.AlertOnReminders #required - Boolean
          alert_broken = $this.AlertOnProblems #required - Boolean
          #paused = $p
        }
        
        # optionals
        <#
        if($ContactGroupID.length -gt 0)
        {
            Write-Verbose "Adding Contact group to post object"
            $r.add("ContactGroup", ($ContactGroupID -join ","))
        }
        #>
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
