function Get-TrelloBoard {
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param
	(
		[Parameter(ParameterSetName = 'ByName')]
		[ValidateNotNullOrEmpty()]
		[string[]]$Name,
		
		[Parameter(ParameterSetName = 'ById')]
		[ValidateNotNullOrEmpty()]
		[string[]]$Id,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$IncludeClosedBoards
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try {
			$invApiParams = @{
				QueryParameter = @{ }
			}
			if (-not $IncludeClosedBoards.IsPresent) {
				$invApiParams.QueryParameter.filter = 'open'
			}
			
			switch ($PSCmdlet.ParameterSetName) {
				'ByName' {
					$invApiParams.PathParameters = 'members/me/boards'
					foreach ($bName in $Name) {
						$boards = Invoke-PowerTrelloApiCall @invApiParams
						$boards = $boards | where { $_.name -like "$bName" } 
						$Boards | Add-Member -TypeName "PowerTrello.Board"
						$boards | Add-Member AliasProperty -Name BoardId -Value Id
						$Boards
					}
				}
				'ById' {
					foreach ($bId in $Id) {
						$invApiParams.PathParameters = "boards/$bId"
						$Boards = Invoke-PowerTrelloApiCall @invApiParams
						$Boards | Add-Member -TypeName "PowerTrello.Board"
						$boards | Add-Member AliasProperty -Name BoardId -Value Id
						$Boards
					}
				}
				default {
					$invApiParams.PathParameters = 'members/me/boards'
					$Boards = Invoke-PowerTrelloApiCall @invApiParams
					$Boards | Add-Member -TypeName "PowerTrello.Board"
					$boards | Add-Member AliasProperty -Name BoardId -Value Id
					$Boards
				}
			}
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}