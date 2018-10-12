Import-Module -Force (Join-Path $PSScriptRoot ..\PSWCMA\PSWCMA.psd1)

InModuleScope "PSWCMA" {
    $TestPath = "TestDrive:\"
    $TestGroup = 'its-ccm-windows-baseline'
    Describe "GroupCache" {
        Context "Reads and saves group chache" {
            $FilePath = "$($TestPath)CachedAdGroups.json"

            $DataObject = New-Object -TypeName psobject -Property @{
                Name = $TestGroup
            }
            $DataObject2 = New-Object -TypeName psobject -Property @{
                Name = "its-ccm-windows-test"
            }

            $Data = New-Object System.Collections.ArrayList
            $Data.Add($DataObject)
            $Data.Add($DataObject2)

            It "creates cache with group" {
                Save-GroupCache -Path $TestPath -Data $DataObject
                Test-Path -Path $FilePath | Should Be $true
            }

            It "reads the group from the cache" {
                (Get-GroupCache -Path $TestPath).Name | Should Be $TestGroup
            }

            It "appends to group cache" {
                Save-GroupCache -Path $TestPath -Data $Data
                (Get-GroupCache -Path $TestPath | Measure-Object).Count | Should BeExactly 2
            }
        }
    }

    Describe "FileHash" {
        $FilePath = "$($TestPath)FileHashes.json"
        $GroupObject = New-Object -TypeName psobject -Property @{
            Name = $TestGroup
        }
        $TestHash = '1E63BE41E7292087BAEAD08862EDD1130B0642731363C4250721CEE45D1ABFCA'
        $Content = @"
{
    "FileHashes":  {
                       "its-ccm-windows-baseline.ps1":  {
                                                            "File":  "$TestGroup.ps1",
                                                            "Hash":  "$TestHash"
                                                        }
                   }
}         
"@
        Context "When it runs the first time" {
            $HashObject = New-Object -TypeName psobject -Property @{
                Hash = $TestHash
            }
            Mock Get-FileHash {return $HashObject }
            
            Update-FileHash -Path $TestPath -GroupNames $GroupObject
            It "should create a new file" {
                Test-Path $FilePath | Should Be $true
            }

            It "should save the hash and name" {
                Get-Content -Path $FilePath | ConvertFrom-Json | Select-Object -ExpandProperty FileHashes | 
                    Select-Object -ExpandProperty its-ccm-windows-baseline.ps1 | Select-Object -ExpandProperty Hash |
                    Should Be $TestHash
            }
        }

        Context "When there is an update" {
            
            $HashObject = New-Object -TypeName psobject -Property @{
                Hash = '1E63BE41E7292087BAEAD08862EDD1130B0642731363C4250721CEE45D1ABFC8'
            }
            Mock Get-FileHash {return $HashObject}
            Set-Content -Path $FilePath -Value $Content

            It "check old hash" {
                Get-Content -Path $FilePath | ConvertFrom-Json | Select-Object -ExpandProperty FileHashes | 
                    Select-Object -ExpandProperty its-ccm-windows-baseline.ps1 | Select-Object -ExpandProperty Hash |
                    Should Be $TestHash
            }
            
            It "should be update" {
                Test-FileHash -GroupName $TestGroup -Path $TestPath | Should Be $false
            }

            It "is updated" {
                Update-FileHash -Path $TestPath -GroupNames $GroupObject
                Get-Content -Path $FilePath | ConvertFrom-Json | Select-Object -ExpandProperty FileHashes | 
                    Select-Object -ExpandProperty its-ccm-windows-baseline.ps1 | Select-Object -ExpandProperty Hash |
                    Should Not Be $TestHash
            }

        }

        Context "When there is no update neded" {
            $HashObject = New-Object -TypeName psobject -Property @{
                Hash = $TestHash
            }
            Set-Content -Path $FilePath -Value $Content
            Mock Get-FileHash {return $HashObject}
            It "no updated needed" {
                Test-FileHash -GroupName $TestGroup -Path $TestPath | Should Be $true
            }
        }
    }

    Describe "LocalConfigManager" {
        $FilePath = "$TestPath\LCM\CCM-LCM.ps1"
        $FilePathMof = "$TestPath\LCM\localhost.meta.mof"

        Context "When there is only one configuration" {
            $DataObject = New-Object -TypeName psobject -Property @{
                Name = $TestGroup
            }
            Update-LocalConfigManager -ConfigCount 1 -ConfigNames $DataObject -Path $TestPath
            It "create file" {
                Test-Path -Path $FilePath | Should Be $true
            }

            It "compiled lcm configuration" {
                Test-Path -Path $FilePathMof | Should Be $true
            }
            $Lcm = Get-DscLocalConfigurationManager
            It "update lcm" {
                
                $Lcm.ConfigurationModeFrequencyMins -eq 15 -and $Lcm.ConfigurationMode -eq 'ApplyAndAutoCorrect' `
                    -and $Lcm.RefreshMode -eq 'Push' -and $Lcm.RebootNodeIfNeeded -eq $false -and $Lcm.ActionAfterReboot -eq 'ContinueConfiguration' `
                    -and $Lcm.AllowModuleOverwrite -eq $false -and $Lcm.StatusRetentionTimeInDays -eq '180' `
                    -and $Lcm.RefreshFrequencyMins -eq '30' | Should Be $true
            }

            It "should be no partial config block" {
                $null -eq $Lcm.PartialConfigurations | Should Be $true
            }
        }

        Context "When there are several configuration" {
            $DataObject = New-Object -TypeName psobject -Property @{
                Name = $TestGroup
            }
            $DataObject2 = New-Object -TypeName psobject -Property @{
                Name = "its-ccm-windows-test"
            }

            $Data = New-Object System.Collections.ArrayList
            $Data.Add($DataObject)
            $Data.Add($DataObject2)
            Update-LocalConfigManager -ConfigCount 2 -ConfigNames $Data -Path $TestPath
            It "create file" {
                Test-Path -Path $FilePath | Should Be $true
            }

            It "compiled lcm configuration" {
                Test-Path -Path $FilePathMof | Should Be $true
            }
            $Lcm = Get-DscLocalConfigurationManager
            It "update lcm" {
                 
                $Lcm.ConfigurationModeFrequencyMins -eq 15 -and $Lcm.ConfigurationMode -eq 'ApplyAndAutoCorrect' `
                    -and $Lcm.RefreshMode -eq 'Push' -and $Lcm.RebootNodeIfNeeded -eq $false -and $Lcm.ActionAfterReboot -eq 'ContinueConfiguration' `
                    -and $Lcm.AllowModuleOverwrite -eq $false -and $Lcm.StatusRetentionTimeInDays -eq '180' `
                    -and $Lcm.RefreshFrequencyMins -eq '30' | Should Be $true
            }

            It "should be partial config" {
                $null -ne $Lcm.PartialConfigurations | Should be $true
            }

            It "should be right configurations" {
                $Lcm.PartialConfigurations.ResourceId -contains "[PartialConfiguration]its-ccm-windows-baseline" `
                    -and $Lcm.PartialConfigurations.ResourceId -contains "[PartialConfiguration]its-ccm-windows-test"
            }
        }
    }

    Describe "AgentConfiguration" {
        Context "Initialize the agent" {
            AfterEach {
                $RegPath = 'HKLM:\SOFTWARE\PSWCMA'
                $RegPathAppwiz = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PSWCMA'
                Unregister-ScheduledTask -TaskName 'Configuration Management Agent' -Confirm:$false -ErrorAction SilentlyContinue
                Remove-Item -Recurse $RegPath -Force -ErrorAction SilentlyContinue
                Remove-Item -Recurse -Path $RegPathAppwiz -Force -ErrorAction SilentlyContinue

            }

            It "should be initialized" {
                Initialize-CMAgent -Path "$($TestPath)CCM" -Git "https://github.com/git.git" -ActiveDirectory "AD.AD.com" -LDAPUserName "domain\user" -LDAPPassword "password" -Filter "ccm-windows*" -Baseline $TestGroup
                Get-ScheduledTask -TaskName "Configuration Management Agent" -ErrorAction SilentlyContinue | Should Not Be $null
                $ModuleConfig = Get-ItemProperty -Path 'HKLM:\SOFTWARE\PSWCMA'
                $ModuleConfig.FilePath | Should BeExactly "$($TestPath)CCM"
                $ModuleConfig.ActiveDirectory | Should BeExactly "AD.AD.com"
                $ModuleConfig.LDAPUserName | Should BeExactly "domain\user"
                $ModuleConfig.LDAPPassword | Should Not Be "password"
                $ModuleConfig.AdFilter | Should BeExactly "ccm-windows*"
                $ModuleConfig.BaseLineConfig | Should BeExactly $TestGroup
                $ModuleConfig.Git | Should BeExactly "https://github.com/git.git"
                
                Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PSWCMA' | Should Not Be $null
            }
        }

        Context "Uninstall agent's components" {
            BeforeEach {
                Initialize-CMAgent -Path "$($TestPath)CCM" -Git "https://github.com/git.git" -ActiveDirectory "AD.AD.com" -LDAPUserName "domain\user" -LDAPPassword "password" -Filter "ccm-windows*" -Baseline $TestGroup
            }

            It "should be unconfigured" {
                Uninstall-CMAgent
                Get-ScheduledTask -TaskName "Configuration Management Agent" -ErrorAction SilentlyContinue | Should Be $null
                Get-Item -Path 'HKLM:\SOFTWARE\PSWCMA' -ErrorAction SilentlyContinue | Should Be $null                
                Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PSWCMA' -ErrorAction SilentlyContinue | Should Be $null
            }
        }
    }

    Describe "Logfiles" {
        $FilePath = (Join-Path -Path $TestPath -ChildPath 'pswcma.log')
        Context "Write in logfile" {
            
            It "log file should be created"{
                Write-Log -Path $TestPath -Message 'This is a test message'
                Test-Path -Path $FilePath | Should be $true
            }

            It "log level without param should be 'INFORMATION'"{
                Write-Log -Path $TestPath -Message 'This is a test message'
                $Content = Get-Content -Path $FilePath -Tail 1
                $Content -match 'INFORMATION' | Should Be $true
            }

            It "log level INFORMATION"{
                Write-Log -Path $TestPath -Level INFORMATION -Message 'This is a test message'
                $Content = Get-Content -Path $FilePath -Tail 1
                $Content -match 'INFORMATION' | Should Be $true
            }

            It "log level ERROR"{
                Write-Log -Path $TestPath -Level ERROR -Message 'This is a test message'
                $Content = Get-Content -Path $FilePath -Tail 1
                $Content -match 'ERROR' | Should Be $true
            }

            It "log level WARNING"{
                Write-Log -Path $TestPath -Level WARNING -Message 'This is a test message'
                $Content = Get-Content -Path $FilePath -Tail 1
                $Content -match 'WARNING' | Should Be $true
            }

            It "log level VERBOSE"{
                Write-Log -Path $TestPath -Level VERBOSE -Message 'This is a test message'
                $Content = Get-Content -Path $FilePath -Tail 1
                $Content -match 'VERBOSE' | Should Be $true
            }

            It "log level DEBUG"{
                Write-Log -Path $TestPath -Level DEBUG -Message 'This is a test message'
                $Content = Get-Content -Path $FilePath -Tail 1
                $Content -match 'DEBUG' | Should Be $true
            }

        }

        Context "log rotate" {
            it "rotate a log" {
                New-Item -Path $FilePath -Force
                Add-Content -Path $FilePath "testetesetset"
                Add-Content -Path $FilePath "testetesetset"
                New-Item -Path "$($FilePath).1" -Force
                New-Item -Path "$($FilePath).2" -Force
                $FilePath = Get-Item $FilePath | Select-Object -ExpandProperty FullName
                $TimeStampBefore = Get-Item -Path $FilePath | Select-Object -ExpandProperty LastWriteTime
                Reset-Log -Path $FilePath -Count 2 -Size 0.00001
                $TimeStampAfter = Get-Item -Path $FilePath | Select-Object -ExpandProperty LastWriteTime
                $TimeStampBefore -ne $TimeStampAfter | Should Be $true
            }
        }
    }
}
