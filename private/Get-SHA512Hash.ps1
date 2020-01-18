# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-SHA512Hash
{
<#
    .SYNOPSIS
        Gets the SHA512 hash of the requested string.
    .DESCRIPTION
        Gets the SHA512 hash of the requested string.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .PARAMETER PlainText
        The plain text that you want the SHA512 hash for.
    .EXAMPLE
        Get-SHA512Hash -PlainText "Hello World"
        Returns back the string "2C74FD17EDAFD80E8447B0D46741EE243B7EB74DD2149A0AB1B9246FB30382F27E853D8585719E0E67CBDA0DAA8F51671064615D645AE27ACB15BFB1447F459B"
        which represents the SHA512 hash of "Hello World"
    .OUTPUTS
        System.String - A SHA512 hash of the provided string
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $PlainText
    )

    $sha512= New-Object -TypeName System.Security.Cryptography.SHA512CryptoServiceProvider
    $utf8 = New-Object -TypeName System.Text.UTF8Encoding
    return [System.BitConverter]::ToString($sha512.ComputeHash($utf8.GetBytes($PlainText))) -replace '-', ''
}