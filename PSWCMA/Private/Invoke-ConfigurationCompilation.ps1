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
            Write-Log -Level WARNING -Message "The Path is invalid"
            break
        }
        #Fetch filename 
        $FileName = Get-ChildItem -Path $Path | Select-Object -ExpandProperty Name
        Write-Verbose "Beginning to compile $FileName"
        Write-Log -Level INFORMATION -Message "Beginning to compile $FileName"
      } 
      process {
        #Execute configuration to compile it 
        $Result = Invoke-Expression $Path
        Write-Verbose "$Result"
      }
      end {
        Write-Log -Level INFORMATION -Message "Finished compiling the configuration"
        Write-Verbose "Finished compiling the configuration"
        return $Result
      }
}