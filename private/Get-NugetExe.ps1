# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-NugetExe
{
<#
    .SYNOPSIS
        Downloads nuget.exe from http://nuget.org to a new local temporary directory
        and returns the path to the local copy.
    .DESCRIPTION
        Downloads nuget.exe from http://nuget.org to a new local temporary directory
        and returns the path to the local copy.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .EXAMPLE
        Get-NugetExe
        Creates a new directory with a GUID under $env:TEMP and then downloads
        http://nuget.org/nuget.exe to that location.
    .OUTPUTS
        System.String - The path to the newly downloaded nuget.exe
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param()

    if ([String]::IsNullOrEmpty($global:AzureAppInsightsTelemetry.NugetExePath))
    {
        $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
        $global:AzureAppInsightsTelemetry.NugetExePath = Join-Path $(New-TemporaryDirectory) "nuget.exe"

        Write-Log -Message "Downloading $sourceNugetExe to $global:AzureAppInsightsTelemetry.NugetExePath" -Level Verbose
        Invoke-WebRequest $sourceNugetExe -OutFile $global:AzureAppInsightsTelemetry.NugetExePath
    }

    return $global:AzureAppInsightsTelemetry.NugetExePath
}