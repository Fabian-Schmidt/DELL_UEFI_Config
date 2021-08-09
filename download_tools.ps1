[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $toolsPath
)

$ErrorActionPreference = 'Stop';

# Need 7Zip to extract rar archive
Install-Module -Name 7Zip4Powershell -Scope CurrentUser;

$downloadPath = [IO.Path]::Combine($toolsPath, 'download');
if(-not [IO.Directory]::Exists($downloadPath)) {
    [IO.Directory]::CreateDirectory($downloadPath) | Out-Null;
}


$repo = 'LongSoft/UEFITool';
$UEFIFind = $null;
$UEFIExtract = $null;

$releases = (Invoke-WebRequest "https://api.github.com/repos/$repo/releases?per_page=5" -UseBasicParsing | ConvertFrom-Json);
$releases | ForEach-Object {
    $release = $_;
    if($null -eq $UEFIFind) {
        $UEFIFind = $release.assets | Where-Object name -match '^UEFIFind_.*_win32[.]zip$'
    }
    if($null -eq $UEFIExtract) {
        $UEFIExtract = $release.assets | Where-Object name -match '^UEFIExtract_.*_win32[.]zip$'
    }
}

if($null -eq $UEFIFind) {
    throw "Not found `UEFIFind` release in `https://github.com/$repo/releases`.";
}

if($null -eq $UEFIExtract) {
    throw "Not found `UEFIExtract` release in `https://github.com/$repo/releases`.";
}

$UEFIFindDownload = [IO.Path]::Combine($downloadPath, $UEFIFind.Name);
Invoke-WebRequest -Uri $UEFIFind.browser_download_url -UseBasicParsing -Out $UEFIFindDownload;
Expand-Archive -Path $UEFIFindDownload -DestinationPath $toolsPath -Force;

$UEFIExtractDownload = [IO.Path]::Combine($downloadPath, $UEFIExtract.Name);
Invoke-WebRequest -Uri $UEFIExtract.browser_download_url -UseBasicParsing -Out $UEFIExtractDownload;
Expand-Archive -Path $UEFIExtractDownload -DestinationPath $toolsPath -Force;



$repo = 'LongSoft/Universal-IFR-Extractor';
$ifrextract = $null;

$releases = (Invoke-WebRequest "https://api.github.com/repos/$repo/releases?per_page=5" -UseBasicParsing | ConvertFrom-Json);
$releases | ForEach-Object {
    $release = $_;
    if($null -eq $ifrextract) {
        $ifrextract = $release.assets | Where-Object name -match '^ifrextract_.*_win[.]zip$'
    }
}

if($null -eq $ifrextract) {
    throw "Not found `IRFExtractor` release in `https://github.com/$repo/releases`.";
}
$ifrextractDownload = [IO.Path]::Combine($downloadPath, $ifrextract.Name);
Invoke-WebRequest -Uri $ifrextract.browser_download_url -UseBasicParsing -Out $ifrextractDownload;
Expand-Archive -Path $ifrextractDownload -DestinationPath $toolsPath -Force;


$repo = 'platomav/BIOSUtilities';
$Dell_PFS_Extract = $null;

$releases = (Invoke-WebRequest "https://api.github.com/repos/$repo/releases?per_page=10" -UseBasicParsing | ConvertFrom-Json);
$releases | ForEach-Object {
    $release = $_;
    if($null -eq $Dell_PFS_Extract) {
        $Dell_PFS_Extract = $release.assets | Where-Object name -match '^Dell_PFS_Extract_v.*[.]rar$'
    }
}

if($null -eq $Dell_PFS_Extract) {
    throw "Not found `Dell_PFS_Extract` release in `https://github.com/$repo/releases`.";
}

$Dell_PFS_ExtractDownload = [IO.Path]::Combine($downloadPath, $Dell_PFS_Extract.Name);
Invoke-WebRequest -Uri $Dell_PFS_Extract.browser_download_url -UseBasicParsing -Out $Dell_PFS_ExtractDownload;
Expand-7Zip -ArchiveFileName $Dell_PFS_ExtractDownload -TargetPath $toolsPath;
