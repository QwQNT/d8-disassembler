void Shell::LoadBytecode(const v8::FunctionCallbackInfo<v8::Value>& info) {
    auto isolate = info.GetIsolate();
    auto isolateInternal = reinterpret_cast<v8::internal::Isolate*>(isolate);

    if (info.Length() < 1) {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8(isolate, "No args found.").ToLocalChecked()));
        return;
    }

    v8::String::Utf8Value filename(isolate, info[0]);
    if (*filename == NULL) {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8(isolate, "Error creating filename.").ToLocalChecked()));
        return;
    }

    int length = 0;
    std::unique_ptr<char[]> raw_filedata(ReadChars(*filename, &length));
    if (raw_filedata == nullptr) {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8(isolate, "Error reading file.").ToLocalChecked()));
        return;
    }

    auto filedata = reinterpret_cast<uint8_t*>(raw_filedata.get());
    v8::internal::AlignedCachedData cached_data(filedata, length);
    auto source = isolateInternal->factory()
        ->NewStringFromUtf8(base::CStrVector("source"))
        .ToHandleChecked();
    v8::internal::ScriptDetails script_details;

    printf("===== START DESERIALIZE BYTECODE =====\n");
    v8::internal::CodeSerializer::Deserialize(isolateInternal, &cached_data, source, script_details);
}
