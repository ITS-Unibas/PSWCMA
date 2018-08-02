Function Install-Configurations {
    <#
      .Synopsis
      Installs all needed configurations

      .Description
      Installs all needed configurations



      #>

    [CmdletBinding()]
    param()
    begin {
        $PreReqs = Test-Prerequisites
        if (!$PreReqs.All) {
            Write-Error -Message "This client is not fullfilling all the Prerequisites"
            Write-Debug "Please run Initialize-CMAgent first"
            break
        }
        $ModuleConfig = Get-ItemProperty -Path 'HKLM:\SOFTWARE\PSWCMA' -ErrorAction SilentlyContinue
        if ($null -eq $ModuleConfig) {
            Write-Error "There is no Configuration available"¨
            Write-Debug "Please run Initialize-CMAgent first"
            break
        }
        $ConfigurationPath = "$($ModuleConfig.FilePath)\Configuration"
        $Groups = [array](Get-ConfigurationGroups -Filter $ModuleConfig.AdFilter -ADServer $ModuleConfig.ActiveDirectory -Path $ModuleConfig.FilePath -Baseline $ModuleConfig.BaseLineConfig)
        if ($null -eq $Groups) {
            Write-Error -Message 'There was an error getting the groups or finding the cache'
        }
    }
    process {
        try {
            Get-Configurations -GitServer $ModuleConfig.Git -Path $ModuleConfig.FilePath -ErrorAction Stop

            Update-LocalConfigManager -ConfigCount $Groups.Count -ConfigNames $Groups -Path $ModuleConfig.FilePath -ErrorAction Stop
            if ($Groups.Count -eq 1) {

                $Group = $Groups[0].Name
                Write-Verbose "Only one Configuration to install. Install from $ConfigurationPath\$Group"
                if (!(Test-FileHash -GroupName $Group -Path $ModuleConfig.FilePath)) {
                    $Compilation = Invoke-ConfigurationCompilation -Path "$ConfigurationPath\$Group\$Group.ps1"
                    if ($Compilation) {
                        $DSCJob = Start-DscConfiguration -Path $Compilation.DirectoryName -ComputerName localhost -Wait -ErrorAction Stop
                    }
                }
            }
            else {
                Write-Verbose "Going to install $ConfigCount Configurations"
                foreach ($Group in $Groups) {
                    if (!(Test-FileHash -GroupName $Group -Path $ModuleConfig.FilePath)) {
                        $Compilation = Invoke-ConfigurationCompilation -Path "$ConfigurationPath\$Group\$Group.ps1"
                        if ($Compilation) {
                            Publish-DscConfiguration -Path $Compilation.DirectoryName -ComputerName localhost -ErrorAction Stop
                        }
                    }
                }
                $DSCJob = Start-DscConfiguration -UseExisting -ComputerName localhost -Wait -ErrorAction Stop
            }

            if ($DSCJob) {
                Wait-Job -Job $DSCJob -Timeout 900
            }
        }
        catch {
            Write-Error -Message $_.Exception.Message
        }
        finally {
            if ($DSCJob) {
                $State = (Get-Job -Id $DSCJob.Id).State
                if ($State -eq 'Running') {
                    Stop-Job -Job $DSCJob
                }
                elseif ($State -eq 'Failed') {
                    Remove-DscConfigurationDocument -Stage Pending
                }
            }
            else {
                if ((Get-DscLocalConfigurationManager).LCMState -eq 'PendingConfiguration') {
                    Remove-DscConfigurationDocument -Stage Pending
                }
            }
            Update-FileHash -GroupNames $Groups -Path $ModuleConfig.FilePath
        }
    }
    end {
        Write-Verbose "Finished installing Configurations"
    }

}