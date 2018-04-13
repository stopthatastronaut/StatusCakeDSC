﻿#
# Module manifest for module 'StatusCakeDSC'
# Generated by: jasbro
# Generated on: 7/05/2017
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'StatusCakeDSC'

# Version number of this module.
ModuleVersion = '2.2.1'

# ID used to uniquely identify this module
GUID = '14c4f055-b47b-4ea8-a8d8-86aec7ad737c'

# Author of this module
Author = 'Jason Brown'

# Company or vendor of this module
CompanyName = 'https://github.com/stopthatastronaut'

# Copyright statement for this module
Copyright = '(c) 2017, 2018 Jason Brown (and contributors)'

# Description of the functionality provided by this module
Description = 'Provisions and manages checks and resources on statuscake.com'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('StatusCakeSSL.psm1', 'StatusCakeTest.psm1', 'StatusCakeContactGroup.psm1')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
DscResourcesToExport = @('StatusCakeSSL', 'StatusCakeTest', 'StatusCakeContactGroup')

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/stopthatastronaut/StatusCakeDSC'

}
