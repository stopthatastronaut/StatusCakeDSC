# generate checksums pre-commit, add them to our git commit


$hashArray = @()
@(
    "StatusCakeTest.psm1", 
    "StatusCakeDSC.psd1", 
    "StatusCakeDSC.psm1", 
    "StatusCakeContactGroup.psm1") | % {

    $hash = Get-FileHash -Path .\Modules\StatusCakeDSC\$_ -Algorithm SHA256 -verbose

    $hashArray += @{FileName = $_; Hash = ($hash | Select Algorithm, Hash) }


}

$hashArray | ConvertTo-Json | Out-File .\hashes.json -verbose
git add .\hashes.json 

Describe "Full module tests" {
    
}