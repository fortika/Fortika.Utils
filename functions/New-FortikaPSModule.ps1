<#
	.SYNOPSIS
        Creates and initializes a new module

	.DESCRIPTION

	.PARAMETER Name

	.PARAMETER Path

	.EXAMPLE
        New-FortikaPSModule

	.NOTES

	.LINK
#>
$ManifestUpdateFunction=@'
<#
	.SYNOPSIS
        Utility function to update the module manifesto

	.DESCRIPTION

	.EXAMPLE
        Update-%MODULE_PREFIX%ModuleManifest

	.NOTES

	.LINK

#>
[cmdletBinding()]
Param(
	[Parameter(Mandatory=$False)]
	[string]$Path
)

# If -debug is set, change $DebugPreference so that output is a little less annoying.
#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
If ($PSBoundParameters['Debug']) {
	$DebugPreference = 'Continue'
}



$ManifestParams = @{
	Path = ''

	# Script module or binary module file associated with this manifest.
	RootModule = '%MODULE_NAME%.psm1'

	# Version number of this module.
	ModuleVersion = '1.0'

	# Supported PSEditions
	# CompatiblePSEditions = @()

	# ID used to uniquely identify this module
	GUID = '%MODULE_GUID%'

	# Author of this module
	Author = '%MODULE_AUTHOR%'

	# Company or vendor of this module
	CompanyName = '%MODULE_COMPANY%'

	# Copyright statement for this module
	Copyright = ' '

	# Description of the functionality provided by this module
	# Description = ''

	# Minimum version of the Windows PowerShell engine required by this module
	# PowerShellVersion = ''

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ''

	# Minimum version of the Windows PowerShell host required by this module
	# PowerShellHostVersion = ''

	# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# DotNetFrameworkVersion = ''

	# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	# CLRVersion = ''

	# Processor architecture (None, X86, Amd64) required by this module
	# ProcessorArchitecture = ''

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	ScriptsToProcess = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	# NestedModules = @()

	# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport = @()

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = @()

	# Variables to export from this module
	VariablesToExport = '*'

	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = @()

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList = @()

	# List of all files packaged with this module
	# FileList = @()

	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
	} # End of PrivateData hashtable

	# HelpInfo URI of this module
	# HelpInfoURI = ''

	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
}


# We assume that this function is located in a subdirectory to the module

if(-Not $Path) {
	if(-Not ${PSScriptRoot}) {
		$ModuleRoot = Split-path -path (Get-Location).Path -Parent
	} else {
		$ModuleRoot = Split-Path -path ${PSScriptRoot} -Parent
	}
} else {
	$ModuleRoot = $Path
}

Write-Debug "ModuleRoot = $ModuleRoot"		

# Do some sanity testing
$FunctionsDir = get-item -Path (join-path -Path $ModuleRoot -ChildPath "functions")
if( (-Not $FunctionsDir) -or (-Not $FunctionsDir.PSIsContainer) ) {
	Throw "Weops! Our assumed module directory $ModuleRoot does not seem to be correct!"
}


$ManifestParams.Path = $(Join-Path -Path $ModuleRoot -ChildPath "%MODULE_NAME%.psd1" )

# There is probably a better way to do this...
# ? { $_.Name -like '*-BIF*.ps1'} |
$Functions = get-childitem "${ModuleRoot}\functions\*.ps1" |  ForEach-Object { $_.Name.Replace(".ps1","") }

$ManifestParams.FunctionsToExport = $Functions

New-ModuleManifest @ManifestParams

'@

$ModuleRootFunction=@'
# Check if $PSScriptRoot is set. If not set then we might be running "interactivly", so set the module root to current location.
if(-Not ${PSScriptRoot}) {
    $ModuleRoot = (Get-Location).Path
} else {
    $ModuleRoot = ${PSScriptRoot}
}


# dot-source cmdlet functions by listing all ps1-files in subfolder functions to where the module file is located
get-childitem ${ModuleRoot}\functions\*.ps1 -recurse | Sort-Object Name | ForEach-Object { . $_.FullName }


'@


Function New-FortikaPSModule {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
		[string]$Name

        ,[Parameter(Mandatory=$False)]
		[string]$Prefix

		,[Parameter(Mandatory=$False)]
		[string]$Path

    )

    # Generated with New-FortikaPSFunction

    BEGIN {
		# If -debug is set, change $DebugPreference so that output is a little less annoying.
		#	http://learn-powershell.net/2014/06/01/prevent-write-debug-from-bugging-you/
		If ($PSBoundParameters['Debug']) {
			$DebugPreference = 'Continue'
		}


        if(-Not $Path) {
            $Path = (Get-Location).Path
        }

        $OutputPath = Join-Path -Path $Path -ChildPath $name

        if($(Test-Path -Path $OutputPath)) {
            Throw "{0} already exits!" -f $OutputPath
        }

        try {
            mkdir $OutputPath -ErrorAction stop | Out-Null
            mkdir "$OutputPath\functions" -ErrorAction stop | Out-Null
            mkdir "$OutputPath\util" -ErrorAction stop | Out-Null
        }
        catch {
            Throw "Could not create directory {0}`r`n{1}" -f $OutputPath,$($_.Exception.Message)
        }


        $VarMappings=@{
                        MODULE_PREFIX=$Prefix;
                        MODULE_NAME=$Name;
                        MODULE_GUID=([guid]::NewGuid()).ToString();
                        MODULE_AUTHOR=" ";
                        MODULE_COMPANY=" ";
                    }
		$ManifestUpdatePath="$OutputPath\util\Update-${Prefix}ModuleManifest.ps1"
		
		Write-Verbose "Writing manifest update function to $ManifestUpdatePath"
		
        $ManifestUpdateFunction | _Expand-VariablesInString -VariableMappings $VarMappings | Set-Content -Path $ManifestUpdatePath
		
		$ModuleRootFunctionPath = Join-Path -Path $OutputPath -ChildPath "${Name}.psm1"
		Write-Verbose "Writing module file to $ModuleRootFunctionPath"
		$ModuleRootFunction | Set-Content -Path $ModuleRootFunctionPath
		
		Write-Verbose "Writing manifest file by calling $ManifestUpdatePath"
		& $ManifestUpdatePath


    }

    PROCESS {

    }

    END {

    }
}
