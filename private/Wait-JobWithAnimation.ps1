# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Wait-JobWithAnimation
{
<#
    .SYNOPSIS
        Waits for a background job to complete by showing a cursor and elapsed time.
    .DESCRIPTION
        Waits for a background job to complete by showing a cursor and elapsed time.
        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub
    .PARAMETER Name
        The name of the job(s) that we are waiting to complete.
    .PARAMETER Description
        The text displayed next to the spinning cursor, explaining what the job is doing.
    .PARAMETER StopAllOnAnyFailure
        Will call Stop-Job on any jobs still Running if any of the specified jobs entered
        the Failed state.
    .EXAMPLE
        Wait-JobWithAnimation Job1
        Waits for a job named "Job1" to exit the "Running" state.  While waiting, shows
        a waiting cursor and the elapsed time.
    .NOTES
        This is not a stand-in replacement for Wait-Job.  It does not provide the full
        set of configuration options that Wait-Job does.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string[]] $Name,

        [string] $Description = "",

        [switch] $StopAllOnAnyFailure
    )

    [System.Collections.ArrayList]$runningJobs = $Name
    $allJobsCompleted = $true
    $hasFailedJob = $false

    $animationFrames = '|','/','-','\'
    $framesPerSecond = 9

    # We'll wrap the description (if provided) in brackets for display purposes.
    if ($Description -ne "")
    {
        $Description = "[$Description]"
    }

    $iteration = 0
    while ($runningJobs.Count -gt 0)
    {
        # We'll run into issues if we try to modify the same collection we're iterating over
        $jobsToCheck = $runningJobs.ToArray()
        foreach ($jobName in $jobsToCheck)
        {
            $state = (Get-Job -Name $jobName).state
            if ($state -ne 'Running')
            {
                $runningJobs.Remove($jobName)

                if ($state -ne 'Completed')
                {
                    $allJobsCompleted = $false
                }

                if ($state -eq 'Failed')
                {
                    $hasFailedJob = $true
                    if ($StopAllOnAnyFailure)
                    {
                        break
                    }
                }
            }
        }

        if ($hasFailedJob -and $StopAllOnAnyFailure)
        {
            foreach ($jobName in $runningJobs)
            {
                Stop-Job -Name $jobName
            }

            $runingJobs.Clear()
        }

        Write-InteractiveHost "`r$($animationFrames[$($iteration % $($animationFrames.Length))])  Elapsed: $([int]($iteration / $framesPerSecond)) second(s) $Description" -NoNewline -f Yellow
        Start-Sleep -Milliseconds ([int](1000/$framesPerSecond))
        $iteration++
    }

    if ($allJobsCompleted)
    {
        Write-InteractiveHost "`rDONE - Operation took $([int]($iteration / $framesPerSecond)) second(s) $Description" -NoNewline -f Green

        # We forcibly set Verbose to false here since we don't need it printed to the screen, since we just did above -- we just need to log it.
        Write-Log -Message "DONE - Operation took $([int]($iteration / $framesPerSecond)) second(s) $Description" -Level Verbose -Verbose:$false
    }
    else
    {
        Write-InteractiveHost "`rDONE (FAILED) - Operation took $([int]($iteration / $framesPerSecond)) second(s) $Description" -NoNewline -f Red

        # We forcibly set Verbose to false here since we don't need it printed to the screen, since we just did above -- we just need to log it.
        Write-Log -Message "DONE (FAILED) - Operation took $([int]($iteration / $framesPerSecond)) second(s) $Description" -Level Verbose -Verbose:$false
    }

    Write-InteractiveHost ""
}