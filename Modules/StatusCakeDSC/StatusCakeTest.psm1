enum Ensure
{
    Absent
    Present
}

[DscResource()]
class StatusCakeTest
{
    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Key)]
    [string]$Name
    
    [DScProperty()]
    [PSCredential] $ApiCredential = [PSCredential]::Empty

    [DscProperty()]
    [string] $URL
    [DscProperty()]
    [int] $Port = 80
    [DscProperty()]
    # [ValidateScript( { $_ -lt 24000 -and $_ -gt 0} )]
    [int] $CheckRate = 300  # default 300. > 0 and < 24000
    [DscProperty()]
    [int] $Timeout
    [DscProperty()]
    [PSCredential]$BasicCredential = [PSCredential]::Empty
    [DscProperty()]
    [bool] $Public
    [DscProperty()]
    [bool] $Paused =  $false
    [DscProperty()]
    [ValidateSet('HTTP', 'TCP', 'PING')]
    [string] $TestType = 'HTTP'
    [DscProperty()]
    [string] $FindString
    [DScProperty()]
    [string[]] $ContactGroup


    [DscProperty(NotConfigurable)]
    [int] $TestID   # if the test exists in Statuscake, we populate this with the ID
    [DscProperty(NotConfigurable)]
    [int[]] $ContactGroupID 

    
    [void] Set()
    {        
        $refObject = $this.Get()

        if($this.Ensure -eq [Ensure]::Absent)
        {
            # we need to delete it"
            Write-Verbose ("Deleting Test " + $this.Name)
            $status = $this.GetApiResponse(("/Tests/Details/?TestID=" + $refObject.TestID), 'DELETE', $null)
        }
        else
        {
            if($refObject.TestID -eq 0)
            {
                # we need to create it                
                Write-Verbose ("Creating Test " + $this.Name)
                $status = $this.GetApiResponse(('/Tests/Update/'), "PUT", $this.GetObjectToPost(0, $this.ResolveContactGroups($this.contactGroup)))
            }
            else
            {
                # we need to update it
                Write-Verbose ("Updating Test " + $this.Name)
                $status = $this.GetApiResponse(('/Tests/Update/'), "PUT", $this.GetObjectToPost($refObject.TestId, $this.ResolveContactGroups($this.contactGroup)))
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
            Write-Verbose "Ensure differs"
            $testOK = $false
        }

        if($this.CheckRate -ne $refobject.CheckRate)
        {
            Write-Verbose "Check rate differs"
            $testOK = $false
        }

        if($this.URL -ne $refobject.URL)
        {
            Write-Verbose "URL has changed"
            $testOK = $false
        }

        if($this.ContactGroup -ne $refObject.ContactGroup)
        {
            Write-Verbose "Contact Groups have Changed"
            $testOK = $false
        }

        return $testOK
    }

    [void] Validate()
    {
        if($this.CheckRate -ge 24000)
        {
            throw "Checkrate cannot be larger than 24000"
        }

        if($this.CheckRate -le 0)
        {
            throw "Checkrate cannot be zero or negative"
        }

        
    }

    [StatusCakeTest] Get()
    {        
        # first things first, validate
        $this.Validate();
        
        # does it exist?
        $checkId = $this.GetApiResponse("/Tests/", "GET", $null) | Where-Object {$_.WebsiteName -eq $this.Name} | Select-Object -expand TestId
        $returnobject = [StatusCakeTest]::new()      

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
            $returnobject.Name = $this.Name
            $returnobject.URL = $this.URL
            $returnobject.CheckRate = $this.checkrate
            $returnobject.Paused = $this.Paused
            $returnobject.ContactGroup = $this.ContactGroup
            $returnobject.ContactGroupID = $this.ResolveContactGroups($this.contactGroup)
            $returnobject.TestID = 0 # null misbehaves
            #$this.TestID = 0
        }
        else
        {
            Write-Verbose "Check exists, fetching details from remote"
            $testDetails = $this.GetApiResponse("/Tests/Details/?TestID=$checkId", 'GET', $null)    
                                    
            $returnObject.Ensure = [Ensure]::Present
            $returnobject.Name = $this.Name
            $returnobject.URL = $testDetails.URI
            $returnobject.CheckRate = $testdetails.CheckRate
            $returnobject.Paused = $testdetails.paused 
            $returnobject.ContactGroup = $testDetails.ContactGroups | select-object -expand Name
            $returnobject.ContactGroupID = $testdetails.ContactGroups | select-object -expand ID
            $returnObject.TestID = $CheckID
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
                throw "No credentials specified and no .creds file found"
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
            $httpresponse = Invoke-RestMethod "https://app.statuscake.com/API$stem" `
                -method $method -body $body -headers $headers `
                -ContentType "application/x-www-form-urlencoded" 
        }
        else
        {
            $httpresponse =  Invoke-RestMethod "https://app.statuscake.com/API$stem" `
                -method GET -headers $headers               
        }
        # if the issues array is not empty, we should throw here. probably

        if(($httpresponse.issues | measure-object | select-object -expand Count) -gt 0 ) {
            throw ($httpresponse.Issues | out-string)
        }

        return $httpresponse
    }

    [int[]] ResolveContactGroups([string[]]$cgNames)
    {
        Write-Verbose "Resolving Contact Groups"
        $groups = $this.GetApiResponse("/ContactGroups", 'GET', $null)
        $r = @()
        for($x=0;$x -lt $cgNames.Length;$x++) {
            Write-Verbose ("Resolving group name " + $cgNames[$x])
            $r += ($groups | Where-Object { $_.GroupName -eq $cgNames[$x] } | Select-Object -expand ContactID)
        }
        Write-Verbose ("Found Contact Groups " + ($r -join ","))
        return $r
    }

    [Object] GetObjectToPost([int]$TestID, [int[]]$ContactGroupID)
    {
        $p = 0
        if($this.Paused -eq $true)
        {
            $p = 1
        }

        # mandatories
        $r = @{  # hashtable
            WebsiteName = $this.Name
            WebsiteURL = $this.URL
            CheckRate = $this.CheckRate
            TestType = $this.TestType
            Paused = $p
        }
        
        # optionals
        if($ContactGroupID.length -gt 0)
        {
            Write-Verbose "Adding Contact group to post object"
            $r.add("ContactGroup", ($ContactGroupID -join ","))
        }

        if($this.BasicCredential -ne [PSCredential]::Empty)
        {
            Write-Verbose "Adding Basic Password and user"
            $r.Add("BasicUser", $this.BasicCredential.UserName)
            $r.Add("BasicPass", $this.BasicCredential.GetNetworkCredential().Password)
        }
        
        if($TestID -ne 0)
        {
            Write-Verbose "Adding a checkID to post object, as we're updating"
            $r.add("TestID", $TestID)
        }
        return $r
    }
}

<#

Node locations: 
(only valid for premium accounts)

Australia � Sydney
Austria � Vienna
Belgium � Oostkamp
Brazil � Sao Paulo
Canada � Montreal
Canada � Toronto
Chile � Vina Del Mar
France � Paris
France � Lille
Germany � Berlin
Germany � Frankfurt
Hong Kong
Hungary � Budapest
Ireland � Dublin
Japan � Tokyo
Mexico � Mexico City
Netherlands � Amsterdam
Iceland � Reykjav�k
India � Bangalore
Israel � Tel Aviv
Italy � Milano
Mexico � Mexico City
New Zealand- Auckland
Poland � Warsaw
Russia � Moscow
Russia � Novosibirsk
Singapore
South Africa � Johannesburg
Spain � Madrid
Sweden � Stockholm
Switzerland � Bern
United Kingdom � London
United Kingdom � Manchester
United States � Atlanta, Georgia
United States � Chicago, Illinois
United States � Dallas, Texas
United States � Jacksonville, Florida
United States � Los Angeles, California
United Status � San Francisco, California
United States � Silicon Valley, California
United States � Phoenix, Arizona,
United States � New York, New York

#>