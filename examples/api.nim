## Sample API that will be used both on server and client side
import ../src/server_fn

type
  PersistentState* = object
    counter: int

when not defined(js):
  # define server-side imports here
  import std/strformat

  # define server-side logic (persistent state, DB etc) here
  var state = PersistentState(counter: 0)

# define procs that needs to be RPC'd here
make_server_fns:
  proc read*(a: string, b: string, time: int = 0): string =
    return fmt"from backend -> {a}; {b}; {time}"

  proc server_echo*(message: string): string =
    return fmt"echo from server -> {message}"

  proc inc_val*(): PersistentState =
    state.counter += 1
    return state