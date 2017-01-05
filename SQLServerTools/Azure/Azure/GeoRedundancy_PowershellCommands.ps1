# Azure SQL Db Geo Replication Commands
Login-AzureRmAccount #blah blah blah

# Select Subscription
Select-AzureRmSubscription -SubscriptionId fdfecc8b-3da2-4f4e-b4cf-ad1699b5686b

# Create Non-Readible Secondary Database
$database = Get-AzureRmSqlDatabase –DatabaseName "SGNL_ANALYTICS_MIRROR" -ResourceGroupName "Azure_SqlServer_Dev" -ServerName "analytics-dev"
$secondaryLink = $database | New-AzureRmSqlDatabaseSecondary –PartnerResourceGroupName "Azure_SqlServer_Dev" –PartnerServerName "analytics-dev-b" -AllowConnections "No"

# Create Readible Secondary Database
$database = Get-AzureRmSqlDatabase –DatabaseName "SGNL_ANALYTICS_MIRROR" -ResourceGroupName "Azure_SqlServer_Dev" -ServerName "analytics-dev"
$secondaryLink = $database | New-AzureRmSqlDatabaseSecondary –PartnerResourceGroupName "Azure_SqlServer_Dev" –PartnerServerName "analytics-dev-b" -AllowConnections "All"

# Get health & performance of Geo-Redundant Db's
$database = Get-AzureRmSqlDatabase –DatabaseName "SGNL_ANALYTICS_MIRROR" -ResourceGroupName "Azure_SqlServer_Dev" -ServerName "analytics-dev"
$secondaryLink = $database | Get-AzureRmSqlDatabaseReplicationLink –PartnerResourceGroup "Azure_SqlServer_Dev” –PartnerServerName "analytics-dev-b”

# Initiate a planned failover
#     Use the Set-AzureRmSqlDatabaseSecondary cmdlet with the -Failover parameter to promote a secondary database to become the new primary database, demoting the existing primary to become a secondary. This functionality is designed for a planned failover, such as during disaster recovery drills, and requires that the primary database be available.
#     The command performs the following workflow:
#         1.Temporarily switch replication to synchronous mode. This will cause all outstanding transactions to be flushed to the secondary.
#         2.Switch the roles of the two databases in the Geo-Replication partnership. 
#     This sequence guarantees that the two databases are synchronized before the roles switch and therefore no data loss will occur. There is a short period during which both databases are unavailable (on the order of 0 to 25 seconds) while the roles are switched. The entire operation should take less than a minute to complete under normal circumstances. For more information, see Set-AzureRmSqlDatabaseSecondary.
$database = Get-AzureRmSqlDatabase –DatabaseName "SGNL_ANALYTICS_MIRROR" –ResourceGroupName "Azure_SqlServer_Dev” –ServerName "analytics-dev-b”
$database | Set-AzureRmSqlDatabaseSecondary -Failover

#     Initiate an unplanned failover from the primary database to the secondary database
#         You can use the Set-AzureRmSqlDatabaseSecondary cmdlet with –Failover and -AllowDataLoss parameters to promote a secondary database to become the new primary database in an unplanned fashion, forcing the demotion of the existing primary to become a secondary at a time when the primary database is no longer available.
#     This functionality is designed for disaster recovery when restoring availability of the database is critical and some data loss is acceptable. When forced failover is invoked, the specified secondary database immediately becomes the primary database and begins accepting write transactions. As soon as the original primary database is able to reconnect with this new primary database after the forced failover operation, an incremental backup is taken on the original primary database and the old primary database is made into a secondary database for the new primary database; subsequently, it is merely a replica of the new primary.
#         because Point In Time Restore is not supported on secondary databases, if you wish to recovery data committed to the old primary database which had not been replicated to the new primary database, you should engage CSS to restore a database to the known log backup.
$database = Get-AzureRmSqlDatabase –DatabaseName "SGNL_ANALYTICS_MIRROR" –ResourceGroupName "Azure_SqlServer_Dev” –ServerName "analytics-dev-b”
$database | Set-AzureRmSqlDatabaseSecondary –Failover -AllowDataLoss

# Create Server Firewall Rule
New-AzureRmSqlServerFirewallRule -ResourceGroupName 'Azure_SqlServer_Dev' -ServerName 'analytics-dev-b' -FirewallRuleName "ContosoFirewallRule" -StartIpAddress '192.168.1.1' -EndIpAddress '192.168.1.10'
# Modify Server Firewall Rule
Set-AzureRmSqlServerFirewallRule -ResourceGroupName 'Azure_SqlServer_Dev' –StartIPAddress 192.168.1.4 –EndIPAddress 192.168.1.10 –RuleName 'ContosoFirewallRule' –ServerName 'analytics-dev-b'
# Get Server Firewall Rules
Get-AzureRmSqlServerFirewallRule -ResourceGroupName "Azure_SqlServer_Dev" -ServerName "analytics-dev-b"
# Remove Server Firewall Rule
Remove-AzureRmSqlServerFirewallRule –RuleName 'ContosoFirewallRule' –ServerName 'analytics-dev-b'
