Function _Expand-VariablesInString {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True
                  ,ValueFromPipeline=$True)]
        [string]$Inputstring,

        [Parameter(Mandatory=$True)]
        [hashtable]$VariableMappings
    )


    foreach($key in $Variablemappings.Keys) {

        $InputString = $Inputstring.Replace("%"+$key+"%",$VariableMappings[$key])
    }


    return $Inputstring
}
