
$ErrorActionPreference = 'Stop';

$irfFiles = Resolve-Path './images/*.irf.txt';

$irfFile = $irfFiles[0];

Get-Content $irfFile | Foreach-Object {
    $line = $_;
    
}