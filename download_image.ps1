[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $imagesPath
)

$ErrorActionPreference = 'Stop';

Write-Host "Fetching UEFI images";

$images = @{
    'xps_15_9560_1.23.1.exe' = 'https://dl.dell.com/FOLDER07400651M/1/xps_15_9560_1.23.1.exe'
}

$images | ForEach-Object {
    $name = $_.Keys;
    $file = [IO.Path]::Combine($imagesPath, $name);
    if (-not [IO.File]::Exists($file)) {
        Write-Host "Download image $name";
        $download_url = $images[$name][0];
        Invoke-WebRequest -Uri $download_url -UseBasicParsing -Out $file;
    } else {
        Write-Host "Found image $name";
    }
}