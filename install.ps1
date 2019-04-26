# Install method is now obsolete

Function Invoke-UTF8WebRequest
{
    # based loosely on https://gist.github.com/angel-vladov/9482676
    param($uri)
    [Net.HttpWebRequest]$req = [Net.WebRequest]::Create($Uri)
    [Net.HttpWebResponse]$res = $req.GetResponse()
    $sr = [IO.StreamReader]::new($res.GetResponseStream())
    $body = $sr.ReadToEnd()
    $sr.Close()
    return [pscustomobject]@{
        Content = $body;
        StatusCode = $res.StatusCode;
        Headers = $res.Headers;
        StatusDescription = $res.StatusDescription;
    }
}

$targetpath = "C:\program Files\WindowsPowerShell\Modules\StatusCakeDSC"
$rawfilehost = "https://raw.githubusercontent.com/stopthatastronaut/StatusCakeDSC/master/"

if(!(Test-Path $targetpath))
{
    New-item -Path $targetPath -Type Directory -Force -Verbose
}
else
{
    # first, check if we need to install it at all by comparing hashes
    $hashfile = Invoke-UTF8WebRequest -uri ($rawfilehost, "hashes.json" -join "") | Select-Object -expand Content
    $hashobject = $hashfile | ConvertFrom-Json

    $hashobject | ForEach-Object {
        $needsupdating = $false # assume it doesn't need updating
        $targetfile = ($targetpath, $_.FileName -join "\")
        if(Test-Path $targetfile)
        {
            # file exists. check hash
            $localhash = Get-FileHash $targetfile -Algorithm SHA256 | Select-Object -expand Hash
            if($localhash -ne $_.Hash.Hash)
            {
                $needsupdating = $true
            }
        }
        else
        {
            # file doesn't exist
            $ needsupdating = $true
        }

        if($needsupdating)
        {
            Invoke-UTF8WebRequest -uri ("$rawfilehost", $_.FileName -join "") | Select-Object -expand Content | Out-File ($targetpath, $_.FileName -join "\") -verbose
        }
    }
}

<# old method
@(
    "StatusCakeDSC.psd1",
    "StatusCakeDSC.psm1",
    "StatusCakeTest.psm1",
    "StatusCakeContactGroup.pms1"
) | % {
    Invoke-UTF8WebRequest -uri ("$rawfilehost", $_ -join "") | select -expand Content | Out-File ($targetpath, $_ -join "\") -verbose
}
#>
