# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-DiagnosticsTracingDllPath
{
<#
    .SYNOPSIS
        Makes sure that the Microsoft.Diagnostics.Tracing.EventSource.dll assembly is available
        on the machine, and returns the path to it.

    .DESCRIPTION
        Makes sure that the Microsoft.Diagnostics.Tracing.EventSource.dll assembly is available
        on the machine, and returns the path to it.

        This will first look for the assembly in the module's script directory.

        Next it will look for the assembly in the location defined by
        $SBAlternateAssemblyDir.  This value would have to be defined by the user
        prior to execution of this cmdlet.

        If not found there, it will look in a temp folder established during this
        PowerShell session.

        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-DiagnosticsTracingDllPath

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will show a time duration
        status counter while the package is being downloaded.

    .EXAMPLE
        Get-DiagnosticsTracingDllPath -NoStatus

        Returns back the path to the assembly as found.  If the package has to
        be downloaded via nuget, the command prompt will appear to hang during
        this time.

    .OUTPUTS
        System.String - The path to the Microsoft.ApplicationInsights.dll assembly.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [switch] $NoStatus
    )

    $nugetPackageName = "Microsoft.Diagnostics.Tracing.EventSource.Redist"
    $nugetPackageVersion = "1.1.24"
    $assemblyPackageTailDir = "Microsoft.Diagnostics.Tracing.EventSource.Redist.1.1.24\lib\net35"
    $assemblyName = "Microsoft.Diagnostics.Tracing.EventSource.dll"

    return Get-NugetPackageDllPath -NugetPackageName $nugetPackageName -NugetPackageVersion $nugetPackageVersion -AssemblyPackageTailDirectory $assemblyPackageTailDir -AssemblyName $assemblyName -NoStatus:$NoStatus
}