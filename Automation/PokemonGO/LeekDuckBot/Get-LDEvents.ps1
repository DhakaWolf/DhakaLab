#region Variables
$eventsUri = "https://raw.githubusercontent.com/bigfoott/ScrapedDuck/data/events.json"
#endregion

#region Functions
function Get-LDEvents {
    param (
        [string]$Uri
    )

    try {
        $events = Invoke-RestMethod -Uri $Uri -ErrorAction Stop
        return $events
    }
    catch {
        Write-Error "Failed to fetch events: $_"
        return $null
    }
}

#endregion

#region Main
# Build table of events
$eventTable = @()
$objEvents = Get-LDEvents -Uri $eventsUri

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

#endregion