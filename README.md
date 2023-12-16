# date-zig
A port of https://github.com/nakedible/datealgo-rs/ to zig.  
datealgo-rs is based on https://github.com/cassioneri/eaf

## Support
currently only supports posix based operating systems.

## TODO
* wasm: `zig build test -Dtarget=wasm32-wasi -fwasmtime`
* windows: `zig build test -Dtarget=x86_64-windows -fwine`
* other non posix?