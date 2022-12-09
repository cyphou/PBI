cls

##Import-MOdule DataGateway



$user = Connect-PowerBIServiceAccount 
$userName = $user.UserName 
 
Write-Host 
Write-Host "Now logged in as $userName" 

###### Begin Parameter
	$workspaceName = "pdetestemb"
	$datasetName = "PBI - VNETGateway"

	#Old Connecting String to change => Need to replace by Oracle 
	$sqlDatabaseServerCurrent = "pdesql.database.windows.net"
	$sqlDatabaseNameCurrent ="mydb"
	
	# add new connection details for SQL datasource
	$dsname = "MyNewDS"
	$sqlDatabaseServer = "pdesql.database.windows.net"
	$sqlDatabaseName = "mydbtest" #old "mydb"
	$sqlUserName = "myuser"  
	$sqlUserPassword = "mypassword"  #Old
	$datasourceType="sql" #Can be replace by Oracle
	
	$scope="Individual" #Can be Organizational if you are admin
###### End Parameter


#you can remove -Name to recover all Workspace
Write-Host ""
Write-Host ""
Write-Host "Step1: Review all workspace"
$workspaces = Get-PowerBIWorkspace -name $workspaceName -Scope $scope

foreach($workspace in $workspaces){
    
	#Get All DS to changed accross workspace
	$datasets = Get-PowerBIDataset -WorkspaceId $workspace.Id | Foreach {$dsId = $_.Id; Get-PowerBIDatasource -DatasetId $dsId -Scope $scope -ErrorAction SilentlyContinue | Where-Object {$_.DatasourceType -eq $datasourceType -and ($_.ConnectionDetails.Server -like "*$sqlDatabaseServerCurrent*" -and $_.ConnectionDetails.Database -like "*$sqlDatabaseNameCurrent*")} | Foreach { $dsId }}
	$workspaceId = $workspace.Id
	$workspacename = $workspace.Name

	foreach($dataset in $datasets){
		Write-Host ""
		Write-Host ""
		Write-Host "Step2: Review dataset $dataset in workspace $workspacename"
		#Get DataSource link to the dataset
		$datasourceUrl = "groups/$workspaceId/datasets/$dataset/datasources"
		$datasourcesResult = Invoke-PowerBIRestMethod -Method Get -Url $datasourceUrl | ConvertFrom-Json
		
		
		# parse REST URL used to patch datasource credentials
		$datasource = $datasourcesResult.value[0]
		$gatewayId = $datasource.gatewayId
		$datasourceId = $datasource.datasourceId
		$datasourceName = $datasource.datasourceName

		
		$gatewaydsUrl = "gateways/$gatewayId/datasources/$datasourceId"
		# execute REST call to determine gateway Id, datasource Id and current connection details
		$gatewaydsResult = Invoke-PowerBIRestMethod -Method Get -Url $gatewaydsUrl | ConvertFrom-Json	
		
		
		$connectionDetails = $gatewaydsResult.connectionDetails
		$connectionDetailsJSon = $connectionDetails | ConvertFrom-Json
		$server = $connectionDetailsJSon.server
		$db = $connectionDetailsJSon.database
		
		#Test if the Gateway DS is up to date 
		if ($server -eq "$sqlDatabaseServerCurrent" -And $db -eq "$sqlDatabaseNameCurrent")
		{
			Write-Host ""
			Write-Host ""
			Write-Host "Step3: Need to remap to an another Gateway Datasource with the new connection string"
			## Test if the new gateway datasource exist or not
			$gatewayavailableUrl = "gateways/$gatewayId/datasources"
			
			$idtargetDataSource = "DefaultID"
			
			# execute REST call to determine gateway Id, datasource Id and current connection details
			$gatewaydsAvailables  = Invoke-PowerBIRestMethod -Method Get -Url $gatewayavailableUrl | ConvertFrom-Json	
						
			## List of DS available for the gateway
			foreach($gatewaydsAvailable in $gatewaydsAvailables.value){
				
				if($gatewaydsAvailable.connectionDetails -like "*$sqlDatabaseServer*" -And $gatewaydsAvailable.connectionDetails -like "*$sqlDatabaseName*")
				{
					$idtargetDataSource = $gatewaydsAvailable.id
					$nametargetDataSource = $gatewaydsAvailable.datasourceName
					Write-Host "===> Target DS available: $nametargetDataSource / $idtargetDataSource" 
				}
			}
						
			if ($idtargetDataSource -eq "DefaultID"){
				Write-Host "===> Target DS not found" 
			}else{
				## Now MAP the right Gateway Data Source to 
				Write-Host ""
				Write-Host ""
				Write-Host "Mapping to new data source"
					
					
					
				$datasourePatchUrl = "groups/$workspaceId/datasets/$dataset/Default.UpdateDatasources"
				# create HTTP request body to update datasource connection details
				$postBody = @{
				  "updateDetails" = @(
				   @{
					"connectionDetails" = @{
					  "server" = "$sqlDatabaseServer"
					  "database" = "$sqlDatabaseName"
					}
					"datasourceSelector" = @{
					  "datasourceType" = "Sql"
					  "connectionDetails" = @{
						"server" = "$sqlDatabaseServerCurrent"
						"database" = "$sqlDatabaseNameCurrent"
					  }
					  "gatewayId" = "$gatewayId"
					  "datasourceId" = "$idtargetDataSource"
					}
				  })
				}

				# convert body contents to JSON
				$postBodyJson = ConvertTo-Json -InputObject $postBody -Depth 6 -Compress

				# execute POST operation to update datasource connection details
				Invoke-PowerBIRestMethod -Method Post -Url $datasourePatchUrl -Body $postBodyJson	
			}			
		}else{
			
		Write-Host ""
		Write-Host ""
		Write-Host "Step3: Dataset $dataset OK"
			
		}
		
	}
}