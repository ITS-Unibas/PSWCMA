Function Update-LocalConfigManager {
    <#
      .Synopsis
      Creates and Updates LocalConfigManager

      .Description
      Creates and Updates LocalConfigManager

      .Parameter ConfigCount
      Amount of Configs which should be included

      .Parameter ConfigNames
      The Configuration Names which should be included for Partial Configurations

  #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ConfigCount,
        [Parameter(Mandatory = $true)]
        $ConfigNames,
        [Parameter(Mandatory = $true)]
        $Path
    )
    begin {
        $LCMFolder = "$Path\LCM"
        $LCMFilePath = "$($LCMFolder)\CCM-LCM.ps1"
        New-Item -Path $LCMFilePath -ItemType File -Force
    }
    process {
      try{
        Add-Content -Path $LCMFilePath -Value '[DSCLocalConfigurationManager()]'
        Add-Content -Path $LCMFilePath -Value 'configuration LCMConfig'
        Add-Content -Path $LCMFilePath -Value '{'
        Add-Content -Path $LCMFilePath -Value 'Node localhost'
        Add-Content -Path $LCMFilePath -Value '{'
        Add-Content -Path $LCMFilePath -Value 'Settings'
        Add-Content -Path $LCMFilePath -Value '{'
        Add-Content -Path $LCMFilePath -Value 'ConfigurationModeFrequencyMins = 15'
        Add-Content -Path $LCMFilePath -Value 'ConfigurationMode = "ApplyAndAutoCorrect"'
        Add-Content -Path $LCMFilePath -Value 'RefreshMode = "Push"'
        Add-Content -Path $LCMFilePath -Value 'RebootNodeIfNeeded = $FALSE'
        Add-Content -Path $LCMFilePath -Value 'ActionAfterReboot = "ContinueConfiguration"'
        Add-Content -Path $LCMFilePath -Value 'AllowModuleOverWrite = $FALSE'
        Add-Content -Path $LCMFilePath -Value 'StatusRetentionTimeInDays = "180"'
        Add-Content -Path $LCMFilePath -Value 'RefreshFrequencyMins = "30"'
        Add-Content -Path $LCMFilePath -Value '}'
        if ($ConfigCount -gt 1) {
            foreach ($Config in $ConfigNames) {
                Add-Content -Path $LCMFilePath -Value "PartialConfiguration $($Config.Name)"
                Add-Content -Path $LCMFilePath -Value '{'
                Add-Content -Path $LCMFilePath -Value 'RefreshMode = "Push"'
                Add-Content -Path $LCMFilePath -Value '}'
            }
        }
        Add-Content -Path $LCMFilePath -Value '}'
        Add-Content -Path $LCMFilePath -Value '}'
        Add-Content -Path $LCMFilePath -Value ''
        Add-Content -Path $LCMFilePath -Value "& LCMConfig -OutputPath `"$LCMFolder`""
        #Add-Content -Path $LCMFilePath -value "Set-DscLocalConfigurationManager -Path `"$LCMFolder`" -Force"
        #Add-Content -Path $LCMFilePath -Value "Set-DscLocalConfigurationManager -Path `"$LCMFolder`""
        Invoke-Expression "$LCMFilePath"
        #Actual update of LCM
        Set-DscLocalConfigurationManager -Path $LCMFolder -Force
      } catch {
        Write-Error -Message $_.Exception.Message
      }


    }
    end {

    }

}