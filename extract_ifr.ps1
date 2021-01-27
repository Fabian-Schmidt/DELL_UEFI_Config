$ErrorActionPreference = 'Stop';


$toolsPath = [IO.Path]::Combine((Resolve-Path '.').Path, 'tools');
if(-not [IO.Directory]::Exists($toolsPath)) {
    [IO.Directory]::CreateDirectory($toolsPath) | Out-Null;
}
$tools = @{
    UEFIFind = [IO.Path]::Combine($toolsPath, 'UEFIFind.exe')
    UEFIExtract = [IO.Path]::Combine($toolsPath, 'UEFIExtract.exe')
    ifrextract = [IO.Path]::Combine($toolsPath, 'ifrextract.exe')
    Dell_PFS_Extract = [IO.Path]::Combine($toolsPath, 'Dell_PFS_Extract.exe')
};

$downloadTools = $false;
$tools.Values | ForEach-Object { 
    if (-not [IO.File]::Exists($_)) {$downloadTools = $true;} 
}

if($downloadTools) {
    Write-Host 'Download tools';
    . ./tools_download.ps1 -toolsPath $toolsPath;
} else {
    Write-Host 'Found tools';
}

$firmwareImage = Resolve-Path './images/xps_15_9560_1.21.0.exe';

echo '  [DELL Setup IFR Extrator]';
# Tool waits for user input. Now it is crashing.
Write-Host "" | . $tools.Dell_PFS_Extract $firmwareImage;
$firmwareImageExtract = Resolve-Path ($firmwareImage.Path + '_extracted');

$biosFile = Resolve-Path ([IO.Path]::Combine($firmwareImageExtract, '1 -- 1 System BIOS with BIOS Guard *'));

echo '  [UEFIFind]';
# Search for `System Language`+0x00 in Unicode.
$guid = . $tools.UEFIFind $biosFile body list 530079007300740065006D0020004C0061006E006700750061006700650000;

echo '  [UEFIExtract]';
$irfbinFolder = $firmwareImage.Path + '_ifr';
. $tools.UEFIExtract $biosFile $guid -o $irfbinFolder -m body -t 10;
$irfbinFile = Resolve-Path ([IO.Path]::Combine($irfbinFolder, 'body.bin'));

echo '  [ifrextract]';
$irfFile = $firmwareImage.Path + '.' + $guid + '.irf.txt';
. $tools.ifrextract $irfbinFile $irfFile;

