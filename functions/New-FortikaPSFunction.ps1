<#

	.SYNOPSIS
        Creates a new powershell function.

	.DESCRIPTION
        Creates a new powershell function.

    .PARAMETER Name
        Name of the function

    .PARAMETER Params
        Hashtable of the parameters for the function.

        $Params = @{
                help="string";
                AdvParameter = @{ Type="string"; 
                        Parameter=@{ Mandatory=$true; ValueFromPipelineByPropertyName=$True; HelpMessage="help" }; Extras=@{ ValidateSet="'alt1','alt2','alt3'"; Alias="'p1','p2'"} 
                }
            }

	.EXAMPLE
        New-FortikaPSFunction -Name New-Stuff

	.EXAMPLE
        New-FortikaPSFunction -Name Get-Stuff -Params @{
                StringParam="string";
                AdvParameter = @{ Type="string"; 
                        Parameter=@{ 
                            Mandatory=$true;
                            ValueFromPipelineByPropertyName=$True; HelpMessage="help";
                        };
                        Extras=@{ 
                            ValidateSet="'alt1','alt2','alt3'";
                            Alias="'p1','p2'"
                        } 
                }
            }

        Creates a function called Get-Stuff with 2 parameters
        Parameter StringParam as a simple parameter of type string
        Parameter AdvParam as an advanced parameter with the following properties
            [Parameter(Mandatory=$True,
				    ValueFromPipelineByPropertyName=$True,
				    HelpMessage="help")]
		    [Alias('p1','p2')]
		    [ValidateSet('alt1','alt2','alt3')]
		    [string]$AdvParameter


	.NOTES

	.LINK

