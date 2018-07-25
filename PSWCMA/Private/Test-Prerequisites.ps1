Function Test-Prerequisites {
    <#
      .Synopsis
      Tests if all prerequisites for the module to work are installed

      .Description
      Tests if all prerequisites for the module to work are installed

      .Outputs
      PSObject. Test-prequisites returns a PSObject with three bool values Git, Win10 and All.


  #>
    [CmdletBinding()]
    param()

    begin {
        $WindowsVer = [System.Environment]::OSVersion.Version
        $Git = Get-Command -Name git -ErrorAction SilentlyContinue
        $WinRM = Test-WSMan -ErrorAction SilentlyContinue
        $XPSDSC = Get-DscResource -Module 'xPSDesiredStateConfiguration' | Select-Object -First 1
        $CFW = Get-DscResource -Module 'cFirewall' | Select-Object -First 1


    }
    process {
        $Prereq = New-Object -TypeName psobject -Property @{
            All    = $false
            Git    = $null -ne $Git
            Win10  = $WindowsVer.Major -eq 10
            WinRM  = $null -ne $WinRM
            XPSDSC = $null -ne $XPSDSC
            CFW    = $null -ne $CFW

        }

        if ($Prereq.Git -and $Prereq.CFW -and $Prereq.Win10 -and $Prereq.WinRM -and $Prereq.XPSDSC) {
            $Prereq.All = $true
        }
    }
    end {
        return $Prereq
    }

}