function Update-FileHash {
    <#
      .Synopsis
      Updates the file hashes for all files which could be applied

      .Description
      Updates the file hashes for all files which could be applied

      .Parameter GroupNames
      Array of the Groupnames which the hash of the underlaying files should be updated

      .Parameter Path
      File Path to the json File

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('g')]
        $GroupNames,
        [Parameter(Mandatory = $true)]
        [Alias('p')]
        [string] $Path
    )

    begin {
        $JsonFile = 'FileHashes.json'
        $Folder = "Configuration"
    }
    process {
        if (Test-Path -Path $Path\$JsonFile) {
            $Hashes = Get-Content -Path $Path\$JsonFile | ConvertFrom-Json
        }
        else {
            $Hashes = @"
            {
                "FileHashes":{

                }
            }
"@
            $Hashes = ConvertFrom-Json $Hashes
        }
        foreach ($GroupName in $GroupNames) {
            $FileName = "$($GroupName.Name).ps1"
            $FileHash = (Get-FileHash -Path "$Path\$Folder\$($GroupName.Name)\$FileName").Hash
            $HashObject = @"
        {
            "File" : "$FileName",
            "Hash" : "$FileHash"
        }
"@
            if ($null -ne ($Hashes.FileHashes | Select-Object -Property $FileName).$FileName) {
                $Hashes.FileHashes | Select-Object -ExpandProperty $FileName | Where-Object {
                     $_.Hash = $FileHash }
            }
            else {
                $Hashes.FileHashes | Add-Member -Name $FileName -Value (ConvertFrom-Json -InputObject $HashObject) -MemberType NoteProperty
            }
        }
        if ($Hashes) {
            $Hashes | ConvertTo-Json | Out-File $Path\$JsonFile -Force
        }
    }
    end {

    }
}