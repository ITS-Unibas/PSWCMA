Function Save-GroupCache {
    <#
      .Synopsis
      Saves received groups from AD to a JSON File

      .Description
      Saves received groups from AD to a JSON File

      .Parameter Path
      File Path where the file should be stored. Alias is 'P'.

      .Parameter Data
      Data which should be stored in the chache. Alias is 'D'.


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
        $Filename = 'CachedAdGroups.json'

    }
    process {
        try {
            #TO-DO: Should not be needed anymore --> Have to check
            if (!(Test-Path $Path)) {
                Write-Verbose "$Path is not existing. Will be created"
                New-Item -Path $Path -ItemType Directory | Out-Null
            }
            #Converts the received data(groups) in a valid json file
            $Data | ConvertTo-Json | Out-File -FilePath "$Path\$Filename" -Force
            Write-Log -Level INFORMATION -Message "File created at $Path\$Filename"
            Write-Verbose "File created at $Path\$Filename"
        } catch {
            Write-Error -Message $_.Exception.Message
        }
    }
    end {

    }
}