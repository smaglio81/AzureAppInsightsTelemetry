# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Set-TelemetryEvent
{
<#
    .SYNOPSIS
        Posts a new telemetry event for this module to the configured Applications Insights instance.

    .DESCRIPTION
        Posts a new telemetry event for this module to the configured Applications Insights instance.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER EventName
        The name of the event that has occurred.

    .PARAMETER Properties
        A collection of name/value pairs (string/string) that should be associated with this event.

    .PARAMETER Metrics
        A collection of name/value pair metrics (string/double) that should be associated with
        this event.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Set-TelemetryEvent "zFooTest1"

        Posts a "zFooTest1" event with the default set of properties and metrics.  If the telemetry
        client needs to be created to accomplish this, and the required assemblies are not available
        on the local machine, the download status will be presented at the command prompt.

    .EXAMPLE
        Set-TelemetryEvent "zFooTest1" @{"Prop1" = "Value1"}

        Posts a "zFooTest1" event with the default set of properties and metrics along with an
        additional property named "Prop1" with a value of "Value1".  If the telemetry client
        needs to be created to accomplish this, and the required assemblies are not available
        on the local machine, the download status will be presented at the command prompt.

    .EXAMPLE
        Set-TelemetryEvent "zFooTest1" -NoStatus

        Posts a "zFooTest1" event with the default set of properties and metrics.  If the telemetry
        client needs to be created to accomplish this, and the required assemblies are not available
        on the local machine, the command prompt will appear to hang while they are downloaded.

    .NOTES
        Because of the short-running nature of this module, we always "flush" the events as soon
        as they have been posted to ensure that they make it to Application Insights.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject] $ClientWrapper,

        [Parameter(Mandatory)]
        [string] $EventName,

        [hashtable] $Properties = @{},

        [hashtable] $Metrics = @{},

        [switch] $NoStatus
    )

    if ($global:AppInsightsTelemeteryUcsb.DisableTelemetry)
    {
        Write-Log -Message "Telemetry has been disabled via configuration. Skipping reporting event [$EventName]." -Level Verbose
        return
    }

    Write-InvocationLog -ExcludeParameter @('Properties', 'Metrics')

    if($null -eq $ClientWrapper.Client) {
        Write-Log -Message "ClientWrapper.Client is null. ClientWrapper should be regenerated using Get-TelemetryClient." -Level Error
        return
    }

    try
    {
        $telemetryClient = $ClientWrapper.Client

        $propertiesDictionary = New-Object 'System.Collections.Generic.Dictionary[string, string]'
        $propertiesDictionary['DayOfWeek'] = (Get-Date).DayOfWeek
        $Properties.Keys | ForEach-Object { $propertiesDictionary[$_] = $Properties[$_] }

        $metricsDictionary = New-Object 'System.Collections.Generic.Dictionary[string, double]'
        $Metrics.Keys | ForEach-Object { $metricsDictionary[$_] = $Metrics[$_] }

        $telemetryClient.TrackEvent($EventName, $propertiesDictionary, $metricsDictionary);

        # Flushing should increase the chance of success in uploading telemetry logs
        Clear-TelemetryClient -ClientWrapper $ClientWrapper -NoStatus:$NoStatus
    }
    catch
    {
        # Telemetry should be best-effort.  Failures while trying to handle telemetry should not
        # cause exceptions in the app itself.
        Write-Log -Message "Set-TelemetryEvent failed:" -Exception $_ -Level Error
    }
}