import winlean4k

proc WinMainCRTStartup() {.exportc.} =
  discard MessageBoxA(nil, cstring"foobar", cstring"title", 0)

when not defined(release):
  WinMainCRTStartup()
