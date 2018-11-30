import strutils
from os import extractFilename

proc toCVar(text: string): string =
  result = ""
  for l in splitLines(text):
    result.add "\"" & l & "\\n\"\n"

for i in 3..paramCount():
  echo "Processing ", paramStr(i)
  let fname = paramStr(i)
  let text = readFile(fname)
  let varName = fname.extractFilename().replace('.', '_')
  let output = "const char " & varName & "[] =\n" & toCVar(text) & ";"
  writefile(fname & ".h", output)
