<#
	.SYNOPSIS        

	.DESCRIPTION        

    .PARAMETER ProfilePath

    .PARAMETER Global

    .PARAMETER Manual
        Edit the profile manually

	.EXAMPLE        

	.NOTES

	.LINK

#>
Function Install-FortikaUtils {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)]
        [string]$ProfilePath

        ,[Parameter(Mandatory=$False)]
        [switch]$Global

        ,[Parameter(Mandatory=$False)]
        [switch]$Manual
    )

    BEGIN {
    }

    PROCESS {
    }

    END {
    }
}
