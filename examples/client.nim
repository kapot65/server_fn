import std/asyncjs
import std/strformat

import api

proc main(): void {.async.} = 
  debugEcho await read("FIELD_A", "FIELD_B") # with default parameter
  debugEcho await read("FIELD_A", "FIELD_B", 1500) # method 1
  debugEcho await server_echo("ECHO_MESSAGE") # method 2

  # persistent functions check
  debugEcho fmt"state after inc_val #1: {await inc_val()}" 
  debugEcho fmt"state after inc_val #2: {await inc_val()}"
main()