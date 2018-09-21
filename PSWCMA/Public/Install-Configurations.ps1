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
        #TO-DO: Self-Repair function
        if (!$PreReqs.All) {
            Write-Error -Message "This client is not fullfilling all the Prerequisites"
            Write-Debug "Please run Initialize-CMAgent first"
            break
        }
        $ModuleConfig = Get-ItemProperty -Path 'HKLM:\SOFTWARE\PSWCMA' -ErrorAction SilentlyContinue
        if ($null -eq $ModuleConfig) {
            Write-Error "There is no Configuration available"
            Write-Debug "Please run Initialize-CMAgent first"
            break
        }
        $ConfigurationPath = "$($ModuleConfig.FilePath)\Configuration"
        $Groups = [array](Get-ConfigurationGroups -Filter $ModuleConfig.AdFilter -ADServer $ModuleConfig.ActiveDirectory -UserName $ModuleConfig.LDAPUserName -Password $ModuleConfig.LDAPPassword -Path $ModuleConfig.FilePath -Baseline $ModuleConfig.BaseLineConfig)
        if ($null -eq $Groups) {
            Write-Error -Message 'There was an error getting the groups or finding the cache'
        }
    }
    process {
        try {
            #Download all configurations
            if ($null -ne $ModulConfig.TestGroup -and $Groups.Name -contains $ModuleConfig.TestGroup) {
                Get-Configurations -GitServer $ModuleConfig.Git -Path $ModuleConfig.FilePath -Testing -TestBranchName $ModuleConfig.TestBranchName -ErrorAction Stop
                
            }
            else {
                Get-Configurations -GitServer $ModuleConfig.Git -Path $ModuleConfig.FilePath -ErrorAction Stop
            }

            #Exclude Groups which are not on the file system
            $ConfigFolders = Get-ChildItem -Path "$($ModuleConfig.FilePath)\Configuration"
            $Groups = [System.Collections.ArrayList]$Groups
            $IndexToDelete = @()
            foreach($Group in $Groups) {
                if($ConfigFolders.Name -notcontains $Group.Name) {
                    for($i = 0; $i -lt $Groups.Count; $i++) {
                        if($Groups.Item($i).Name -eq $Group.Name) {
                            $IndexToDelete += $i
                        }
                    }
                }
            }
            for($j = 0; $j -lt $IndexToDelete.Count; $j++) {
                $Groups.RemoveAt($j)
                <# if($Groups.Item($i).Name -eq $Group.Name) {
                    $ExclusionIndex = $i
                    $Groups.RemoveAt($ExclusionIndex)
                    break                            
                } #>
                
            }

            #Update LCM
            #TO-DO: Do not always update LCM
            Update-LocalConfigManager -ConfigCount $Groups.Count -ConfigNames $Groups -Path $ModuleConfig.FilePath -ErrorAction Stop
            $HasConfigs = Get-DscConfiguration -ErrorAction SilentlyContinue
            if ($Groups.Count -eq 1) {

                $Group = $Groups[0].Name
                Write-Verbose "Only one Configuration to install. Install from $ConfigurationPath\$Group"
                #Compare Hashes
                if (!(Test-FileHash -GroupName $Group -Path $ModuleConfig.FilePath) -or !$HasConfigs) {
                    #Compile MOF-Files
                    $Compilation = Invoke-ConfigurationCompilation -Path "$ConfigurationPath\$Group\$Group.ps1"
                    if ($Compilation) {
                        #Run actual DSC Job
                        $DSCJob = Start-DscConfiguration -Path $Compilation.DirectoryName -ComputerName localhost -Wait -ErrorAction Stop
                    }
                }
            }
            else {
                Write-Verbose "Going to install $ConfigCount Configurations"
                $PartialHashChanged = $false
                #Check if any partial configuration has changed
                foreach ($Group in $Groups) {
                    if (!(Test-FileHash -GroupName $Group.Name -Path $ModuleConfig.FilePath)) {
                        $PartialHashChanged = $true
                    }
                }
                foreach ($Group in $Groups) {
                    if ($PartialHashChanged -or !$HasConfigs) {
                        #Compile MOF-Files
                        $Compilation = Invoke-ConfigurationCompilation -Path "$ConfigurationPath\$($Group.Name)\$($Group.Name).ps1"
                        if ($Compilation) {
                            #Publishing partial configurations
                            Publish-DscConfiguration -Path $Compilation.DirectoryName -ComputerName localhost -ErrorAction Stop
                        }
                    }
                }
                #Run actual DSC Job
                $DSCJob = Start-DscConfiguration -UseExisting -ComputerName localhost -ErrorAction Stop
            }

            if ($DSCJob) {
                #Wait for the job compilation or exceeded timeout
                #TO-DO: Customizable Timeout
                Wait-Job -Job $DSCJob -Timeout 900
            }
        }
        catch {
            Write-Error -Message $_.Exception.Message
        }
        finally {
            if ($DSCJob) {
                $State = (Get-Job -Id $DSCJob.Id).State
                #Kill job if timeout is exceeded and job is still running
                if ($State -eq 'Running') {
                    Stop-Job -Job $DSCJob
                }
            }
            #Remove pending configurations
            if ((Get-DscLocalConfigurationManager).LCMState -eq 'PendingConfiguration') {
                Remove-DscConfigurationDocument -Stage Pending
            }
            #Update hash
            Update-FileHash -GroupNames $Groups -Path $ModuleConfig.FilePath
        }
    }
    end {
        Write-Verbose "Finished installing Configurations"
    }

}