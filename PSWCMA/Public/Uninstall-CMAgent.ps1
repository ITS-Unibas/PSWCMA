Function Uninstall-CMAgent {
    <#
      .Synopsis
      Uninstalls all the components of this Agent

      .Description
      Uninstalls all the components of this Agent. Be aware the module itself has to be removed manually

      #>

      [CmdletBinding()]
      param (

      )

      begin {
        Write-Verbose "Going to uninstall PSWCMA"
        $RegPath = 'HKLM:\SOFTWARE\PSWCMA'
        $RegPathAppwiz = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PSWCMA'
        $FilePath = Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FilePath
      }
      process {
        Unregister-ScheduledTask -TaskName 'Configuration Management Agent' -Confirm:$false -ErrorAction SilentlyContinue
        if($FilePath) {
            Remove-Item -Recurse -Path $FilePath -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -Recurse $RegPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Path $RegPathAppwiz -Force -ErrorAction SilentlyContinue
      }
      end {
        Write-Verbose "Finished uninstalling PSWCMA"
      }
}