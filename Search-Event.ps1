function Search-Event {
    Param(
        [Parameter(Mandatory=$False)]
        [string]$search="*",

        [Parameter(Mandatory=$False)]
        [string]$field=$null,

        [Parameter(Mandatory=$False)]
        [string]$value=$null,
		
	[Parameter(Mandatory=$False)]
        [int]$eventid=$null,
		
	[Parameter(Mandatory=$False)]
        [string]$logname,
        
        [Parameter(Mandatory=$False)]
        [datetime]$starttime,

        [Parameter(Mandatory=$False)]
        [datetime]$endtime,
		
	[Parameter(Mandatory=$False)]
        [switch]$raw=$False
    )

    $filter = @{
        logname=$logname;
    }
	
    if($eventid) {
	$filter['id'] = $eventid
    }

    if($starttime) {
        $filter['StartTime'] = $starttime
    }
    if($endtime) {
        $filter['EndTime'] = $starttime
    }

    $events = Get-WinEvent -FilterHashtable $filter -ErrorAction Continue | Where-Object { $_.Message -like "*$search*" }
	
	
    if($events.Length -gt 0) {
        [xml[]]$xmlevents = $events | % { $_.ToXml() }
        [PSCustomObject[]]$results = $null

		ForEach($xmlevent in $xmlevents) {
			$eventData = $xmlevent.Event.EventData.Data            
			$row = [PSCustomObject][ordered] @{
				TimeCreated=(get-date -date $xmlevent.Event.System.TimeCreated.SystemTime).ToString("MM/dd/yyyy hh:mm:ss tt")
				Id = $xmlevent.Event.System.EventId
			}
			foreach($ed in $eventData) {
				$row | Add-Member -NotePropertyName $ed.Name -NotePropertyvalue $ed."#text"
			}
            $row | Add-Member -NotePropertyName "xmlEvent" -NotePropertyValue $xmlevent
            $continue = $False
            if($field -and $value) {
                if($row.$field -like $value) {
                    $results += $row
                }
            }
            else {
                $results += $row
            }			
		}
		if($raw) {
			$results
		}
		else {
			$results | Out-GridView -Title "Search-Event Results"
		}
    }
    else {
        Write-Warning "No events were found that matched your search query."
    }
    
}
