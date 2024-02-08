# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import server_fnpkg/submodule

import iso_client

when isMainModule:
  echo(getWelcomeMessage())
