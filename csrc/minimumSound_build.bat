cl /c /nologo /FominimumSound.o /O1 /Ob2 /Oi /Os /fp:fast /arch:IA32 minimumSound.c
crinkler /OUT:minimumSound_c.exe /SUBSYSTEM:WINDOWS user32.lib kernel32.lib winmm.lib minimumSound.o
