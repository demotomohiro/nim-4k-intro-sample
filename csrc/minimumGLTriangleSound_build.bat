nim e glslheader.nims ..\shaders\triangle.vs ..\shaders\triangle.fs ..\shaders\sound.cs
cl /c /nologo /FominimumGLTriangleSound.o /O1 /Ob2 /Oi /Os minimumGLTriangleSound.c
crinkler /OUT:minimumGLTriangleSound_c.exe /SUBSYSTEM:WINDOWS user32.lib kernel32.lib Gdi32.lib Opengl32.lib winmm.lib minimumGLTriangleSound.o
