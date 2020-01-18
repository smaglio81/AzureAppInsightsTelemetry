# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Clear-TelemetryClient
{
<#
    .SYNOPSIS
        Flushes the buffer of stored telemetry events to the configured Applications Insights instance.

    .DESCRIPTION
        Flushes the buffer of stored telemetry events to the configured Applications Insights instance.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Clear-TelemetryClient

        Attempts to push all buffered telemetry events for this telemetry client immediately to
        Application Insights.  If the telemetry client needs to be created to accomplish this,
        and the required assemblies are not available on the local machine, the download status
        will be presented at the command prompt.

    .EXAMPLE
        Clear-TelemetryClient -NoStatus

        Attempts to push all buffered telemetry events for this telemetry client immediately to
        Application Insights.  If the telemetry client needs to be created to accomplish this,
        and the required assemblies are not available on the local machine, the command prompt
        will appear to hang while they are downloaded.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Internal-only helper method.  Matches the internal method that is called.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject] $ClientWrapper,
        [switch] $NoStatus
    )

    Write-InvocationLog

    if ($ClientWrapper.DisableTelemetry)
    {
        Write-Log -Message "Telemetry has been disabled via configuration. Skipping flushing of the telemetry client." -Level Verbose
        return
    }

    if ($null -eq $ClientWrapper.Client -or $ClientWrapper.Client.GetType() -ne "TelemetryClient") {
        $telemetryClient = $ClientWrapper.Client
    }

    try
    {
        $telemetryClient.Flush()
    }
    catch [System.Net.WebException]
    {
        Write-Log -Message "Encountered exception while trying to flush telemetry events:" -Exception $_ -Level Warning

        Set-TelemetryException -Exception ($_.Exception) -ErrorBucket "TelemetryFlush" -NoFlush -NoStatus:$NoStatus
    }
    catch
    {
        # Any other scenario is one that we want to identify and fix so that we don't miss telemetry
        Write-Log -Level Warning -Exception $_ -Message @(
            "Encountered a problem while trying to record telemetry events.",
            "This is non-fatal, but it would be helpful if you could report this problem",
            "to the PowerShellForGitHub team for further investigation:")
    }
}