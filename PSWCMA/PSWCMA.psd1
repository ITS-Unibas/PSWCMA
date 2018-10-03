#
# Module manifest for module 'PSWCMA'
#
# Generated by: Kevin Schaefer
#
# Generated on: 27.06.2018
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSWCMA.psm1'

# Version number of this module.
ModuleVersion = '0.5.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '72e2d2ab-59fb-45f2-87e7-708c89446b93'

# Author of this module
Author = 'Kevin Schaefer'

# Company or vendor of this module
CompanyName = 'University Basel'

# Copyright statement for this module
Copyright = '(c) 2018 University Basel. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Powershell module for applying DSC Configuration automatically with Git

Target is to get all AD Distribution Groups with a specific prefix, where the client is included. After that a git repository will be cloned/pulled to get the configurations.
Then on the basis of the group names the specific dsc configurations will be applied. The folders in the git repo have to have the same name as the group names.

Features

* Get groups with a specific filter from Active Directory which the client is included
* Caches the groups, so it works also when outside of the company network or AD is just not available
* Get compiled DSCs from a git repository
* Updates LCM if there are several DSCs to use Partial Configurations
* Starts or publish the DSCs
* Installs git if not installed (thanks to https://github.com/tomlarse/Install-Git)
* Configures a task in the scheduler to look up changes and set to the new DSCs

For first use run Initialize-CMAgent to configure AD, Git-Repo, AD-Filter, Baseline Configuration (which always should be triggered) and FilePath for cloning.

'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        #Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
         ProjectUri = 'https://github.com/ITS-Unibas/PSWCMA'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
            * Added key file for secure string so system user can convert it back
        '

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

