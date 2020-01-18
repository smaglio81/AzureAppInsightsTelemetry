# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Get-TelemetryClient
{
<#
    .SYNOPSIS
        Returns back a new instance of the Application Insights TelemetryClient.

    .DESCRIPTION
        Returns back a new instance of the Application Insights TelemetryClient.

        This will ensure all dependenty assemblies
        are available on the machine, create the client and initialize its properties.

        This will first look for the dependent assemblies in the module's script directory.

        Next it will look for the assemblies in the location defined by
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
        Get-TelemetryClient

        Returns back the singleton instance to the TelemetryClient for the module.
        If any nuget packages have to be downloaded in order to load the TelemetryClient, the
        command prompt will show a time duration status counter during the download process.

    .EXAMPLE
        Get-TelemetryClient -NoStatus

        Returns back the singleton instance to the TelemetryClient for the module.
        If any nuget packages have to be downloaded in order to load the TelemetryClient, the
        command prompt will appear to hang during this time.

    .OUTPUTS
        $ClientWrapper =
            @{
                Client = Microsoft.ApplicationInsights.TelemetryClient
                DisablePiiProtection = $false
                DisableTelemetry = $false
            }
        
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ApplicationInsightsKey,
        [switch] $NoStatus
    )

    Write-Log -Message "Initializing telemetry client." -Level Verbose

    $dlls = @(
                (Get-ThreadingTasksDllPath -NoStatus:$NoStatus),
                (Get-DiagnosticsTracingDllPath -NoStatus:$NoStatus),
                (Get-ApplicationInsightsDllPath -NoStatus:$NoStatus)
    )

    foreach ($dll in $dlls)
    {
        $bytes = [System.IO.File]::ReadAllBytes($dll)
        [System.Reflection.Assembly]::Load($bytes) | Out-Null
    }

    $username = Get-PiiSafeString -PlainText $env:USERNAME

    $client = New-Object Microsoft.ApplicationInsights.TelemetryClient
    
    $client.InstrumentationKey = $ApplicationInsightsKey
    $client.Context.User.Id = $username
    $client.Context.Session.Id = [System.GUID]::NewGuid().ToString()
    $client.Context.Properties['Username'] = $username
    $client.Context.Properties['DayOfWeek'] = (Get-Date).DayOfWeek
    $client.Context.Component.Version = $MyInvocation.MyCommand.Module.Version.ToString()

    $wrapper = @{
        Client = $client
        DisablePiiProtection = $false
        DisableTelemetry = $false
    }

    return $wrapper
}