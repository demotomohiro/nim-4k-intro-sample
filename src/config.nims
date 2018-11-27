--cc:vcc
--d:noAutoGLerrorCheck
when defined(release):
  --cpu:i386
  --os:standalone
  --gc:none
  --dynlibOverrideAll
  --noMain
  --opt:size
  switch("d", "StandaloneHeapSize=0")
  switch("d", "windows")

  put "vcc.linkerexe", "crinkler.exe"
  put "vcc.options.always", "--platform:x86 /nologo /Ob2 /Oi /Os /GS-"
  put "vcc.options.linker", "/SUBSYSTEM:WINDOWS /OUT:" & projectName().toExe()
