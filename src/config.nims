# Build configuration file used by all *.nim files in this directory.
# Other *.nims files contain options specific to each samples.

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

if not existsFile("openGL4k2.nim"):
  withDir "../tools/openGL4kGen":
    selfExec("c -d:ssl openGL4kGen.nim")
    exec("openGL4kGen.exe -o=../../src/openGL4k2.nim")
