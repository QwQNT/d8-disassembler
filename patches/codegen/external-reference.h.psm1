Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $leaptieringDef = '^#ifdef V8_ENABLE_LEAPTIERING$'
    $Content = Add-LineBelow -Content $Content `
        -Patterns @($leaptieringDef) `
        -Insert '#if 0'
    $Content = Add-LineBelow -Content $Content `
        -Patterns @($leaptieringDef, 'js_dispatch_table_address') `
        -Insert @'
#endif
#define EXTERNAL_REFERENCE_LIST_LEAPTIERING(V)
'@

    $Content = Add-LineBelow -Content $Content `
        -Patterns @('V8_EXPORT_PRIVATE static ExternalReference isolate_address\(\);') `
        -Insert @'
#ifdef V8_ENABLE_LEAPTIERING
  V8_EXPORT_PRIVATE static ExternalReference js_dispatch_table_address();
#endif
'@

    return $Content
}
