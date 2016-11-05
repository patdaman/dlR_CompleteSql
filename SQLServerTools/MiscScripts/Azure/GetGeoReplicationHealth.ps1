# Azure SQL Db Geo Replication Commands
Login-AzureRmAccount #blah blah blah

# Select Subscription
Select-AzureRmSubscription -SubscriptionId fdfecc8b-3da2-4f4e-b4cf-ad1699b5686b

# Get health & performance of Geo-Redundant Db's
$database = Get-AzureRmSqlDatabase –DatabaseName "SGNL_ANALYTICS_MIRROR" -ResourceGroupName "Azure_SqlServer_Dev" -ServerName "analytics-dev"
$secondaryLink = $database | Get-AzureRmSqlDatabaseReplicationLink –PartnerResourceGroup "Azure_SqlServer_Dev” –PartnerServerName "analytics-dev-b”

