import oldwinapi/windows

proc WinMainCRTStartup() {.exportc.} =
  discard MessageBoxA(0, cstring"foobar", cstring"title", 0)

when not defined(release):
  WinMainCRTStartup()
