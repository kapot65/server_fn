# server_fn
An attempt to achieve Leptos [server functions](https://book.leptos.dev/server/25_server_functions.html) functionality in Nim.


## usage
1. A `httpbeast` and `unibs` must be installed and added as imports
   ```python
   import httpbeast
   import unibs

   # your code after ...
   ```


## caveats
- unibs doesnt works with simple types (int, float etc)


### TODO
- [ ] add default values for arguments
- [ ] switch from unibs to json-serialization
- [ ] make onApi generated 
- [ ] pass ref instead of copy to internal funcs