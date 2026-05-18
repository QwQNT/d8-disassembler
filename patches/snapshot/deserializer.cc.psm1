Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)
    
    $deserializerSignature = "Deserializer<IsolateT>::Deserializer"
    $Content = Add-LineBelow -Content $Content `
        -Patterns @($deserializerSignature, '#endif') `
        -Insert "  /*"
    $Content = Add-LineBelow -Content $Content `
        -Patterns @($deserializerSignature, 'CHECK_EQ') `
        -Insert "  */"

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "int Deserializer<IsolateT>::ReadReadOnlyHeapRef" `
        -Parameter "uint8_t data,\s*SlotAccessor slot_accessor" `
        -Converter {
        param($Body)
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('ReadOnlySpace\* read_only_space = isolate\(\)->heap\(\)->read_only_space\(\);') `
            -Insert @"
  size_t page_count = read_only_space->pages().size();
  if (chunk_index >= page_count) {
    PrintF("ReadOnlyHeapRef out of range: source_pos=%d pages=%zu chunk_index=%u chunk_offset=%u\n",
           source_.position(), page_count, chunk_index, chunk_offset);
    FATAL("invalid ReadOnlyHeapRef chunk index");
  }
"@
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('ReadOnlyPageMetadata\* page = read_only_space->pages\(\)\[chunk_index\];') `
            -Insert @"
  if (chunk_offset >= page->size()) {
    PrintF("ReadOnlyHeapRef offset out of range: source_pos=%d pages=%zu chunk_index=%u chunk_offset=%u page_size=%zu area_start=%p area_end=%p\n",
           source_.position(), page_count, chunk_index, chunk_offset, page->size(),
           reinterpret_cast<void*>(page->area_start()), reinterpret_cast<void*>(page->area_end()));
    FATAL("invalid ReadOnlyHeapRef chunk offset");
  }
"@
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('Address address = page->OffsetToAddress\(chunk_offset\);') `
            -Insert @"
  if (address < page->area_start() || address >= page->area_end()) {
    PrintF("ReadOnlyHeapRef outside object area: source_pos=%d pages=%zu chunk_index=%u chunk_offset=%u address=%p chunk=%p page_size=%zu area_start=%p area_end=%p\n",
           source_.position(), page_count, chunk_index, chunk_offset,
           reinterpret_cast<void*>(address), reinterpret_cast<void*>(page->ChunkAddress()),
           page->size(), reinterpret_cast<void*>(page->area_start()),
           reinterpret_cast<void*>(page->area_end()));
    FATAL("invalid ReadOnlyHeapRef object address");
  }
"@
        $Body = $Body -replace 'ShortPrint\(heap_object\);', 'PrintF("0x%" PRIxPTR, heap_object.ptr());'
        return $Body
    }

    return $Content
}
