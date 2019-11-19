function Decode-Win32 {
param(
    [Parameter(Mandatory=$true)][string]$inputfile,
    [Parameter(Mandatory=$true)][string]$outputfile
    )
$path = Split-Path $inputfile
$filename = Split-Path $inputfile -Leaf
Add-Type -AssemblyName "System.IO.Compression.Filesystem"
[System.IO.Compression.ZipFile]::ExtractToDirectory($inputfile, $path + "\temp\")
$xmlfile = $path + "\temp\IntuneWinPackage\Metadata\Detection.xml"
[xml]$xmldata = Get-Content $xmlfile
$enckey = $xmldata.ApplicationInfo.EncryptionInfo.EncryptionKey
$enckey = [System.Convert]::FromBase64String($enckey)
$iv = $xmldata.ApplicationInfo.EncryptionInfo.InitializationVector
$iv = [System.Convert]::FromBase64String($iv)
$encfile = $path + "\temp\IntuneWinPackage\Contents\" + $filename


[System.IO.FileStream]$FileStreamIn = [System.IO.FileStream]::new($encfile,[System.IO.FileMode]::Open)
[System.IO.FileStream]$FileStreamOut = [System.IO.FileStream]::new($outputfile,[System.IO.FileMode]::Create)

[System.Security.Cryptography.AesCryptoServiceProvider]$Aes =  [System.Security.Cryptography.AesCryptoServiceProvider]::new()
        $Aes.BlockSize = 128
        $Aes.KeySize = 256
        $Aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $Aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

[System.Security.Cryptography.ICryptoTransform]$ICryptoTransform = $Aes.CreateDecryptor($enckey,$iv)
[System.Security.Cryptography.CryptoStream]$CryptoStream = [System.Security.Cryptography.CryptoStream]::new($FileStreamIn, $ICryptoTransform, [System.Security.Cryptography.CryptoStreamMode]::Read)
 
$DataAvailable = $true
[int]$Data
      
        While ($DataAvailable)
        {
            
            $Data = $CryptoStream.ReadByte()
            if($Data -ne -1)
            {
                $FileStreamOut.WriteByte([byte]$Data)
            }
            else
            {
                $DataAvailable = $false
            }
        }
 
$FileStreamIn.Dispose()
$CryptoStream.Dispose()
$FileStreamOut.Dispose()

$temppath = $path + "/temp"
Remove-Item $temppath -Recurse
}

function Get-Win32App
{
param(
    [Parameter(Mandatory=$true)][string]$appid,
    [Parameter(Mandatory=$true)][string]$outputfolder
    )

$IntuneModule = Get-Module -Name "Microsoft.Graph.Intune" -ListAvailable
 if ($IntuneModule -eq $null) {
        write-host
        write-host "The module Microsoft.Graph.Intune is not installed..." -f Red
        write-host "Install by running the command 'Install-Module Microsoft.Graph.Intune' from  an elevated PowerShell prompt" -f Yellow
        write-host "The scriptet cannot continiue..." -f Red
        write-host
        exit
    }

Write-Progress -Activity "Kobler til Microsoft Graph..." -Status "..."
Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion beta
Connect-MSGraph

$url = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/" + $appid + "/microsoft.graph.win32LobApp/contentVersions/1/files/"
$fileid = (Invoke-MSGraphRequest -HttpMethod GET -Url $url -ErrorAction Stop).value[0].id
$url2 = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/" + $appid + "/microsoft.graph.win32LobApp/contentVersions/1/files/" + $fileid
$downloadurl = (Invoke-MSGraphRequest -HttpMethod GET -Url $url2 -ErrorAction Stop).azureStorageUri
$outputfile = $outputfolder + "\encrypted.intunewin"
Invoke-WebRequest -Uri $downloadurl -OutFile $outputfile
#File downloaded are encoded. Not found any way to decode yet.

}