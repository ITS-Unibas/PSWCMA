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
        #delete scheduled task: above Windows 7 - for Windows 7 compatibility reasons the task will deleted with Schedule.Service COM object
        #Unregister-ScheduledTask -TaskName 'Configuration Management Agent' -Confirm:$false -ErrorAction SilentlyContinue

        #delete scheduled task with Schedule.Service COM object
        $TaskName = 'Configuration Management Agent'          
        $Service = New-Object -ComObject("Schedule.Service")
        $Service.Connect()
        $RootFolder = $Service.GetFolder("\")
        $RootFolder.DeleteTask($TaskName, 0)

        if($FilePath) {
            #remove all files
            Remove-Item -Recurse -Path $FilePath -Force -ErrorAction SilentlyContinue
        }
        #remove all registry items
        Remove-Item -Recurse $RegPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Path $RegPathAppwiz -Force -ErrorAction SilentlyContinue
      }
      end {
        Write-Verbose "Finished uninstalling PSWCMA"
      }
}