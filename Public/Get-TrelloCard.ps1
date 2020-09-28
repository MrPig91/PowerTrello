function Get-TrelloCard {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ArgumentCompleter({
            param ($commandName,$parameterName,$wordToComplete,$commandAst,$fakeBoundParameters)
            Get-TrelloBoard -Name "*$wordToComplete*" | foreach {
                $ToolTip = "Name: $($_.Name)`nShortURL: $($_.ShortURL)`nLastView: $($_.dateLastView)"
                [System.Management.Automation.CompletionResult]::new($_.BoardId,$_.Name,"ParameterValue",$ToolTip)
            }
        })]
        [string]$BoardId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateNotNullOrEmpty()]
        [object]$List,
		
        [Parameter(ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Id')]
        [ValidateNotNullOrEmpty()]
        [string]$Id,
		
        [Parameter(ParameterSetName = 'Label')]
        [ValidateNotNullOrEmpty()]
        [string]$Label,
	
        [Parameter(ParameterSetName = 'Due')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Today', 'Tomorrow', 'In7Days', 'In14Days')]
        [string]$Due,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [switch]$IncludeArchived,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [switch]$IncludeAllActivity
    )
    begin {
        $ErrorActionPreference = 'Stop'
    }
    process {
        try {
            $filter = 'open'
            if ($IncludeArchived.IsPresent) {
                $filter = 'all'
            }
            $cards = Invoke-RestMethod -Uri "$script:baseUrl/boards/$BoardId/cards?customFieldItems=true&filter=$filter&$($trelloConfig.String)"
            $cards | Add-Member -TypeName "PowerTrello.Card"
            if ($PSBoundParameters.ContainsKey('Label')) {
                $cards = $cards | where { if (($_.labels) -and $_.labels.Name -contains $Label) { $true } }
            } elseif ($PSBoundParameters.ContainsKey('Due')) {
                Write-Warning -Message 'Due functionality is not complete.'
            } elseif ($PSBoundParameters.ContainsKey('Name')) {
                $cards = $cards | where { $_.Name -eq $Name }
            } elseif ($PSBoundParameters.ContainsKey('Id')) {
                $cards = $cards | where { $_.idShort -eq $Id }
            } elseif ($PSBoundParameters.ContainsKey('List')) {
                $cards = $cards | where { $_.idList -eq $List.id }
            }
            $Boards = Get-TrelloBoard

            $boardCustomFields = Get-TrelloCustomField -BoardId $BoardId
            foreach ($card in $cards) {
                if ($IncludeAllActivity.IsPresent) {
                    $card | Add-Member -NotePropertyName 'Activity' -NotePropertyValue (Get-TrelloCardAction -Card $_)
                }
                if ('customFieldItems' -in $card.PSObject.Properties.Name) {
                    $cFields = @()
                    $card.customFieldItems | foreach {
                        $cFields += ConvertToFriendlyCustomField -BoardId $BoardId -CustomFieldItem $_ -BoardCustomFields $boardCustomFields
                    }
                    $card | Add-Member -NotePropertyName 'CustomFields' -NotePropertyValue $cFields
                    $card | Add-Member -MemberType NoteProperty -Name BoardName -Value ($Boards | where Id -eq $card.idBoard).Name
                    $card | Add-Member -MemberType NoteProperty -Name ListName -Value (Get-TrelloList -ListId $card.idList).Name
                    if ($card.due){
                        $tDate = $card.due
                        $Date = Get-Date -Year $tdate.substring(0,4) -Month $tDate.Substring(5,2) -Day $tdate.SubString(8,2) -Hour $tDate.substring(11,2) -Minute $tDate.substring(14,2)
                        [datetime]$card.due = $Date 
                    }
                    $card
                }
            }
        } catch {
            Write-Error $_.Exception.Message
        }
    }
}