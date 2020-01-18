# http://stackoverflow.com/questions/1183183/path-of-currently-executing-powershell-script
$root = Split-Path $MyInvocation.MyCommand.Path -Parent;

#Import-Module WebAdministration
#Import-Module CoreUcsb
#Import-Module SecretServerUcsb

# grab functions from files (from C:\Chocolatey\chocolateyinstall\helpers\chocolateyInstaller.psm1)
Resolve-Path $root\AzureAppInsightsTelemetry.*.ps1 | 
	? { -not ($_.ProviderPath.Contains(".Tests.")) } |
	% { . $_.ProviderPath; }


# grab functions from files (from C:\Chocolatey\chocolateyinstall\helpers\chocolateyInstaller.psm1)
$privateFiles = dir -Path $root\private -Recurse -Include *.ps1 -ErrorAction SilentlyContinue
$publicFiles = dir -Path $root\public -Recurse -Include *.ps1 -ErrorAction SilentlyContinue

if(@($privateFiles).Count -gt 0) { $privateFiles.FullName |% { . $_; } }
if(@($publicFiles).Count -gt 0) { $publicFiles.FullName |% { . $_; } }

$publicFuncs = $publicFiles |% { $_.Name.Substring(0, $_.Name.Length - 4) }
Export-ModuleMember -Function $publicFuncs


# setup namespaced domain variabless
if($null -eq $global:AzureAppInsightsTelemetry) {
	$global:AzureAppInsightsTelemetry = @{};

	$global:AzureAppInsightsTelemetry.AlwaysExcludeParametersForLogging = @('NoStatus')
	$global:AzureAppInsightsTelemetry.AlwaysRedactParametersForLogging = @('AccessToken') # Would be a security issue
	$global:AzureAppInsightsTelemetry.AssemblyPath = "$PSScriptRoot\resources"
	$global:AzureAppInsightsTelemetry.DisableLogging = $true
	$global:AzureAppInsightsTelemetry.LogProcessId = $false
	$global:AzureAppInsightsTelemetry.LogTimeAsUtc = $false
	$global:AzureAppInsightsTelemetry.NugetExePath = [string]::Empty
	$global:AzureAppInsightsTelemetry.TempAssemblyCacheDir = [string]::Empty

	$logPath = [String]::Empty
    $documentsFolder = [System.Environment]::GetFolderPath('MyDocuments')
    if (-not [System.String]::IsNullOrEmpty($documentsFolder))
    {
        $logPath = Join-Path -Path $documentsFolder -ChildPath 'AzureAppInsightsTelemetry.log'
    }
	$global:AzureAppInsightsTelemetry.LogPath = $logPath
	
}

$ExecutionContext.SessionState.Module.OnRemove += {
    Remove-Variable -Name AzureAppInsightsTelemetry -Scope global
}

