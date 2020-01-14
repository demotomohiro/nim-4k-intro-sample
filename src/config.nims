--cc:vcc
--d:noAutoGLerrorCheck
--cpu:i386
when defined(danger):
  --os:standalone
  --gc:none
  --dynlibOverrideAll
  --noMain
  --opt:size
  switch("d", "StandaloneHeapSize=0")
  switch("d", "windows")

  put "vcc.linkerexe", "crinkler.exe"
  put "vcc.options.always", "/nologo /Ob2 /Oi /Os /GS-"
  put "vcc.options.linker", "/SUBSYSTEM:WINDOWS"
  put "vcc.linkTmpl", "$options /OUT:$exefile.exe $objfiles"
