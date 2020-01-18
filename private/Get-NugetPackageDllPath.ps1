# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-NugetPackageDllPath
{
<#
    .SYNOPSIS
        Makes sure that the specified assembly from a nuget package is available
        on the machine, and returns the path to it.
    .DESCRIPTION
        Makes sure that the specified assembly from a nuget package is available
        on the machine, and returns the path to it.
        This will first look for the assembly in the module's script directory.
        Next it will look for the assembly in the location defined by the configuration
        property AssemblyPath.
        If not found there, it will look in a temp folder established during this
        PowerShell session.
        If still not found, it will download the nuget package
        for it to a temp folder accessible during this PowerShell session.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .PARAMETER NugetPackageName
        The name of the nuget package to download
    .PARAMETER NugetPackageVersion
        Indicates the version of the package to download.
    .PARAMETER AssemblyPackageTailDirectory
        The sub-path within the nuget package download location where the assembly should be found.
    .PARAMETER AssemblyName
        The name of the actual assembly that the user is looking for.
    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
    .EXAMPLE
        Get-NugetPackageDllPath "WindowsAzure.Storage" "6.0.0" "WindowsAzure.Storage.6.0.0\lib\net40\" "Microsoft.WindowsAzure.Storage.dll"
        Returns back the path to "Microsoft.WindowsAzure.Storage.dll", which is part of the
        "WindowsAzure.Storage" nuget package.  If the package has to be downloaded via nuget,
        the command prompt will show a time duration status counter while the package is being
        downloaded.
    .EXAMPLE
        Get-NugetPackageDllPath "WindowsAzure.Storage" "6.0.0" "WindowsAzure.Storage.6.0.0\lib\net40\" "Microsoft.WindowsAzure.Storage.dll" -NoStatus
        Returns back the path to "Microsoft.WindowsAzure.Storage.dll", which is part of the
        "WindowsAzure.Storage" nuget package.  If the package has to be downloaded via nuget,
        the command prompt will appear to hang during this time.
    .OUTPUTS
        System.String - The full path to $AssemblyName.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $NugetPackageName,

        [Parameter(Mandatory)]
        [string] $NugetPackageVersion,

        [Parameter(Mandatory)]
        [string] $AssemblyPackageTailDirectory,

        [Parameter(Mandatory)]
        [string] $AssemblyName,

        [switch] $NoStatus
    )

    Write-Log -Message "Looking for $AssemblyName" -Level Verbose

    # First we'll check to see if the user has cached the assembly into the module's script directory
    $moduleAssembly = Join-Path -Path $PSScriptRoot -ChildPath $AssemblyName
    if (Test-Path -Path $moduleAssembly -PathType Leaf -ErrorAction Ignore)
    {
        if (Test-AssemblyIsDesiredVersion -AssemblyPath $moduleAssembly -DesiredVersion $NugetPackageVersion)
        {
            Write-Log -Message "Found $AssemblyName in module directory ($PSScriptRoot)." -Level Verbose
            return $moduleAssembly
        }
        else
        {
            Write-Log -Message "Found $AssemblyName in module directory ($PSScriptRoot), but its version number [$moduleAssembly] didn't match required [$NugetPackageVersion]." -Level Verbose
        }
    }

    # Next, we'll check to see if the user has defined an alternate path to get the assembly from
    $alternateAssemblyPath = $global:AzureAppInsightsTelemetry.AssemblyPath
    if (-not [System.String]::IsNullOrEmpty($alternateAssemblyPath))
    {
        $assemblyPath = Join-Path -Path $alternateAssemblyPath -ChildPath $AssemblyName
        if (Test-Path -Path $assemblyPath -PathType Leaf -ErrorAction Ignore)
        {
            if (Test-AssemblyIsDesiredVersion -AssemblyPath $assemblyPath -DesiredVersion $NugetPackageVersion)
            {
                Write-Log -Message "Found $AssemblyName in alternate directory ($alternateAssemblyPath)." -Level Verbose
                return $assemblyPath
            }
            else
            {
                Write-Log -Message "Found $AssemblyName in alternate directory ($alternateAssemblyPath), but its version number [$moduleAssembly] didn't match required [$NugetPackageVersion]." -Level Verbose
            }
        }
    }

    # Then we'll check to see if we've previously cached the assembly in a temp folder during this PowerShell session
    if ([System.String]::IsNullOrEmpty($global:AzureAppInsightsTelemetry.TempAssemblyCacheDir))
    {
        $global:AzureAppInsightsTelemetry.TempAssemblyCacheDir = New-TemporaryDirectory
    }
    else
    {
        $cachedAssemblyPath = Join-Path -Path $(Join-Path $global:AzureAppInsightsTelemetry.TempAssemblyCacheDir $AssemblyPackageTailDirectory) $AssemblyName
        if (Test-Path -Path $cachedAssemblyPath -PathType Leaf -ErrorAction Ignore)
        {
            if (Test-AssemblyIsDesiredVersion -AssemblyPath $cachedAssemblyPath -DesiredVersion $NugetPackageVersion)
            {
                Write-Log -Message "Found $AssemblyName in temp directory ($global:AzureAppInsightsTelemetry.TempAssemblyCacheDir)." -Level Verbose
                return $cachedAssemblyPath
            }
            else
            {
                Write-Log -Message "Found $AssemblyName in temp directory ($global:AzureAppInsightsTelemetry.TempAssemblyCacheDir), but its version number [$moduleAssembly] didn't match required [$NugetPackageVersion]." -Level Verbose
            }
        }
    }

    # Still not found, so we'll go ahead and download the package via nuget.
    Write-Log -Message "$AssemblyName is needed and wasn't found.  Acquiring it via nuget..." -Level Verbose
    Get-NugetPackage -PackageName $NugetPackageName -Version $NugetPackageVersion -TargetPath $global:AzureAppInsightsTelemetry.TempAssemblyCacheDir -NoStatus:$NoStatus

    $cachedAssemblyPath = Join-Path -Path $(Join-Path -Path $global:AzureAppInsightsTelemetry.TempAssemblyCacheDir -ChildPath $AssemblyPackageTailDirectory) -ChildPath $AssemblyName
    if (Test-Path -Path $cachedAssemblyPath -PathType Leaf -ErrorAction Ignore)
    {
        Copy-Item -Path $cachedAssemblyPath -Destination $global:AzureAppInsightsTelemetry.AssemblyPath
        Write-Log -Message @("Downloading [$cachedAssemblyPath] and copied to [$($global:AzureAppInsightsTelemetry.AssemblyPath)]")
        # Write-Log -Message @(
        #     "To avoid this download delay in the future, copy the following file:",
        #     "  [$cachedAssemblyPath]",
        #     "either to:",
        #     "  [$PSScriptRoot]",
        #     "or to:",
        #     "  a directory of your choosing, and store that directory as 'AssemblyPath' with 'Set-GitHubConfiguration'")

        return $cachedAssemblyPath
    }

    $message = "Unable to acquire a reference to $AssemblyName."
    Write-Log -Message $message -Level Error
    throw $message
}