#>
Function New-FortikaPSFunction {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Name

        ,[Parameter(Mandatory=$False)]
        [string]$Synposis

        ,[Parameter(Mandatory=$False)]
        [string]$Description

        ,[Parameter(Mandatory=$False)]
        [string]$Notes

        ,[Parameter(Mandatory=$False)]
        [string]$Link

        ,[Parameter(Mandatory=$False)]
        [hashtable]$Params

        ,[Parameter(Mandatory=$False)]
        [switch]$AddDummyOutput
    )

    BEGIN {
        $FunctionTemplate = @"
<#
	.SYNOPSIS        
        %HELP_SYNOPSIS%
	.DESCRIPTION        
        %HELP_DESCRIPTION%
    .PARAMETER         

	.EXAMPLE        

	.NOTES
        %HELP_NOTES%
	.LINK
        %HELP_LINK%
#>
Function %FUNCTIONNAME% {
    [cmdletBinding()]
    Param(
%PARAMETERS%
    )

    # Generated with New-FortikaPSFunction

    BEGIN {
		# If -debug is set, change `$DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If (`$PSBoundParameters['Debug']) {
			`$DebugPreference = 'Continue'
		}

%BEGINCODEBLOCK%
    }

    PROCESS {
%PROCESSCODEBLOCK%
    }

    END {
%ENDCODEBLOCK%
    }
}

"@

    }

    PROCESS {

        <#
        $Params = @{
            Param1 = "string";
            Param2 = @{ type="string"; Parameter=@{ mandatory=$true; ValueFromPipelineByPropertyName=$True; HelpMessage="help" }; Extras=@{ValidateSet="'alt1','alt2','alt3'"} }
        }
        #>


        # Handle the parameters...
        $ParamArray = @()

        foreach($param in $Params.Keys) {

            $ParamName = $param
            $ParamData = $Params[$param]

            # Check if the parameter data is an advaned parameter
            if( $ParamData -is [hashtable]) {

                # yes, advanced parameter. The parameter type should be in key "Type"
                $ParamType = $ParamData["Type"]
                if($ParamType) {
                    
                    # The rest should be in key "Parameter" which also is a hashtable

                    # Initialize the parameter block string
                    $ParameterBlockString = "[Parameter("

                    $ParameterBlock = $ParamData["Parameter"]
                    if($ParameterBlock -and $ParameterBlock -is [hashtable]) {
                        
                        # loop all key/values in the parameter block.
                        # the keys are the parameter attributes. See get-help about_Functions_Advanced_Parameters

                        # inspired by https://stackoverflow.com/questions/9015138/powershell-looping-through-a-hash-or-using-an-array
                        # Create a string for each key/value-pair on the format:
                        # key=value
                        # Ex. Mandatory=$true
                        #
                        # use .ToString() to handle that the value can be a boolean or integer etc.
                        # Join the resulting collection to a string separated with comma.
                        #                        
                        # "A one-liner a day keeps the alzheimers away"
                        #$ParameterBlockString += ($ParameterBlock.Keys | ForEach-Object { "$($_)=$($ParameterBlock.item($_).ToString())" }) -join ","
                        # would have been nice, but need to handle variable types here too :/

                        # this is much clearer than a one-liner :)
                        $ParameterBlockString += ($ParameterBlock.Keys | `
                            ForEach-Object { 
                                $BlockItem = $_

                                switch( (($ParameterBlock.item($BlockItem)).GetType()).Name ) {
                                    "Boolean" {
                                        "$($BlockItem)=`$$($ParameterBlock.item($BlockItem).ToString())" 
                                    }
                                    "String" {
                                        "$($BlockItem)=`"$($ParameterBlock.item($BlockItem).ToString())`"" 
                                    }
                                    Default {
                                        "$($BlockItem)=$($ParameterBlock.item($BlockItem).ToString())"                                         
                                    }
                                }
                            }) -join ",`r`n`t`t`t`t"


                        <#
                        foreach($blockitem in $ParameterBlock.Keys) {

                            # use .ToString() to handle that the value can be a boolean or integer etc.
                            $BlockItemValue = $ParameterBlock[$blockitem].ToString()

                            $ParameterBlockString += "${blockitem}=${BlockItemValue}"
                        }
                        #>

                    } else {
                        Write-Warning "No parameter block found for $ParamName or it's not defined as a hashtable."
                    }

                    $ParameterBlockString += ")]"


                    $ParameterExtras = $ParamData["Extras"]
                    $ParameterExtrasString = ""
                    If($ParameterExtras -and $ParameterExtras -is [hashtable]) {
                    
                        # ($h.keys | ForEach-Object { "$($_)=('$($h.item($_))')" })  -join ","
                        # [alias("CN","MachineName")]
                        $ParameterExtrasString = ($ParameterExtras.keys | ForEach-Object { "`t`t[$($_)($($ParameterExtras.item($_)))]" })  -join "`r`n"
                    }

                    if($ParameterExtrasString) {
                        $ParamArray += "`t`t${ParameterBlockString}`r`n$ParameterExtrasString`r`n`t`t[${ParamType}]`$${ParamName}`r`n"
                    } else {
                        $ParamArray += "`t`t${ParameterBlockString}`r`n`t`t[${ParamType}]`$${ParamName}`r`n"
                    }                    

                } else {
                    Write-Warning "Could not find parameter type for $ParamName"
                }                
            } elseif( $ParamData -is [string]) {
                # assume that value has the type
                $ParamType = $ParamData

                $ParamArray += "[Parameter()]`r`n`t`t[${ParamType}]`$${ParamName}`r`n"

            } else {
                Write-Warning "Unknown type for parameter $ParamName"
            }
        }

        if($AddDummyOutput) {
            $BeginCodeBlock = @"

        Write-Host `"Dummy output from `$(`$PSCmdlet.MyInvocation.InvocationName)`"

"@
        }


        $FunctionTemplate | _Expand-VariablesInString -VariableMappings @{
                                                                            FUNCTIONNAME=$Name;
                                                                            PARAMETERS=$($ParamArray -join "`r`n`t`t,");
                                                                            BEGINCODEBLOCK=$BeginCodeBlock;
                                                                            PROCESSCODEBLOCK=$ProcessCodeBlock;
                                                                            ENDCODEBLOCK=$EndCodeBlock;
                                                                            HELP_SYNOPSIS="${Synposis}`r`n";
                                                                            HELP_DESCRIPTION="${Description}`r`n"
                                                                            HELP_LINK="${Link}`r`n";
                                                                            HELP_NOTES="${Notes}`r`n"
                                                                        }
    }

    END {
    }
}
