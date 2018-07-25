Function Get-GroupCache {
    <#
      .Synopsis
      Reads the cached json file where the AD Groups are stored

      .Description
      Reads the cached json file where the AD Groups are stored

      .Parameter Path
      File Path to the folder where it should be stored. Alias is 'P'.

       .Outputs
      System.String Array. Get-LDAPGroup returns an string array with all config groups


  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [Alias('P')]
        [string]$Path
    )
    begin {
        #Maybe should be stored as param (thinking...)
        $Filename = 'CachedAdGroups.json'
        $Groups = @()
    }
    process {
        try {
            $Groups = Get-Content -Raw -Path  "$Path\$Filename" | ConvertFrom-Json
        } catch {
            Write-Error -Message $_.Exception.Message
        }
    }
    end {
        return $Groups
    }

}