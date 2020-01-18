# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-NugetPackage
{
<#
    .SYNOPSIS
        Downloads a nuget package to the specified directory.
    .DESCRIPTION
        Downloads a nuget package to the specified directory (or the current
        directory if no TargetPath was specified).
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .PARAMETER PackageName
        The name of the nuget package to download
    .PARAMETER TargetPath
        The nuget package will be downloaded to this location.
    .PARAMETER Version
        If provided, this indicates the version of the package to download.
        If not specified, downloads the latest version.
    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.
    .EXAMPLE
        Get-NugetPackage "Microsoft.AzureStorage" -Version "6.0.0.0" -TargetPath "c:\foo"
        Downloads v6.0.0.0 of the Microsoft.AzureStorage nuget package to the c:\foo directory.
    .EXAMPLE
        Get-NugetPackage "Microsoft.AzureStorage" "c:\foo"
        Downloads the most recent version of the Microsoft.AzureStorage
        nuget package to the c:\foo directory.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [string] $PackageName,

        [Parameter(Mandatory)]
        [ValidateScript({if (Test-Path -Path $_ -PathType Container) { $true } else { throw "$_ does not exist." }})]
        [string] $TargetPath,

        [string] $Version,

        [switch] $NoStatus
    )

    Write-Log -Message "Downloading nuget package [$PackageName] to [$TargetPath]" -Level Verbose

    $nugetPath = Get-NugetExe

    if ($NoStatus)
    {
        if ($PSCmdlet.ShouldProcess($PackageName, $nugetPath))
        {
            if (-not [System.String]::IsNullOrEmpty($Version))
            {
                & $nugetPath install $PackageName -o $TargetPath -version $Version -source nuget.org -NonInteractive | Out-Null
            }
            else
            {
                & $nugetPath install $PackageName -o $TargetPath -source nuget.org -NonInteractive | Out-Null
            }
        }
    }
    else
    {
        $jobName = "Get-NugetPackage-" + (Get-Date).ToFileTime().ToString()

        if ($PSCmdlet.ShouldProcess($jobName, "Start-Job"))
        {
            [scriptblock]$scriptBlock = {
                param($NugetPath, $PackageName, $TargetPath, $Version)

                if (-not [System.String]::IsNullOrEmpty($Version))
                {
                    & $NugetPath install $PackageName -o $TargetPath -version $Version -source nuget.org
                }
                else
                {
                    & $NugetPath install $PackageName -o $TargetPath -source nuget.org
                }
            }

            Start-Job -Name $jobName -ScriptBlock $scriptBlock -Arg @($nugetPath, $PackageName, $TargetPath, $Version) | Out-Null

            if ($PSCmdlet.ShouldProcess($jobName, "Wait-JobWithAnimation"))
            {
                Wait-JobWithAnimation -Name $jobName -Description "Retrieving nuget package: $PackageName"
            }

            if ($PSCmdlet.ShouldProcess($jobName, "Receive-Job"))
            {
                Receive-Job $jobName -AutoRemoveJob -Wait -ErrorAction SilentlyContinue -ErrorVariable remoteErrors | Out-Null
            }
        }

        if ($remoteErrors.Count -gt 0)
        {
            throw $remoteErrors[0].Exception
        }
    }
}