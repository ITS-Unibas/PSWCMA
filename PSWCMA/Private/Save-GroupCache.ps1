Function Save-GroupCache {
    <#
      .Synopsis
      Saves received groups from AD to a JSON File

      .Description
      Saves received groups from AD to a JSON File

      .Parameter Path
      File Path where the file should be stored. Alias is 'P'.

      .Parameter Data
      File Path where the file should be stored


  #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('P')]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [Alias('D')]
        $Data

    )

    begin {
        #Maybe should be stored as param (thinking...)
        $Filename = 'CachedAdGroups.json'

    }
    process {
        try {
            if (!(Test-Path $Path)) {
                Write-Verbose "$Path is not existing. Will be created"
                New-Item -Path $Path -ItemType Directory | Out-Null
            }

            $Data | ConvertTo-Json | Out-File -FilePath "$Path\$Filename" -Force
            Write-Verbose "File created at $Path\$Filename"
        } catch {
            Write-Error -Message $_.Exception.Message
        }
    }
    end {

    }
}