# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Resolve-UnverifiedPath
{
<#
    .SYNOPSIS
        A wrapper around Resolve-Path that works for paths that exist as well
        as for paths that don't (Resolve-Path normally throws an exception if
        the path doesn't exist.)
    .DESCRIPTION
        A wrapper around Resolve-Path that works for paths that exist as well
        as for paths that don't (Resolve-Path normally throws an exception if
        the path doesn't exist.)
        The Git repo for this module can be found here: https://aka.ms/PowerShellForGitHub
    .EXAMPLE
        Resolve-UnverifiedPath -Path 'c:\windows\notepad.exe'
        Returns the string 'c:\windows\notepad.exe'.
    .EXAMPLE
        Resolve-UnverifiedPath -Path '..\notepad.exe'
        Returns the string 'c:\windows\notepad.exe', assuming that it's executed from
        within 'c:\windows\system32' or some other sub-directory.
    .EXAMPLE
        Resolve-UnverifiedPath -Path '..\foo.exe'
        Returns the string 'c:\windows\foo.exe', assuming that it's executed from
        within 'c:\windows\system32' or some other sub-directory, even though this
        file doesn't exist.
    .OUTPUTS
        [string] - The fully resolved path
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            ValueFromPipeline)]
        [string] $Path
    )

    $resolvedPath = Resolve-Path -Path $Path -ErrorVariable resolvePathError -ErrorAction SilentlyContinue

    if ($null -eq $resolvedPath)
    {
        return $resolvePathError[0].TargetObject
    }
    else
    {
        return $resolvedPath.ProviderPath
    }
}