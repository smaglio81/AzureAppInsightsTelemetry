# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Test-AssemblyIsDesiredVersion
{
    <#
    .SYNOPSIS
        Checks if the specified file is the expected version.
    .DESCRIPTION
        Checks if the specified file is the expected version.
        Does a best effort match.  If you only specify a desired version of "6",
        any version of the file that has a "major" version of 6 will be considered
        a match, where we use the terminology of a version being:
        Major.Minor.Build.PrivateInfo.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .PARAMETER AssemblyPath
        The full path to the assembly file being tested.
    .PARAMETER DesiredVersion
        The desired version of the assembly.  Specify the version as specifically as
        necessary.
    .EXAMPLE
        Test-AssemblyIsDesiredVersion "c:\Microsoft.WindowsAzure.Storage.dll" "6"
        Returns back $true if "c:\Microsoft.WindowsAzure.Storage.dll" has a major version
        of 6, regardless of its Minor, Build or PrivateInfo numbers.
    .OUTPUTS
        Boolean - $true if the assembly at the specified path exists and meets the specified
        version criteria, $false otherwise.
#>
    param(
        [Parameter(Mandatory)]
        [ValidateScript( { if (Test-Path -PathType Leaf -Path $_) { $true }  else { throw "'$_' cannot be found." } })]
        [string] $AssemblyPath,

        [Parameter(Mandatory)]
        [ValidateScript( { if ($_ -match '^\d+(\.\d+){0,3}$') { $true } else { throw "'$_' not a valid version format." } })]
        [string] $DesiredVersion
    )

    $splitTargetVer = $DesiredVersion.Split('.')

    $file = Get-Item -Path $AssemblyPath -ErrorVariable ev
    if (($null -ne $ev) -and ($ev.Count -gt 0))
    {
        Write-Log "Problem accessing [$Path]: $($ev[0].Exception.Message)" -Level Warning
        return $false
    }

    $versionInfo = $file.VersionInfo
    $splitSourceVer = @(
        $versionInfo.ProductMajorPart,
        $versionInfo.ProductMinorPart,
        $versionInfo.ProductBuildPart,
        $versionInfo.ProductPrivatePart
    )

    # The cmdlet contract states that we only care about matching
    # as much of the version number as the user has supplied.
    for ($i = 0; $i -lt $splitTargetVer.Count; $i++)
    {
        if ($splitSourceVer[$i] -ne $splitTargetVer[$i])
        {
            return $false
        }
    }

    return $true
}