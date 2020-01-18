# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Set-TelemetryException
{
<#
    .SYNOPSIS
        Posts a new telemetry event to the configured Application Insights instance indicating
        that an exception occurred in this this module.

    .DESCRIPTION
        Posts a new telemetry event to the configured Application Insights instance indicating
        that an exception occurred in this this module.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Exception
        The exception that just occurred.

    .PARAMETER ErrorBucket
        A property to be added to the Exception being logged to make it easier to filter to
        exceptions resulting from similar scenarios.

    .PARAMETER Properties
        Additional properties that the caller may wish to be associated with this exception.

    .PARAMETER NoFlush
        It's not recommended to use this unless the exception is coming from Clear-TelemetryClient.
        By default, every time a new exception is logged, the telemetry client will be flushed
        to ensure that the event is published to the Application Insights.  Use of this switch
        prevents that automatic flushing (helpful in the scenario where the exception occurred
        when trying to do the actual Flush).

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Set-TelemetryException $_

        Used within the context of a catch statement, this will post the exception that just
        occurred, along with a default set of properties.  If the telemetry client needs to be
        created to accomplish this, and the required assemblies are not available on the local
        machine, the download status will be presented at the command prompt.

    .EXAMPLE
        Set-TelemetryException $_ -NoStatus

        Used within the context of a catch statement, this will post the exception that just
        occurred, along with a default set of properties.  If the telemetry client needs to be
        created to accomplish this, and the required assemblies are not available on the local
        machine, the command prompt will appear to hang while they are downloaded.

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
        [System.Exception] $Exception,

        [string] $ErrorBucket,

        [hashtable] $Properties = @{},

        [switch] $NoFlush,

        [switch] $NoStatus
    )

    if (Get-GitHubConfiguration -Name DisableTelemetry)
    {
        Write-Log -Message "Telemetry has been disabled via configuration. Skipping reporting exception." -Level Verbose
        return
    }

    Write-InvocationLog -ExcludeParameter @('Exception', 'Properties', 'NoFlush')

    if($null -eq $ClientWrapper.Client) {
        Write-Log -Message "ClientWrapper.Client is null. ClientWrapper should be regenerated using Get-TelemetryClient." -Level Error
        return
    }

    try
    {
        $telemetryClient = $ClientWrapper.Client

        $propertiesDictionary = New-Object 'System.Collections.Generic.Dictionary[string,string]'
        $propertiesDictionary['Message'] = $Exception.Message
        $propertiesDictionary['HResult'] = "0x{0}" -f [Convert]::ToString($Exception.HResult, 16)
        $Properties.Keys | ForEach-Object { $propertiesDictionary[$_] = $Properties[$_] }

        if (-not [String]::IsNullOrWhiteSpace($ErrorBucket))
        {
            $propertiesDictionary['ErrorBucket'] = $ErrorBucket
        }

        $telemetryClient.TrackException($Exception, $propertiesDictionary);

        # Flushing should increase the chance of success in uploading telemetry logs
        if (-not $NoFlush)
        {
            Clear-TelemetryClient -ClientWrapper $ClientWrapper -NoStatus:$NoStatus
        }
    }
    catch
    {
        # Telemetry should be best-effort.  Failures while trying to handle telemetry should not
        # cause exceptions in the app itself.
        Write-Log -Message "Set-TelemetryException failed:" -Exception $_ -Level Error
    }
}