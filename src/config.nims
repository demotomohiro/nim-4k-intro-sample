import strformat

const
  ScreenWidth {.intdefine.}  = 640
  ScreenHeight {.intdefine.} = 480

--cc:vcc
--d:noAutoGLerrorCheck
--cpu:i386
when defined(release):
  --os:standalone
  --gc:none
  --dynlibOverrideAll
  --noMain
  --opt:size
  switch("d", "StandaloneHeapSize=0")
  switch("d", "windows")

  put "vcc.linkerexe", "crinkler.exe"
  put "vcc.options.always", "--platform:x86 /nologo /Ob2 /Oi /Os /GS-"
  let exename = &"{projectName()}{ScreenWidth}x{ScreenHeight}"
  put "vcc.options.linker", &"/SUBSYSTEM:WINDOWS /OUT:{exename.toExe()}"
else:
  put "vcc.options.always", "--platform:x86 /nologo /Z7"
  put "vcc.options.linker", "--platform:x86 /nologo /DEBUG /Zi"
