param (
$serverName = "powerbi://api.powerbi.com/v1.0/myorg/YOURWORKSPACE"
, $databaseName = "YOURDATASET"
, $years = (2015..2017)
)
$ErrorActionPreference = "Stop"

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition -Parent)

Import-Module "$currentPath\TOMHelper.psm1" -Force
			 
$partitions = "{   
  ""sequence"":    
    {   
      ""maxParallelism"": 3,   
      ""operations"": [   "

foreach ($year in $years)
{
    foreach($month in @(1..12))
    {        
		$yearmonth = "$($year)$($month.ToString("D2"))"
        $partitions += "{""createOrReplace"": {
			""object"": {
			  ""database"": ""PBI_ADB"",
			  ""table"": ""user_logs"",
			  ""partition"": ""$yearmonth""
			},
			""partition"": 
			{
			  ""name"": ""$yearmonth"",
			  ""source"": {
				""type"": ""m"",
				""expression"": [
				  ""let\r"",
				  ""    Source = Value.NativeQuery(Databricks.Catalogs(\""YOURDB.azuredatabricks.net\"", \""/sql/1.0/warehouses/67d4a124df53e621\"", [Catalog=\""hive_metastore\"", Database=null, EnableAutomaticProxyDiscovery=null]){[Name=\""hive_metastore\"",Kind=\""Database\""]}[Data], \""select * from kkbox.user_logs_partition_yearmonth WHERE yearmonth = $yearmonth\"", null, [EnableFolding=true])\r"",
				  ""in\r"",
				  ""Source""
				]
			  }
		}
		}},
		"
    }
}
$partitions = $partitions.Remove($partitions.Length - 1)
$partitions += "]}}"
$partitions | Out-File -FilePath ".\Create_Partition.xmla"