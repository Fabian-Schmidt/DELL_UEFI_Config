$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

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
    Write-Verbose ". ./download_tools.ps1 -toolsPath $toolsPath";
    . ./download_tools.ps1 -toolsPath $toolsPath;
} else {
    Write-Host 'Found tools';
}

$imagesPath = [IO.Path]::Combine((Resolve-Path '.').Path, 'images');
if(-not [IO.Directory]::Exists($imagesPath)) {
    [IO.Directory]::CreateDirectory($imagesPath) | Out-Null;
}

Write-Verbose ". ./download_image.ps1 -imagesPath $imagesPath";
. ./download_image.ps1 -imagesPath $imagesPath;

$images = [IO.Directory]::GetFiles($imagesPath, '*.exe');
$images | ForEach-Object {
    $firmwareImage = $_;
    Write-Host $firmwareImage;

    echo '  [DELL Setup IFR Extrator]';
    Write-Verbose "$($tools.Dell_PFS_Extract) $firmwareImage";
    # Tool waits for user input.
    [System.Environment]::NewLine | . $tools.Dell_PFS_Extract $firmwareImage;
    echo ''; #Force linebreak
    $firmwareImageExtract = Resolve-Path ($firmwareImage + '_extracted');

    $biosFile = Resolve-Path ([IO.Path]::Combine($firmwareImageExtract, '1 -- 1 System BIOS with BIOS Guard *'));

    echo '  [UEFIFind]';
    Write-Verbose "$($tools.UEFIFind) $biosFile body list 530079007300740065006D0020004C0061006E006700750061006700650000";
    # Search for `System Language`+0x00 in Unicode.
    $guid = . $tools.UEFIFind $biosFile body list 530079007300740065006D0020004C0061006E006700750061006700650000;

    echo '  [UEFIExtract]';
    $irfbinFolder = $firmwareImage + '_ifr';
    Write-Verbose "$($tools.UEFIExtract) $biosFile $guid -o $irfbinFolder -m body -t 10";
    . $tools.UEFIExtract $biosFile $guid -o $irfbinFolder -m body -t 10;
    $irfbinFile = Resolve-Path ([IO.Path]::Combine($irfbinFolder, 'body.bin'));

    echo '  [ifrextract]';
    $irfFile = $firmwareImage + '.' + $guid + '.irf.txt';
    Write-Verbose "$($tools.ifrextract) $irfbinFile $irfFile";
    . $tools.ifrextract $irfbinFile $irfFile;

    echo '  Build grub.cfg'
    $grubFile = $firmwareImage + '.grub.cfg';
    Write-Verbose "./build_grubmenu.ps1 -irfFile $irfFile -grubFile $grubFile";
    . ./build_grubmenu.ps1 -irfFile $irfFile -grubFile $grubFile
}