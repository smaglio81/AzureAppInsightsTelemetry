# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Ensure-Directory
{
<#
    .SYNOPSIS
        A utility function for ensuring a given directory exists.
    .DESCRIPTION
        A utility function for ensuring a given directory exists.
        If the directory does not already exist, it will be created.
    .PARAMETER Path
        A full or relative path to the directory that should exist when the function exits.
    .NOTES
        Uses the Resolve-UnverifiedPath function to resolve relative paths.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification = "Unable to find a standard verb that satisfies describing the purpose of this internal helper method.")]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        $Path = Resolve-UnverifiedPath -Path $Path

        if (-not (Test-Path -PathType Container -Path $Path))
        {
            Write-Log -Message "Creating directory: [$Path]" -Level Verbose
            New-Item -ItemType Directory -Path $Path | Out-Null
        }
    }
    catch
    {
        Write-Log -Message "Could not ensure directory: [$Path]" -Level Error

        throw
    }
}