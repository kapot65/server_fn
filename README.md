# server_fn
An attempt to achieve Leptos [server functions](https://book.leptos.dev/server/25_server_functions.html) functionality in Nim.

## example
An [exampes](./examples/) folder contains minimal working example.
To run it follow next steps:
1. compile js part
   ```bash
   nim js examples/client.nim # from server_fn root
   ```
2. compile and run server
   ```bash
   nim r examples/server.nim
   ```
3. open http://localhost:8880/ and check console

## caveats
- unibs doesnt works with simple types (int, float etc)
- no error handling for now

<!-- ### TODO
- [ ] switch from unibs to json-serialization
- [ ] pass ref instead of copy to internal funcs
- [ ] add implemetation for native rpc client
- [ ] createRemoteCall -> change proc to func
- [ ] add debug logging -->