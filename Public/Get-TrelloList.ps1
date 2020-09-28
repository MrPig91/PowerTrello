function Get-TrelloList {
	[CmdletBinding(DefaultParameterSetName = "ByBoard")]
	param
	(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName,ParameterSetName = "ByBoard")]
		[ValidateNotNullOrEmpty()]
		[Alias('id')]
		[string]$BoardId,

		[Parameter(Mandatory,ParameterSetName = "ByID")]
		[string]$ListId
		
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try {
			if ($PSBoundParameters.ContainsKey("ListId")){
				Invoke-RestMethod -Uri "$script:baseUrl/lists/$($ListId)?$($trelloConfig.String)"
			}
			else{
				foreach ($list in (Invoke-RestMethod -Uri "$script:baseUrl/boards/$BoardId/lists?$($trelloConfig.String)")) {
					$list
				}
			}
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}