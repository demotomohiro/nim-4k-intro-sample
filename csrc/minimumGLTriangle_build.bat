nim e glslheader.nims ..\shaders\triangle.vs ..\shaders\triangle.fs 
cl /c /nologo /FominimumGLTriangle.o /O1 /Ob2 /Oi /Os minimumGLTriangle.c
crinkler /OUT:minimumGLTriangle_c.exe /SUBSYSTEM:WINDOWS user32.lib kernel32.lib Gdi32.lib Opengl32.lib minimumGLTriangle.o
