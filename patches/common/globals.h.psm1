Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = $Content -replace '#define V8_JUMP_TABLE_INFO_BOOL true', @"
// Keep disabled for code-cache compatibility: enabling it changes the
// Code object layout by adding kJumpTableInfoOffsetOffset.
#define V8_JUMP_TABLE_INFO_BOOL false
"@

    return $Content
}
