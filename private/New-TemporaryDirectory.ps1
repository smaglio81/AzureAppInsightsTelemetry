# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function New-TemporaryDirectory
{
<#
    .SYNOPSIS
        Creates a new subdirectory within the users's temporary directory and returns the path.
    .DESCRIPTION
        Creates a new subdirectory within the users's temporary directory and returns the path.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .EXAMPLE
        New-TemporaryDirectory
        Creates a new directory with a GUID under $env:TEMP
    .OUTPUTS
        System.String - The path to the newly created temporary directory
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param()

    $guid = [System.GUID]::NewGuid()
    while (Test-Path -PathType Container (Join-Path -Path $env:TEMP -ChildPath $guid))
    {
        $guid = [System.GUID]::NewGuid()
    }

    $tempFolderPath = Join-Path -Path $env:TEMP -ChildPath $guid

    Write-Log -Message "Creating temporary directory: $tempFolderPath" -Level Verbose
    New-Item -ItemType Directory -Path $tempFolderPath
}