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
    
    [DscProperty()]   # if these two are unset, it will look for a .creds file in the module directory
    [string] $ApiKey
    [DscProperty()]
    [string] $UserName

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
    [string] $BasicUser
    [DscProperty()]
    [string] $BasicPass
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
            if($refObject.TestID -eq $null)
            {
                # we need to create it
                
                Write-Verbose ("Creating Test " + $this.Name)
                $status = $this.GetApiResponse(('/Tests/Update/'), "PUT", $this.GetObjectToPost($this.TestID, $this.ContactGroupID))
            }
            else
            {
                # we need to update it
                Write-Verbose ("Updating Test " + $this.Name)
                $status = $this.GetApiResponse(('/Tests/Update/'), "PUT", $this.GetObjectToPost(0, $this.ContactGroupID))
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

    [bool] Validate()
    {
        $paramsOK = $true # assume we're OK

        if($this.CheckRate -ge 24000)
        {
            throw "Checkrate cannot be larger than 24000"
        }

        if($this.CheckRate -le 0)
        {
            throw "Checkrate cannot be zero or negative"
        }

        # if basic user, need basicpass and vice versa

        if($this.BasicUser -ne $null -and $this.BasicPass -eq $null)
        {
            throw "If specifying basic user, you must also include as password"
        }

        if($this.BasicUser -eq $null -and $this.BasicPass -ne $null)
        {
            throw "If specifying a basic password, you must also specify a username"
        }

        return $paramsOK
    }

    [StatusCakeTest] Get()
    {        
        # first things first, validate
        $this.Validate();
        
        # does it exist?
        $checkId = $this.GetApiResponse("/Tests/", "Get", $null) | ? {$_.WebsiteName -eq $this.Name} | Select -expand TestId
        $returnobject = [StatusCakeTest]::new()      

        # need a check here for duped by name


        if(-not $checkId)
        {
            Write-Verbose "Looks like our check doesn't exist"
            # check doesn't exist 
            $this.TestID = $null            
            $returnObject.Ensure = [Ensure]::Absent
            $returnobject.TestID = $null
            $returnobject.Name = $this.Name
            $returnobject.URL = $this.URL
            $returnobject.CheckRate = $this.checkrate
            $returnobject.Paused = $this.Paused
            $returnobject.ContactGroup = $this.ContactGroup
            $returnobject.ContactGroupID = $this.ResolveContactGroups($this.contactGroup)
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
            $returnobject.ContactGroup = $testDetails.ContactGroups | select -expand Name
            $returnobject.ContactGroupID = $testdetails.ContactGroups | select -expand ID
            $returnObject.TestID = $CheckID
            $this.TestID = $CheckID
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

    [int[]] ResolveContactGroups($cgNames)
    {
        Write-Verbose "Resolving Contact Groups"
        $groups = $this.GetApiResponse("/ContactGroups", 'GET', $null)
        $r = @()
        $cgNames | % {
            Write-Verbose ("Resolving group name " + $_)
            $r += ($groups | ? { $_.GroupName -eq $_ } | Select -expand ContactID)
        }
        Write-Verbose ("Found Contact Groups " + ($r -join ","))
        return $r
    }

    [Object] GetObjectToPost($tid, $cid)
    {
        $p = 0
        if($this.Paused -eq $true)
        {
            $p = 1
        }

        # mandatories
        $r = @{
            WebsiteName = $this.Name
            WebsiteURL = $this.URL
            CheckRate = $this.CheckRate
            TestType = $this.TestType
            Paused = $p
        }
        
        # optionals
        if($cid -ne $null)
        {
            Write-Verbose "Adding Contact group to post object"
            $r | Add-Member -MemberType NoteProperty -Name ContactGroup -Value ($cid -join ",")
        }
        
        if($tid -ne 0)
        {
            Write-Verbose "Adding a checkID to post object, as we're updating"
            $r | Add-Member -MemberType NoteProperty -Name TestID -Value $tid
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