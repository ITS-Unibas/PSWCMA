function Test-FileHash {
    <#
      .Synopsis
      Checks if a file is updated and needs to be published

      .Description
      Checks if a file is updated and needs to be published

      .Parameter GroupName
      Groupname which the hash of the underlaying files should be read

      .Parameter Path
      File Path to the json File

      .Outputs
      Returns false if hash is outdated and true if hashes are the same

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('g')]
        $GroupName,
        [Parameter(Mandatory = $true)]
        [Alias('p')]
        [string] $Path
    )
    begin {
        $JsonFile = 'FileHashes.json'
        $PathJson = "$Path\$JsonFile"
    }
    process {
        if (Test-Path -Path $Path\$JsonFile) {
            $Hashes = Get-Content -Path $PathJson | ConvertFrom-Json
            $FileName = "$GroupName.ps1"
            $CurrentHash = (Get-FileHash -Path "$Path\Configuration\$GroupName\$FileName").Hash
            $ChachedHash = $Hashes.FileHashes | Select-Object -ExpandProperty $FileName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Hash -ErrorAction SilentlyContinue
            if($null -ne $ChachedHash -and $CurrentHash -eq $ChachedHash) {
                return $true
            }
        }
        return $false
    }
    end{

    }
}