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
        $WMFVer = $PSVersionTable.PSVersion.Major
        $Git = Get-Command -Name git -ErrorAction SilentlyContinue
        $WinRM = Test-WSMan -ErrorAction SilentlyContinue


    }
    process {
        $Prereq = New-Object -TypeName psobject -Property @{
            All    = $false
            Git    = $null -ne $Git
            WMF  = $WMFVer -ge 5
            WinRM  = $null -ne $WinRM

        }

        if ($Prereq.Git -and $Prereq.WMF -and $Prereq.WinRM) {
            $Prereq.All = $true
        }
    }
    end {
        return $Prereq
    }

}