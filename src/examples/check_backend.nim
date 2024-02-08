when defined(js):
    proc test() = echo "JS"
else:
    proc test() = echo "Not JS"
test()