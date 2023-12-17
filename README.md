# date-zig
A port of https://github.com/nakedible/datealgo-rs/ to zig.  
datealgo-rs is based on https://github.com/cassioneri/eaf

## Support
system time related related methods such as `datetime_to_systemtime()` and `systemtime_to_datetime()` currently only support posix based operating systems. 

everything else such as `rd_to_date()` and `date_to_rd()` should work on any target and platform.

## TODO
* wasm: `zig build test -Dtarget=wasm32-wasi -fwasmtime`
* windows: `zig build test -Dtarget=x86_64-windows -fwine`
* other non posix?