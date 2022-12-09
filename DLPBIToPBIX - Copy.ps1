cls

##Import-MOdule DataGateway
$user = Connect-PowerBIServiceAccount 
$userName = $user.UserName 
 
Write-Host 
Write-Host "Now logged in as $userName" 


##MS
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$applictionId = "bc81b34d-b0a5-4d97-8bea-fe11bc8e105b"
$applicationSecret = "UIQ8Q~sld3KxDR8rw6ydGJvcE-YP~NGxbtoK6caz"

##PBI Champs
#$tenantId = "644d9875-54f6-4f5f-b562-2a14755779f7"
#$applictionId = "06ec6a02-60fd-4878-9d8b-52cb82d59577"
#$applicationSecret = "riT7Q~48gJ_ZGZxpexkjy8BAJ5UaDvA_Ny.iK"
##$applicationSecret = "8870d093-96a2-4553-b579-4a47eeb690c6" 
##id

$SecuredApplicationSecret = ConvertTo-SecureString -String $applicationSecret -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $applictionId, $SecuredApplicationSecret

#Disconnect-PowerBIServiceAccount
#$sp = Connect-PowerBIServiceAccount -Environment Public -ServicePrincipal  -Credential $credential -Tenant $tenantId
$AppId = $sp.UserName
$AppID


###### Begin Parameter
	$workspaceName = "pdetestemb" ##"PDE_Demos"
	$reportName = ""
	$scope="Individual" #Can be Organizational if you are admin
###### End Parameter


#you can remove -Name to recover all Workspace
Write-Host ""
Write-Host ""
Write-Host "Step1: Review all workspace"
$workspaces = Get-PowerBIWorkspace -name $workspaceName #-Scope $scope 

foreach($workspace in $workspaces){
    $workspaceId = $workspace.Id
	$reports = Get-PowerBIReport -WorkspaceID $workspace.Id
	
	##Get-PowerBIReport -WorkspaceID $workspace.Id
	foreach($report in $reports){
		$reportName = $report.Name
		$reportID = $report.Id
		Write-Host ""
		Write-Host ""
		Write-Host "Report $reportName in workspace $workspacename"
		
		
		
		$dlURL = "groups/$workspaceId/datasets/$reportID/Export"
		$dlURL
		
		Invoke-PowerBIRestMethod -Method Get -Url $dlURL

	}
}