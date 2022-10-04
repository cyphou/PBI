## Connection / ServicePrincipal for example## 
## ServicePrincipal or AAD User need to be Owner of the Gateway!!!
$tenantId = ""
$applictionId = ""
$applicationSecret = ""

$SecuredApplicationSecret = ConvertTo-SecureString -String $applicationSecret -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $applictionId, $SecuredApplicationSecret

#Disconnect-PowerBIServiceAccount
$sp = Connect-PowerBIServiceAccount  -ServicePrincipal  -Credential $credential -Tenant $tenantId
$AppId = $sp.UserName


#Recover last 30 days (max for the Preview API, one day for each API call)
$day=Get-date

for($s=0; $s -le 30; $s++)
{
    $periodStart=$day.AddDays(-$s)
    $base=$periodStart.ToString("yyyy-MM-dd")

    write-host "Recover $base logs"

    $a=Get-PowerBIActivityEvent -StartDateTime ($base+'T00:00:00.000') -EndDateTime ($base+'T23:59:59.999') -ActivityType 'AddUsersToGatewayClusterDatasource' -ResultType JsonString | ConvertFrom-Json
    $c=$a.Count

    for($i=0 ; $i -lt $c; $i++)
    {
        $r=$a[$i]
		$GatewayID = $r.GatewayClusterId
		$DataSourceID = $r.DataSourceId
		$UserID = $r.UserId
		
        Write-Host "Gateway ID: $($r.GatewayClusterId)"
                 ` "Data Source ID: $($r.DataSourceId)"
                 ` "From User: $($r.UserId)"
                 ` "Modification done on: $($r.CreationTime)"
                 ` "IsSuccess: $($r.IsSuccess) `n"
				 
		$datasourceUrl = "https://api.powerbi.com/v1.0/myorg/gateways/$($GatewayID)/datasources/$($DataSourceID)/users"
		$res = Invoke-PowerBIRestMethod -Method Get -Url $datasourceUrl | ConvertFrom-Json
		#$res.value	
		$totalUserToRemove = $res.value.count
		for($b=0;$b -lt $totalUserToRemove;$b++)
		{
			$UserToRemove = $res.value[$b]
			##$UserToRemove
			$EmailToRemove = $UserToRemove.emailAddress
			if($EmailToRemove -ne $UserID){
				write-host "Remove user $EmailToRemove from datasource $DataSourceID"
				$RemoveUserDSUrl="https://api.powerbi.com/v1.0/myorg/gateways/$($GatewayID)/datasources/$($DataSourceID)/users/$($EmailToRemove)"
				$RmUser = Invoke-PowerBIRestMethod -Method Delete -Url $RemoveUserDSUrl 
				
				
			}
		}
		
    }
}

