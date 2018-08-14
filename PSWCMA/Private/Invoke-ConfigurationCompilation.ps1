Function Invoke-ConfigurationCompilation {
     <#
      .Synopsis
      Installs all needed configurations

      .Description
      Installs all needed configurations

      .Parameter Path
      The absolut path to the configuration's ps1 file. Alias is 'P'

      #>

      [CmdletBinding()]
      param (
        [Parameter(Mandatory=$true)]
        [Alias('P')]
        [string] $Path
      )

      begin{
        if(!(Test-Path -Path $Path)) {
            Write-Verbose "The path is invalid"
            break
        }
        #Fetch filename 
        $FileName = Get-ChildItem -Path $Path | Select-Object -ExpandProperty Name
        Write-Verbose "Beginning to compile $FileName"
      } 
      process {
        #Execute configuration to compile it 
        $Result = Invoke-Expression $Path
        Write-Verbose "$Result"
      }
      end {
        return $Result
        Write-Verbose "Finished compiling the configuration"
      }
}