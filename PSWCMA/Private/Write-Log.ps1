Function Write-Log {
        <#
      .Synopsis
      Used to create and write a log

      .Description
      Writes a log with different log level

      .Parameter Message
      Define your custom message which should be written into the logfile.

      .Parameter Level
      Define the level of the log message. Values are 'ERROR', 'WARNING', 'INFORMATION', 'DEBUG', 'VERBOSE'. Default level is 'INFORMATION'

      .Parameter Path
      Path where the logfile should be created.

      .Outputs
      A new text file or append to a log file
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [alias('M')]
    [string]$Message,
    [Parameter(Mandatory = $false)]
    [ValidateSet('ERROR', 'WARNING', 'INFORMATION', 'DEBUG', 'VERBOSE')]
    [alias('L')]
    [string]$Level = 'INFORMATION',
    [Parameter(Mandatory = $true)]
    [alias('P')]
    [string]$Path
  )

  begin  {
      $FileName = "pswcma.log"
      $LogPath = Join-Path -Path $Path -ChildPath $FileName
      $TimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.ff'
  }
  process {
    if(!(Test-Path -Path $LogPath -ErrorAction SilentlyContinue)) {
        New-Item -Path $LogPath -ItemType File -Force -ErrorAction Stop
    }

    $LogLine = ("{0} `t [{1}] `t {2}" -f $TimeStamp, $Level, $Message)
    Add-Content -Path $LogPath -Value $LogLine
  }
  end {
    Write-Verbose "$LogLine was added to $LogPath"
  }
}