function Test-FileHash {
    <#
      .Synopsis
      Checks if a file is updated and needs to be published

      .Description
      Checks if a file is updated and needs to be published

      .Parameter GroupName
      Groupname which the hash of the underlaying files should be read. Alis is 'G'.

      .Parameter Path
      File Path to the json File. Alias is 'P'.

      .Outputs
      Returns false if hash is outdated and true if hashes are the same

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('G')]
        $GroupName,
        [Parameter(Mandatory = $true)]
        [Alias('P')]
        [string] $Path
    )
    begin {
        $JsonFile = 'FileHashes.json'
        $PathJson = "$Path\$JsonFile"
    }
    process {
        if (Test-Path -Path $Path\$JsonFile) {
            #Read from file hashes
            $Hashes = Get-Content -Path $PathJson | ConvertFrom-Json
            $FileName = "$GroupName.ps1"

            #Get hash from the current saved file
            $CurrentHash = (Get-FileHash -Path "$Path\Configuration\$GroupName\$FileName").Hash

            #Read cached hash
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