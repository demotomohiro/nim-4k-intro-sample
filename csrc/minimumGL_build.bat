cl /c /nologo /FominimumGL.o /O1 /Ob2 /Oi /Os minimumGL.c
crinkler /OUT:minimumGL_c.exe /SUBSYSTEM:WINDOWS user32.lib kernel32.lib Gdi32.lib Opengl32.lib minimumGL.o
