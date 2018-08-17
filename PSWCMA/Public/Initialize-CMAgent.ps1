Function Initialize-CMAgent {
    <#
      .Synopsis
      Configures the Agent on the Client with all needed Dependencies

      .Description
      Configures the Agent on the Client with all needed Dependencies

      .Parameter Path
      Filepath for the working directory for this agent. Alias is 'P'.

      .Parameter Git
      Give the link to your Git Repository. Repo must be public to allow anonymous access. Alias is 'G'.

      .Parameter ActiveDirectory
      FQDN for your Active Directory. Alias is 'AD'.

      .Parameter Filter
      The AD Filter for the group prefix which should be searched. Alias is 'F'.

      .Parameter Baseline
      The baseline configuration which always shoudld be applied. Only exists in git. Alias is 'B'.

      .Parameter TestGroup
      If this Group is set and the client is found in this group, the testing branch will be checked out. Alias is 'T'.

      .Parameter TestBranchName
      Define the name of the testing branch in git. Alias is 'TB'.

      

      .Example
      Initialize-CMAgent -Path "C:\ProgramData\Unibasel\CCM" -Git "https://github.com/your-repo.git" -ActiveDirectory "Your.ActiveDirectory.com" -Filter "prefix-ccm*" -Baseline "prefix-ccm-baseline"

  #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('P')]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [Alias('G')]
        [string]$Git,
        [Parameter(Mandatory = $true)]
        [Alias('AD')]
        [string]$ActiveDirectory,
        [Parameter(Mandatory = $true)]
        [Alias('F')]
        [string]$Filter,
        [Parameter(Mandatory = $true)]
        [Alias('B')]
        [string]$Baseline,
        [Parameter(ParameterSetName = 'Testing')]
        [Alias('T')]
        [String]$TestGroup,
        [Parameter(ParameterSetName = 'Testing')]
        [Alias('TB')]
        [String]$TestBranchName


    )
    begin {
        $PreReq = Test-Prerequisites
        $RegPath = 'HKLM:\SOFTWARE\PSWCMA'
        $RegPathAppwiz = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PSWCMA'
        $ModuleVersion = Get-InstalledModule -Name "PSWCMA" | Select-Object -ExpandProperty Version
    }
    process {
        #Write Configuration Cache
        New-Item -Path $RegPath -Force
        New-ItemProperty -Path $RegPath -Name 'FilePath' -Value $Path -PropertyType String -Force
        New-ItemProperty -Path $RegPath -Name 'Git' -Value $Git -PropertyType String -Force
        New-ItemProperty -Path $RegPath -Name 'ActiveDirectory' -Value $ActiveDirectory -PropertyType String -Force
        New-ItemProperty -Path $RegPath -Name 'AdFilter' -Value $Filter -PropertyType String -Force
        New-ItemProperty -Path $RegPath -Name 'BaseLineConfig' -Value $Baseline -PropertyType String -Force
        New-ItemProperty -Path $RegPath -Name 'TestGroup' -Value $TestGroup -PropertyType String -Force
        New-ItemProperty -Path $RegPath -Name 'TestBranchName' -Value $TestBranchName -PropertyType String -Force


        #Write appwiz data
        New-Item -Path $RegPathAppwiz -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'Comments' -Value 'PowerShell Windows Configuration Management Agent' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'Contact' -Value 'University of Basel - ITS' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'DisplayVersion' -Value "$ModuleVersion" -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'NoModify' -Value '1' -PropertyType DWORD -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'NoRemove' -Value '1' -PropertyType DWORD -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'Publisher' -Value 'University of Basel - ITS' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'SystemComponent' -Value '0' -PropertyType DWORD -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'URLInfoAbout' -Value 'www.unibas.ch' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'DisplayName' -Value 'PSWCMA' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'InstallLocation' -Value 'C:\Program Files\WindowsPowerShell\Modules\PSWCMA' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'UninstallString' -Value '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -WindowStyle Hidden -command "& {Import-Module PSWCMA; Uninstall-CMAgent}"' -PropertyType String -Force
        New-ItemProperty -Path $RegPathAppwiz -Name 'DisplayIcon' -Value '%SystemRoot%\System32\SHELL32.dll,238' -PropertyType ExpandString -Force

        #Install Pre-Reqs
        if (!$PreReq.WMF) {
            Write-Error 'WMFVersion is lower than 5'
            break
        }
        if (!$PreReq.Git) {
            Install-Git
        }
        if (!$PreReq.WinRM) {
            $NetProfile = Get-NetConnectionProfile
            if ($NetProfile.NetworkCategory -eq 'Public') {
                Set-NetConnectionProfile -InterfaceIndex $NetProfile.InterfaceIndex -NetworkCategory Private
            }
            Set-WSManQuickConfig -Force
        }

        if (!(Test-Prerequisites).All) {
            Write-Error 'There was an error installing the Prequisites'
            break
        }

        try {
            #Configure Scheduler
            $Random = Get-Random -Maximum 15
            $SchedulerAction = New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -WindowStyle Hidden -command "& {Import-Module PSWCMA; Install-Configurations}"'
            $SchedulerTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RandomDelay (New-TimeSpan -Minutes $Random)
            $SchedulerSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1)
            Register-ScheduledTask -User System -TaskName 'Configuration Management Agent' -Action $SchedulerAction -Trigger $SchedulerTrigger -Settings $SchedulerSettings -Force
        }
        catch {
            Write-Error -Message $_.Exception.Message
            Write-Debug "There was an error creating the scheduled task. Please try again"
        }

    }
    end {

    }

}