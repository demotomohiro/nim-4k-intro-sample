when defined(release):
  --passL:user32.lib kernel32.lib Gdi32.lib Opengl32.lib winmm.lib
else:
  --passL:winmm.lib
