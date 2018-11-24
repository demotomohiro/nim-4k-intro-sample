cl /c /nologo /Fominimum.o /O1 /Ob2 /Oi /Os minimum.c
crinkler /OUT:minimum_c.exe /SUBSYSTEM:WINDOWS user32.lib kernel32.lib minimum.o
