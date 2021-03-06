﻿Function Get-Configurations {
    <#
      .Synopsis
      Downloads Configurations from your Git Repo

      .Description
      Downloads Configurations from your Git Repo

      .Parameter GitServer
      Url to the git repository where the configurations are located

      .Parameter Path
      Filepath where the git repository should be checked out

      .Parameter Testing
      Switch Parameter to signalize test machine

      .Parameter TestBranchName
      Branch name for the testing branch

      #>

    [CmdletBinding()]
    param(
        <#[Parameter(Mandatory = $true)]
        $ConfigurationNames,#>
        [Parameter(Mandatory = $true)]
        $GitServer,
        [Parameter(Mandatory = $true)]
        $Path,
        [Parameter()]
        [switch]$Testing,
        [Parameter()]
        $TestBranchName
    )
    begin {
        $CloneDirectory = "$Path\Configuration"
        #$Counter = 0
        $SiteAvail = Invoke-WebRequest $GitServer -DisableKeepAlive -UseBasicParsing -Method head -ErrorAction SilentlyContinue
    }
    process {
        if ($SiteAvail) {
            if(Test-Path -Path $CloneDirectory) {
                Write-Log -Message "First time fetching from git $GitServer, going to clone into directory $CloneDirectory"
                Start-Process "git" -ArgumentList "-C $CloneDirectory pull" -Wait
            } else {
                Write-Log -Message "Pulling from git $GitServer"
                Start-Process "git" -ArgumentList "clone $GitServer $CloneDirectory" -Wait
            }

            if($Testing) {
                Write-Log -Message "Device is is a tester, going to checkout testing branch"
                Start-Process "git" -ArgumentList "-C $CloneDirectory pull origin $TestBranchName" -Wait
                Start-Process "git" -ArgumentList "-C $CloneDirectory checkout $TestBranchName"
            }
        } else {
            Write-Log -Level ERROR -Message "Git Repository is not available"
        }

    }
    end {
        #return $Counter
    }

}