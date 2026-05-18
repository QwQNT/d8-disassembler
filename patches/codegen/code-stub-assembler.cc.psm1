function Patch {
    param([string]$Content)

    $Content = $Content -replace `
        'ExternalReference::js_dispatch_table_address\(\)', `
        'ExternalReference::Create(IsolateFieldId::kJSDispatchTable)'

    return $Content
}
