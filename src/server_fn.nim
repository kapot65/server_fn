import std/macros

when defined(js):
    import server_fn/client
else:
    import server_fn/server

macro make_server_fns*(args: untyped): untyped =
    # TODO: add docstring
    for procDef in args:
        assert(
            procDef.kind == nnkProcDef, 
            "macro block must contain only proc definitions"
        )

    when defined(js):
        createApi(args)
    else:
        createServerApi(args)
    