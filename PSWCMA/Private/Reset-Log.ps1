Function Reset-Log {
            <#
      .Synopsis
      Rotates Log

      .Description
      Rotates a specific log when an estimated size is reached

      .Parameter Path
      Path where the logfile should be created.

      .Parameter Size
      Define a size, when a log should rotate. Size is determined in KB. Default size is 500KB

      .Parameter Count
      Define a count how much log files should be kept. Default Count is 10

      .Outputs
      A new text file or append to a log file
  #>

    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $true)]
        [alias('P')]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [alias('S')]
        [double]$Size = 500,
        [Parameter(Mandatory = $false)]
        [alias('C')]
        [int]$Count = 10
    )

    begin {
        if(!(Test-Path -Path $Path -ErrorAction SilentlyContinue)) {
            break
        }
        $FileProperties = Get-Item -Path $Path
        $FileSize = $FileProperties.Length / 1KB
        $FileParentPath = $FileProperties.DirectoryName
        $FileName = $FileProperties.Name
        $FullName = $FileProperties.FullName
        $InstanceCount = 0
        $LogFiles = New-Object System.Collections.ArrayList
    }
    process {

        if($FileSize -ge $Size) {
            Get-ChildItem -Path $FileParentPath | Where-Object -Property Name -match $FileName | Select-Object -ExpandProperty FullName | ForEach-Object { $InstanceCount++;  [void]$LogFiles.Add($_)}
            $LogFiles | Sort-Object | Out-Null
            if($InstanceCount-1 -eq $Count) {
                Remove-Item -Path $LogFiles.Item($LogFiles.Count-1)
                $LogFiles.RemoveAt($LogFiles.Count-1)
                $InstanceCount--
            }

            
            do {
                [string]$Item = $LogFiles.Item($InstanceCount-1)
                Rename-Item -Path $Item -NewName "$($FullName).$($InstanceCount)"
                $InstanceCount--
            } while ($InstanceCount -gt 0)
            

            New-Item -Path $Path -ItemType File
        }
    }
    end {

    }

}