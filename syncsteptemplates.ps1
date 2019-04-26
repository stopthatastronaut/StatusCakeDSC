Import-Module OctopusStepTemplateCI

gci .\StepTemplates -filter *.steptemplate.ps1 | % {
    Sync-StepTemplate -Path $_.FullName -Verbose    # Sync-StepTemplate dosn't like relative paths
}
