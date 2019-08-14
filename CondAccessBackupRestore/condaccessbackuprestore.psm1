<#
 .Synopsis
  Backup and restore Intune Conditional Access Policies

 .Description
  Backup and restore Intune Conditional Access Policies

 .Parameter backupfolder
  The path to save the backup files to

 .Parameter importfile
  The file with the policy you want to import to Intune

 .Example
   # Backup policies
   Backup-CondAcc -backupfolder c:\temp

 .Example
   # Restore a policy
   Restore-CondAcc -importfile c:\temp\policy.xml

#>

#region Backup

function Backup-CondAcc {
param(
    [Parameter(Mandatory=$true)][string]$backupfolder
    )
#region Authentication

login-azurermaccount
$context = Get-AzureRmContext
$tenantId = $context.Tenant.Id
$refreshToken = $context.TokenCache.ReadItems().RefreshToken
$body = "grant_type=refresh_token&refresh_token=$($refreshToken)&resource=74658136-14ec-4630-ad9b-26e160ff0fc6"
$apiToken = Invoke-RestMethod "https://login.windows.net/$tenantId/oauth2/token" -Method POST -Body $body -ContentType 'application/x-www-form-urlencoded'
 
$header = @{
'Authorization' = 'Bearer ' + $apiToken.access_token
'Content-Type' = 'application/json'
    'X-Requested-With'= 'XMLHttpRequest'
    'x-ms-client-request-id'= [guid]::NewGuid()
    'x-ms-correlation-id' = [guid]::NewGuid()
    }

#endregion

$url = "https://main.iam.ad.ext.azure.com/api/Policies/Policies?top=50&nextLink=null&appId=&includeBaseline=false"
$policies = Invoke-RestMethod –Uri $url –Headers $header –Method GET -ErrorAction Stop

foreach($policy in $policies.items)
{
    $url = "https://main.iam.ad.ext.azure.com/api/Policies/" + $policy.policyId + ""
    $exportpolicy = Invoke-RestMethod –Uri $url –Headers $header –Method GET -ErrorAction Stop
    $exportfile = $backupfolder + $policy.policyName + ".xml"
    $exportpolicy | Export-Clixml $exportfile
}
}
#endregion

#region Restore

