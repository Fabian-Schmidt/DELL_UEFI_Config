[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $irfFile,

    [Parameter()]
    [string]
    $grubFile
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop;

$grub = [System.Text.StringBuilder]::new();
$formSetName = "";
$formName = "";
$formId = "";
$formEntries = 0;
$option = "";
$optionName = "";
$optionVarOffset = "";
$optionVarStore = "";

Get-Content $irfFile | Foreach-Object {
    $line = $_;    
    $lineHandeld = $false;

    $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*Form Set: (.*),';
    if($regex.Matches) {
        $lineHandeld = $true;
        $formSetName = $regex.Matches.Groups[1].Captures[0].Value;
        Write-Verbose "formSetName: $formSetName";
        $formEntries = 0;
    }

    if(-not $lineHandeld) {
        $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*Form: (.*), FormId: 0x([0-9A-F]*)';
        if($regex.Matches) {
            $lineHandeld = $true;
            $formName = $regex.Matches.Groups[1].Captures[0].Value;
            $formId = $regex.Matches.Groups[2].Captures[0].Value;
            Write-Verbose "formSetName: $formSetName, formName: $formName, formId: $formId";
            [void]$grub.AppendLine("submenu ""$($formName.Replace('"', '')) (0x$formId)"" {");
        }
    }
    if(-not $lineHandeld) {
        $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*End Form {';
        if($regex.Matches) {
            $lineHandeld = $true;
            $formName = '';
            $formId = '';
            [void]$grub.AppendLine("}");
        }
    }

    # 'One Of'
    if(-not $lineHandeld) {
        $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*One Of: ([^,]*), VarStoreInfo \(VarOffset/VarName\): 0x([0-9A-F]*), VarStore: 0x([0-9A-F]*),';
        if($regex.Matches) {
            $lineHandeld = $true;
            $option = 'One Of';
            $optionName = $regex.Matches.Groups[1].Captures[0].Value;
            $optionVarOffset = $regex.Matches.Groups[2].Captures[0].Value;
            $optionVarStore = $regex.Matches.Groups[3].Captures[0].Value;
            Write-Verbose "One Of: $optionName ($optionVarStore / $optionVarOffset)";
            [void]$grub.AppendLine(" submenu ""$($optionName.Replace('"', '')) ($optionVarStore-$optionVarOffset)"" {");

            [void]$grub.AppendLine("  menuentry ""read"" {");
            [void]$grub.AppendLine("    echo ""setup_var_3 0x$optionVarOffset""");
            [void]$grub.AppendLine("    setup_var_3 0x$optionVarOffset");
            [void]$grub.AppendLine('    read');
            [void]$grub.AppendLine('  }');
            $formEntries++;
        }
    }
    if(-not $lineHandeld -and $option -eq 'One Of') {
        $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*One Of Option: ([^,]*), Value \(8 bit\): 0x([0-9A-F]*) ';
        if($regex.Matches) {
            $lineHandeld = $true;
            $optionValueName = $regex.Matches.Groups[1].Captures[0].Value;
            $optionValue = $regex.Matches.Groups[2].Captures[0].Value;
            Write-Verbose "One Of Option: $($optionValueName) ($optionValue)";
            [void]$grub.AppendLine("  menuentry ""set to $($optionValueName.Replace('"', ''))"" {");
            [void]$grub.AppendLine("    echo ""setup_var_3 0x$optionVarOffset 0x$optionValue""");
            [void]$grub.AppendLine("    setup_var_3 0x$optionVarOffset 0x$optionValue");
            [void]$grub.AppendLine('    read');
            [void]$grub.AppendLine('  }');
        }
    }
    if(-not $lineHandeld) {
        $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*End One Of';
        if($regex.Matches) {
            $lineHandeld = $true;
            $option = "";
            [void]$grub.AppendLine(" }");
        }
    }

    # 'Numeric'
    if(-not $lineHandeld) {
        $regex = $line | Select-String -Pattern '0x[0-9A-F]*\s*Numeric: ([^,]*), VarStoreInfo \(VarOffset/VarName\): 0x([0-9A-F]*), VarStore: 0x([0-9A-F]*), QuestionId: 0x([0-9A-F]*), Size: ([0-9]*), Min: 0x([0-9A-F]*), Max 0x([0-9A-F]*),';
        if($regex.Matches) {
            $lineHandeld = $true;
            $option = 'Numeric';
            $optionName = $regex.Matches.Groups[1].Captures[0].Value;
            $optionVarOffset = $regex.Matches.Groups[2].Captures[0].Value;
            $optionVarStore = $regex.Matches.Groups[3].Captures[0].Value;
            $optionSize = $regex.Matches.Groups[5].Captures[0].Value;
            $optionMin = $regex.Matches.Groups[6].Captures[0].Value;
            $optionMax = $regex.Matches.Groups[7].Captures[0].Value;
            Write-Verbose "One Of: $optionName ($optionVarStore / $optionVarOffset)";
            [void]$grub.AppendLine(" submenu ""$($optionName.Replace('"', '')) ($optionVarStore-$optionVarOffset)"" {");

            [void]$grub.AppendLine("  menuentry ""read"" {");
            [void]$grub.AppendLine("    echo ""setup_var_3 0x$optionVarOffset""");
            [void]$grub.AppendLine("    setup_var_3 0x$optionVarOffset");
            [void]$grub.AppendLine('    read');
            [void]$grub.AppendLine('  }');
            
            [void]$grub.AppendLine("  menuentry ""update"" {");
            [void]$grub.AppendLine("    echo ""setup_var_3 0x$optionVarOffset""");
            [void]$grub.AppendLine("    setup_var_3 0x$optionVarOffset");
            [void]$grub.AppendLine("    echo ""Min: 0x$optionMin, Max: 0x$optionMax, Size: $optionSize""");
            [void]$grub.AppendLine('    read $val');
            [void]$grub.AppendLine("    echo ""setup_var_3 0x$optionVarOffset $('$')val""");
            [void]$grub.AppendLine("    echo $('$')val");
            [void]$grub.AppendLine("    setup_var_3 0x$optionVarOffset $('$')val");
            [void]$grub.AppendLine("    echo ""setup_var_3 0x$optionVarOffset""");
            [void]$grub.AppendLine("    setup_var_3 0x$optionVarOffset");
            [void]$grub.AppendLine('    read');
            [void]$grub.AppendLine('  }');

            $formEntries++;
            $option = '';
        }
    }
}

$grub.ToString() | Set-Content $grubFile;