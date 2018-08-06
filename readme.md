# PSWCMA - PowerShell Windows Conifguration Management Agent
## Introduction
Powershell module for applying DSC configurations automatically with Git

The target is to fetch all Active Directory distribution groups with a specific prefix fromt the current client. 
If a connection could be established to the AD the agent writes all found groups in a cache file, which is written in json. If not, the client will read the cache. 
If there wasn't any connection yet and the AD is offline, it will only get the baseline config, if there is one configured.
After the fetching of the distribution group, the agent clones or pull the configurations from a git repository. Then on the basis of the group names the specific dsc configurations will be applied.

The agent will run periodically (implemented with task scheduler from windows).

*Important*: The folders in the git repo have to have the same name as the group names. 

## Requirements
- WMF 5.0
- Active Directory 
- Git Repository
    - Repository has to be public

## Getting started
### Install PSWCMA using PowerShell Gallery
The module can be installed with the PowerShell Gallery: https://www.powershellgallery.com
The install command is:
```
Install-Module -Name PSWCMA
```
### Installing PSWCMA using git
Or it can be cloned with git:
```
git clone git@github.com:ITS-Unibas/PSWCMA.git
```
But when cloned with git, the repository must be cloned or at least copied in one of the defrootault module directories. To get the module directories:
```
$ENV:PSModulePath -split ';'
```

### Configure the agent
The agent will be configured with `Initialize-CMAgent`. Basic example:
```
Initialize-CMAgent -Path "C:\path\to\a\desiredfolder" -Git "https://git-server/yourgitrepo.git" -ActiveDirectory "FQDN.OF.DOMAIN" -Filter "Prefix-Of-DistributionGroups*" -Basline "Name-of-your-baseline-config"
```

This will install the prequisits and configure the task scheduler.

### Run installing configuration command
You can also trigger the installation of the configuration manually by running:
```
Install-Configurations
```

## Remove the PSWCMA
To remove the components of the PSWCMA run:
```
Uninstall-CMAgent
```
This command only removes the parts, which were created while the initialization of the PSWCMA. To remove the module itself run:
```
Uninstall-Module -Name "PSWCMA"
```