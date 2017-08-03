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

    .PARAMETER OutputType
        If specified adds an output type for the returned data.

	.NOTES

	.LINK

#>
Function New-FortikaPSFunction {
    [cmdletBinding(SupportsShouldProcess=$True,ConfirmImpact="High")]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Name

        ,[Parameter(Mandatory=$False)]
        [string]$Synopsis

        ,[Parameter(Mandatory=$False)]
        [string]$Description

        ,[Parameter(Mandatory=$False)]
        [string]$Notes

        ,[Parameter(Mandatory=$False)]
        [string]$Link

        ,[Parameter(Mandatory=$False)]
        [hashtable]$Params

        ,[Parameter(Mandatory=$False)]
        [string]$OutputType

        ,[Parameter(Mandatory=$False)]
        [switch]$AddDummyOutput

        ,[Parameter(Mandatory=$False)]
        [switch]$SkipBeginProcessEnd

        ,[Parameter(Mandatory=$False
                   ,HelpMessage="If specified writes the function to a file or directory with automatic file name.")]
        [string]$Path

        ,[Parameter(Mandatory=$False
                   ,HelpMessage="Number of spaces per tab")]
        [int]$NumTabSpaces=4

    )

    BEGIN {
        $FunctionTemplate = @"
<#
	.SYNOPSIS
        %HELP_SYNOPSIS%
	.DESCRIPTION
        %HELP_DESCRIPTION%
%HELP_PARAMETERBLOCK%
	.EXAMPLE
        %HELP_EXAMPLE%
	.NOTES
        %HELP_NOTES%
	.LINK
        %HELP_LINK%
#>
Function %FUNCTIONNAME% {
    [cmdletBinding()]%OUTPUTTYPEBLOCK%
    Param(
%PARAMETERS%
    )

    # Generated with %GENERATEDBY%

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
                            }) -join ",`r`n"


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
                        $ParameterExtrasString = ($ParameterExtras.keys | ForEach-Object { "[$($_)($($ParameterExtras.item($_)))]" })  -join "`r`n"
                    }

                    if($ParameterExtrasString) {
                        $ParamArray += "${ParameterBlockString}`r`n$ParameterExtrasString`r`n[${ParamType}]`$${ParamName}`r`n"
                    } else {
                        $ParamArray += "${ParameterBlockString}`r`n[${ParamType}]`$${ParamName}`r`n"
                    }

                    $Help_ParameterBlock += ".PARAMETER ${ParamName}`r`n`r`n"

                } else {
                    Write-Warning "Could not find parameter type for $ParamName"
                }                
            } elseif( $ParamData -is [string]) {
                # assume that value has the type
                $ParamType = $ParamData

                $ParamArray += "[Parameter(Mandatory=`$False)]`r`n[${ParamType}]`$${ParamName}`r`n"

                $Help_ParameterBlock += ".PARAMETER ${ParamName}`r`n`r`n"

            } else {
                Write-Warning "Unknown type for parameter $ParamName"
            }
        }

        if($AddDummyOutput) {
            $BeginCodeBlock = @"

        Write-Host `"Dummy output from `$(`$PSCmdlet.MyInvocation.InvocationName)`"

"@
        }

        if($OutputType) {
            # not pretty...
            $OutputTypeBlock = "`r`n`t[OutputType([$OutputType])]"
        } else {
            $OutputTypeBlock  = ""
        }


        $FunctionData = $FunctionTemplate | _Expand-VariablesInString -VariableMappings @{
                                                                            GENERATEDBY=$PSCmdlet.MyInvocation.Line;
                                                                            FUNCTIONNAME=$Name;
                                                                            PARAMETERS=$($ParamArray -join "`r`n,");
                                                                            BEGINCODEBLOCK=$BeginCodeBlock;
                                                                            PROCESSCODEBLOCK=$ProcessCodeBlock;
                                                                            ENDCODEBLOCK=$EndCodeBlock;
                                                                            OUTPUTTYPEBLOCK=$OutputTypeBlock
                                                                            HELP_SYNOPSIS="${Synopsis}";
                                                                            HELP_DESCRIPTION="${Description}";
                                                                            HELP_PARAMETERBLOCK="${Help_ParameterBlock}";
                                                                            HELP_EXAMPLE="${Name}`r`n";
                                                                            HELP_LINK="${Link}";
                                                                            HELP_NOTES="${Notes}";
                                                                        }
        $FunctionData = ($FunctionData -replace "`t",("".PadLeft($NumTabSpaces," "))).trim()

        if($Path) {
        
            try {
                # check if Path is a directory.
                # If so, write the output to a file, named as the function name with extension .ps1.
                # If Path is a file, then write it there.
                # If Path does not exist, then assume it's a file.

                # get the "item"
		# ignore errors
                $FileItem = Get-Item -Path $Path -ErrorAction SilentlyContinue

                if($FileItem.PSIsContainer) {
                    $OutputPath = Join-Path -Path $Path -ChildPath "${Name}.ps1"
                } else {
                    $OutputPath = $Path
                }
                
                $WriteFile = $False
                # Show a confirmation if $OutputPath exists
                if($(Test-Path -Path $OutputPath)) {
                    if($PSCmdlet.ShouldProcess("$OutputPath","Overwrite")) {                        
                        $WriteFile = $True
                    }
                } else {
                    $WriteFile = $true
                }

                If($WriteFile) {
                    try {
                        Write-Verbose "Writing output to $OutputPath"
                        $FunctionData | Set-Content -Path $OutputPath -ErrorAction stop
                    }
                    catch {
                        Throw "Could not write output to {0}`r`n{1}" -f $OutputPath, $_.Exception.Message
                    }
                }
            }
            catch {
                Throw "Cant output to {0}`r`n{1}" -f $Path, $_.Exception.Message
            }

        } else {
            $FunctionData
        }
    }

    END {
    }
}
