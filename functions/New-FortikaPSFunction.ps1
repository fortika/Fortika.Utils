<#

	.SYNOPSIS
        Creates a new powershell function.

	.DESCRIPTION
        Creates a new powershell function.

    .PARAMETER Name
        Name of the function

	.EXAMPLE
        New-FortikaPSFunction -Name New-Stuff

	.NOTES

	.LINK

#>
Function New-FortikaPSFunction {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Name

        ,[Parameter(Mandatory=$False)]
        [hashtable]$Synposis

        ,[Parameter(Mandatory=$False)]
        [hashtable]$Description

        ,[Parameter(Mandatory=$False)]
        [hashtable]$Params
    )

    BEGIN {
    }

    PROCESS {

        <#
        $Params = @{
            Param1 = "string";
            Param2 = @{ type="string"; mandatory=$true}
        }
        #>


        $ParamArray = @()

        foreach($param in $Params) {

            $ParamName = $param
            $ParamType = $Params[$Paramname]

            if( $ParamType -is [hashtable]) {
                
            } else {
                # assume that value has the type
                $ParamArray += $ParamArray + "[Parameter()]`r`n[${ParamType}]`$${ParamName}`r`n"
            }        
        }


        $FunctionTemplate = @"
<#
	.SYNOPSIS        

	.DESCRIPTION        

    .PARAMETER Name        

	.EXAMPLE        

	.NOTES

	.LINK

#>
Function $Name {
    [cmdletBinding()]
    Param(
        $($ParamArray -join ",")
    )

    BEGIN {
    }

    PROCESS {
    }

    END {
    }
}

"@

    $FunctionTemplate


    }

    END {
    }
}

