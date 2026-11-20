function Get-LDEvents {
    <#
    .SYNOPSIS
        Fetches event data from a ScrapedDuck JSON endpoint.
    .DESCRIPTION
        This function retrieves event information from the ScrapedDuck JSON endpoint and returns it as a PowerShell object.
    .PARAMETER Uri
        The URI of the REST API endpoint from which to fetch events.
    #>
    $eventsUri = "https://raw.githubusercontent.com/bigfoott/ScrapedDuck/data/events.json"

    try {
        $events = Invoke-RestMethod -Uri $eventsUri -ErrorAction Stop
        return $events
    }
    catch {
        Write-Error "Failed to fetch events: $_"
        return $null
    }
}

function Get-LDEventTable {
    # Build table of events
    $eventTable = @()
    $objEvents = Get-LDEvents

    foreach ($event in $objEvents) {
        # Parse start/end strings into DateTime objects when possible
        $startDt = $null
        $endDt = $null

        if ($null -ne $event.start -and $event.start -ne '') {
            try {
                $startDt = [datetime]$event.start
            }
            catch {
                $startDt = $null
            }
        }

        if ($null -ne $event.end -and $event.end -ne '') {
            try {
                $endDt = [datetime]$event.end
            }
            catch {
                $endDt = $null
            }
        }

        $eventTable += [PSCustomObject]@{
            Name       = $event.name
            StartDate  = $startDt
            EndDate    = $endDt
            Type       = $event.eventtype
            Image      = $event.image
            Url        = $event.link
        }
    }

    # Display the table
    $eventTable | Format-Table -AutoSize
}