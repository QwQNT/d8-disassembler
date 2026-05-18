Import-Module (Join-Path $PSScriptRoot "..\utils.psm1")

function Patch {
    param([string]$Content)

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "void SharedFunctionInfo::SharedFunctionInfoPrint" `
        -Converter {
        param($Body)
        $Body = Set-CommentLine -Content $Body -Pattern "\s*PrintSourceCode\(os\);"
        $Body += "`n"
        $Body += @"
  os << "\nStart BytecodeArray\n";
  if (isolate != nullptr && this->HasBytecodeArray()) {
    this->GetActiveBytecodeArray(isolate)->Disassemble(os);
  } else {
    os << "<none>\n";
  }
  os << "\nEnd BytecodeArray\n";
  os << std::flush;
"@
        return $Body
    }

    $Content = Edit-FunctionBody -Content $Content `
        -FunctionName "void HeapObject::HeapObjectShortPrint" `
        -Converter {
        param($Body)
#        $Body = Add-LineBelow -Content $Body `
#            -Patterns @('cage_base =') `
#            -Insert @"
#  Isolate* isolate = nullptr;
#  if (!GetIsolateFromHeapObject(*this, &isolate) || isolate == nullptr) {
#    os << "[!!! Corrupted HeapObject (cannot get Isolate) at "
#       << reinterpret_cast<void*>(this->ptr()) << " !!!]";
#    return;
#  }
#  ReadOnlyRoots roots(isolate);
#  Tagged<Map> map_of_this_object = this->map(cage_base);
#  if (map_of_this_object.ptr() == kNullAddress) {
#    os << "[!!! Corrupted HeapObject (null map pointer) at "
#       << reinterpret_cast<void*>(this->ptr()) << " !!!]";
#    return;
#  }
#  if (map_of_this_object->map(cage_base) != roots.meta_map()) {
#    os << "[!!! Corrupted HeapObject (invalid map) at "
#       << reinterpret_cast<void*>(this->ptr()) << " !!!]";
#    return;
#  }
#"@
        $Body = Add-LineBefore -Content $Body `
            -Pattern '\s*switch \(map\(cage_base\)->instance_type\(\)\) {' `
            -Insert @"
  if (map(cage_base)->instance_type() == ASM_WASM_DATA_TYPE) {
    os << "<ArrayBoilerplateDescription> ";
    Cast<ArrayBoilerplateDescription>(*this)
        ->constant_elements()
        .GetHeapObject()
        ->HeapObjectShortPrint(os);
    return;
  }
"@
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('case FIXED_ARRAY_TYPE:', ';') `
            -Insert @"
      os << "\nStart FixedArray\n";
      Cast<FixedArray>(*this)->FixedArrayPrint(os);
      os << "\nEnd FixedArray\n";
"@
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('case OBJECT_BOILERPLATE_DESCRIPTION_TYPE:', ';') `
            -Insert @"
      os << "\nStart ObjectBoilerplateDescription\n";
      Cast<ObjectBoilerplateDescription>(*this)
          ->ObjectBoilerplateDescriptionPrint(os);
      os << "\nEnd ObjectBoilerplateDescription\n";
"@
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('case FIXED_DOUBLE_ARRAY_TYPE:', ';') `
            -Insert @"
      os << "\nStart FixedDoubleArray\n";
      Cast<FixedDoubleArray>(*this)->FixedDoubleArrayPrint(os);
      os << "\nEnd FixedDoubleArray\n";
"@
        $Body = Add-LineBelow -Content $Body `
            -Patterns @('case SHARED_FUNCTION_INFO_TYPE:', 'else', '}') `
            -Insert @"
      os << "\nStart SharedFunctionInfo\n";
      shared->SharedFunctionInfoPrint(os);
      os << "\nEnd SharedFunctionInfo\n";
"@
        return $Body
    }

    return $Content
}
