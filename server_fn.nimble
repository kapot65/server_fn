# Package

version       = "0.1.0"
author        = "chernov"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["server_fn"]


# Dependencies

requires "nim >= 2.0.2"

requires "mummy >= 0.4.0"
