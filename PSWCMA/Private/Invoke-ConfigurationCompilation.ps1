Function Invoke-ConfigurationCompilation {
     <#
      .Synopsis
      Installs all needed configurations

      .Description
      Installs all needed configurations

      .Parameter Path
      The absolut path to the configuration's ps1 file

      #>

      [CmdletBinding()]
      param (
        [Parameter(Mandatory=$true)]
        [Alias('p')]
        [string] $Path
      )

      begin{
        if(!(Test-Path -Path $Path)) {
            Write-Verbose "The path is invalid"
            break
        }
        $FileName = Get-ChildItem -Path $Path | Select-Object -ExpandProperty Name
        Write-Verbose "Beginning to compile $FileName"
      } 
      process {
        $Result = Invoke-Expression $Path
        Write-Verbose "$Result"
      }
      end {
        return $Result
        Write-Verbose "Finished compiling the configuration"
      }
}