function Restore-CondAcc {
param(
    [Parameter(Mandatory=$true)][string]$importfile
    )
#region Authentication

login-azurermaccount
$context = Get-AzureRmContext
$tenantId = $context.Tenant.Id
$refreshToken = $context.TokenCache.ReadItems().RefreshToken
$body = "grant_type=refresh_token&refresh_token=$($refreshToken)&resource=74658136-14ec-4630-ad9b-26e160ff0fc6"
$apiToken = Invoke-RestMethod "https://login.windows.net/$tenantId/oauth2/token" -Method POST -Body $body -ContentType 'application/x-www-form-urlencoded'
 
$header = @{
'Authorization' = 'Bearer ' + $apiToken.access_token
'Content-Type' = 'application/json'
    'X-Requested-With'= 'XMLHttpRequest'
    'x-ms-client-request-id'= [guid]::NewGuid()
    'x-ms-correlation-id' = [guid]::NewGuid()
    }

#endregion
$policy = Import-Clixml $importfile
#region array to string fix
if ($policy.conditions.namedNetworks.includedNetworkIds -gt 0)
{
    $includedNetworkIds = '["' + ($policy.conditions.namedNetworks.includedNetworkIds -join "`",`"") + '"]'
}
else
{
    $includedNetworkIds = "[]"
}
if ($policy.conditions.namedNetworks.excludedNetworkIds -gt 0)
{
    $excludedNetworkIds = '["' + ($policy.conditions.namedNetworks.excludedNetworkIds -join "`",`"") + '"]'
}
else
{
    $excludedNetworkIds = "[]"
}
if ($policy.controls.claimProviderControlIds -gt 0)
{
    $claimProviderControlIds = '["' + ($policy.controls.claimProviderControlIds -join "`",`"") + '"]'
}
else
{
    $claimProviderControlIds = "[]"
}
if ($policy.usersV2.included.userIds -gt 0)
{
    $includeduserIds = '["' + ($policy.usersV2.included.userIds -join "`",`"") + '"]'
}
else
{
    $includeduserIds = "[]"
}
if ($policy.usersV2.included.groupIds -gt 0)
{
    $includedgroupIds = '["' + ($policy.usersV2.included.groupIds -join "`",`"") + '"]'
}
else
{
    $includedgroupIds = "[]"
}
if ($policy.usersV2.excluded.userIds -gt 0)
{
    $excludeduserIds = '["' + ($policy.usersV2.excluded.userIds -join "`",`"") + '"]'
}
else
{
    $excludeduserIds = "[]"
}
if ($policy.usersV2.excluded.groupIds -gt 0)
{
    $excludedgroupIds = '["' + ($policy.usersV2.excluded.groupIds -join "`",`"") + '"]'
}
else
{
    $excludedgroupIds = "[]"
}
if ($policy.servicePrincipals.included.ids -gt 0)
{
    $spincludedids = '["' + ($policy.servicePrincipals.included.ids -join "`",`"") + '"]'
}
else
{
    $spincludedids = "[]"
}
if ($policy.servicePrincipals.excluded.ids -gt 0)
{
    $spexcludedids = '["' + ($policy.servicePrincipals.excluded.ids -join "`",`"") + '"]'
}
else
{
    $spexcluidedids = "[]"
}
#endregion
$content = '{"policyState":' + $policy.policyState + ',"usePolicyState":' + $policy.usePolicyState.ToString().ToLower() + ',"policyId":"","policyName":"' + $policy.policyName + '","conditions":{"minSigninRisk":{"applyCondition":' + $policy.conditions.minSigninRisk.applyCondition.ToString().ToLower() + ',"highRisk":' + $policy.conditions.minSigninRisk.highRisk.ToString().ToLower() + ',"mediumRisk":' + $policy.conditions.minSigninRisk.mediumRisk.ToString().ToLower() + ',"lowRisk":' + $policy.conditions.minSigninRisk.lowRisk.ToString().ToLower() + ',"noRisk":' + $policy.conditions.minSigninRisk.noRisk.ToString().ToLower() + '},"devicePlatforms":{"applyCondition":' + $policy.conditions.devicePlatforms.applyCondition.ToString().ToLower() + ',"all":' + $policy.conditions.devicePlatforms.all + ',"included":{"android":' + $policy.conditions.devicePlatforms.included.android.ToString().ToLower() + ',"ios":' + $policy.conditions.devicePlatforms.included.ios.ToString().ToLower() + ',"windows":' + $policy.conditions.devicePlatforms.included.windows.ToString().ToLower() + ',"windowsPhone":' + $policy.conditions.devicePlatforms.included.windowsPhone.ToString().ToLower() + ',"macOs":' + $policy.conditions.devicePlatforms.included.macOs.ToString().ToLower() + '},"excluded":{"android":' + $policy.conditions.devicePlatforms.excluded.android.ToString().ToLower() + ',"ios":' + $policy.conditions.devicePlatforms.excluded.ios.ToString().ToLower() + ',"windows":' + $policy.conditions.devicePlatforms.excluded.windows.ToString().ToLower() + ',"windowsPhone":' + $policy.conditions.devicePlatforms.excluded.windowsPhone.ToString().ToLower() + ',"macOs":' + $policy.conditions.devicePlatforms.excluded.macOs.ToString().ToLower() + '}},"locations":{"applyCondition":' + $policy.conditions.locations.applyCondition.ToString().ToLower() + ',"includeLocationType":' + $policy.conditions.locations.includeLocationType + ',"excludeAllTrusted":' + $policy.conditions.locations.excludeAllTrusted.ToString().ToLower() + '},"namedNetworks":{"applyCondition":' + $policy.conditions.namedNetworks.applyCondition.ToString().ToLower() + ',"includeLocationType":' + $policy.conditions.namedNetworks.includeLocationType + ',"includeTrustedIps":' + $policy.conditions.namedNetworks.includeTrustedIps.ToString().ToLower() + ',"excludeTrustedIps":' + $policy.conditions.namedNetworks.excludeTrustedIps.ToString().ToLower() + ',"includeCorpnet":' + $policy.conditions.namedNetworks.includeCorpnet.ToString().ToLower() + ',"excludeCorpnet":' + $policy.conditions.namedNetworks.excludeCorpnet.ToString().ToLower() + ',"includedNetworkIds":' + $includedNetworkIds + ',"excludedNetworkIds":' + $excludedNetworkIds + ',"excludeLocationType":' + $policy.conditions.namedNetworks.excludeLocationType + '},"clientApps":{"applyCondition":' + $policy.conditions.clientApps.applyCondition.ToString().ToLower() + ',"webBrowsers":' + $policy.conditions.clientApps.webBrowsers.ToString().ToLower() + ',"onlyAllowSupportedPlatforms":' + $policy.conditions.clientApps.onlyAllowSupportedPlatforms.ToString().ToLower() + ',"mobileDesktop":' + $policy.conditions.clientApps.mobileDesktop.ToString().ToLower() + ',"exchangeActiveSync":' + $policy.conditions.clientApps.exchangeActiveSync.ToString().ToLower() + ',"specificClientApps":' + $policy.conditions.clientApps.specificClientApps.ToString().ToLower() + '},"clientAppsV2":{"applyCondition":' + $policy.conditions.clientAppsV2.applyCondition.ToString().ToLower() + ',"exchangeActiveSync":' + $policy.conditions.clientAppsV2.exchangeActiveSync.ToString().ToLower() + ',"mobileDesktop":' + $policy.conditions.clientAppsV2.mobileDesktop.ToString().ToLower() + ',"onlyAllowSupportedPlatforms":' + $policy.conditions.clientAppsV2.onlyAllowSupportedPlatforms.ToString().ToLower() + ',"webBrowsers":' + $policy.conditions.clientAppsV2.webBrowsers.ToString().ToLower() + ',"modernAuth":' + $policy.conditions.clientAppsV2.modernAuth.ToString().ToLower() + ',"otherClients":' + $policy.conditions.clientAppsV2.otherClients.ToString().ToLower() + '},"time":{"applyCondition":' + $policy.conditions.time.applyCondition.ToString().ToLower() + ',"all":' + $policy.conditions.time.all + ',"included":{"dateRange":{"startDateTime":"2019-6-20 0:0:0","endDateTime":"2019-6-21 0:0:0"},"daysOfWeek":{"allDay":' + $policy.conditions.time.included.daysOfWeek.allDay.ToString().ToLower() + ',"day":[0,1,2,3,4,5,6],"startTime":"2019-6-20 0:0:0","endTime":"2019-6-21 0:0:0"},"timezoneId":"","type":' + $policy.conditions.time.included.type + ',"isExcludeSet":' + $policy.conditions.time.included.isExcludeSet.ToString().ToLower() + '},"excluded":{"dateRange":{"startDateTime":"2019-6-20 0:0:0","endDateTime":"2019-6-21 0:0:0"},"daysOfWeek":{"allDay":' + $policy.conditions.time.excluded.daysOfWeek.allDay.ToString().ToLower() + ',"day":[0,1,2,3,4,5,6],"startTime":"2019-6-20 0:0:0","endTime":"2019-6-21 0:0:0"},"timezoneId":"","type":' + $policy.conditions.time.excluded.type + ',"isExcludeSet":' + $policy.conditions.time.excluded.isExcludeSet.ToString().ToLower() + '}},"deviceState":{"applyCondition":' + $policy.conditions.deviceState.applyCondition.ToString().ToLower() + ',"includeDeviceStateType":' + $policy.conditions.deviceState.includeDeviceStateType + ',"excludeCompliantDevice":' + $policy.conditions.deviceState.excludeCompliantDevice.ToString().ToLower() + ',"excludeDomainJoionedDevice":' + $policy.conditions.deviceState.excludeDomainJoionedDevice.ToString().ToLower() + '}},"controls":{"blockAccess":' + $policy.controls.blockAccess.ToString().ToLower() + ',"challengeWithMfa":' + $policy.controls.challengeWithMfa.ToString().ToLower() + ',"compliantDevice":' + $policy.controls.compliantDevice.ToString().ToLower() + ',"domainJoinedDevice":' + $policy.controls.domainJoinedDevice.ToString().ToLower() + ',"approvedClientApp":' + $policy.controls.approvedClientApp.ToString().ToLower() + ',"requireCompliantApp":' + $policy.controls.requireCompliantApp.ToString().ToLower() + ',"requiredFederatedAuthMethod":' + $policy.controls.requiredFederatedAuthMethod + ',"controlsOr":' + $policy.controls.controlsOr.ToString().ToLower() + ',"claimProviderControlIds":' + $claimProviderControlIds + '},"users":null,"usersV2":{"allUsers":' + $policy.usersV2.allUsers + ',"included":{"userIds":' + $includeduserIds + ',"groupIds":' + $includedgroupIds + ',"allGuestUsers":' + $policy.usersV2.included.allGuestUsers.ToString().ToLower() + ',"roleIds":[],"roles":' + $policy.usersV2.included.roles.ToString().ToLower() + ',"usersGroups":' + $policy.usersV2.included.usersGroups.ToString().ToLower() + '},"excluded":{"userIds":' + $excludeduserIds + ',"groupIds":' + $excludedgroupIds + ',"allGuestUsers":' + $policy.usersV2.excluded.allGuestUsers.ToString().ToLower() + ',"roleIds":[],"roles":' + $policy.usersV2.excluded.roles.ToString().ToLower() + ',"usersGroups":' + $policy.usersV2.excluded.usersGroups.ToString().ToLower() + '}},"servicePrincipalsV2":null,"sessionControls":null,"servicePrincipals":{"allServicePrincipals":' + $policy.servicePrincipals.allServicePrincipals + ',"included":{"ids":' + $spincludedids + '},"excluded":{"ids":' + $spexcludedids + '},"includeAllMicrosoftApps":' + $policy.servicePrincipals.includeAllMicrosoftApps.ToString().ToLower() + ',"excludeAllMicrosoftApps":' + $policy.servicePrincipals.excludeAllMicrosoftApps.ToString().ToLower() + ',"userActions":[]},"isAllProtocolsEnabled":true,"isUsersGroupsV2Enabled":' + $policy.isUsersGroupsV2Enabled.ToString().ToLower() + ',"isCloudAppsV2Enabled": ' + $policy.isCloudAppsV2Enabled.ToString().ToLower() + '}'

$url = "https://main.iam.ad.ext.azure.com/api/Policies"
Invoke-RestMethod –Uri $url –Headers $header –Method POST -Body $content -ErrorAction Stop
}
#endregion