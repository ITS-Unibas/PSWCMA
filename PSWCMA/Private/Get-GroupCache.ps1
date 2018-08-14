Function Get-GroupCache {
    <#
      .Synopsis
      Reads the cached json file where the AD Groups are stored

      .Description
      Reads the cached json file where the AD Groups are stored

      .Parameter Path
      File Path to the folder where the cache is located. Alias is 'P'.

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
            #Reads groups from the cache. Chache has to be in json
            $Groups = Get-Content -Raw -Path  "$Path\$Filename" | ConvertFrom-Json
        } catch {
            Write-Error -Message $_.Exception.Message
        }
    }
    end {
        return $Groups
    }

}