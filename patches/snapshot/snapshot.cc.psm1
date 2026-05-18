Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "bool Snapshot::VersionIsValid" `
        -Converter {
        param($Body)
        return @"
  return true;
"@
    }

    return $Content
}
