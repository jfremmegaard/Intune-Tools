$upn = 'MeganB@M365x091570.OnMicrosoft.com'
Connect-AzureAD
$userid = (Get-AzureADUser -ObjectId $upn).ObjectId

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

$url = "https://main.iam.ad.ext.azure.com/api/UserDetails/" + $userid
$imageurl = (Invoke-RestMethod –Uri $url –Headers $header –Method GET -Body $content -ErrorAction Stop).imageUrl
Write-Host $imageurl