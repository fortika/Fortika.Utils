# dot-source helpers
. ${PSScriptRoot}\functions\helpers\helper_functions.ps1


# dot-source functions
. ${PSScriptRoot}\functions\New-FortikaPSFunction.ps1
. ${PSScriptRoot}\functions\New-FortikaPSModule.ps1
. ${PSScriptRoot}\functions\Install-FortikaUtils.ps1

# make cmdlets available by exporting them.
Get-ChildItem function: | ? { $_.Name -like '*Fortika*' -and $_.Name -notlike '_*' } | Select Name | ForEach-Object { Export-ModuleMember -Function $_.Name }

