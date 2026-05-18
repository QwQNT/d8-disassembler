# `d8-disassembler`

```powershell
.\target\v8\out.gn\x64.release\d8.exe `
  --no-lazy `
  --no-flush-bytecode `
  --snapshot_blob .\v8_context_snapshot.bin `
  -e "loadBytecode('.\\index.js.bin')"
```

# LICENSE

```
d8-disassembler: A V8 bytecode disassembler and decompiler.
Copyright (C) 2026  Cdm2883

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as 
published by the Free Software Foundation, either version 3 of 
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
