import strutils
from os import extractFilename

proc processGLSL(text: string): string =
  const
    soundSampleRate     = 44100
    soundLengthInSecond = 60
    soundNumSamples     = soundSampleRate * soundLengthInSecond
    soundCSLocalSize    = 32
    shaderTimeLoc       = 1

  text % ["soundNumSamples", $soundNumSamples,
          "soundCSLocalSize", $soundCSLocalSize,
          "soundSampleRate", $soundSampleRate,
          "shaderTimeLoc", $shaderTimeLoc
          ]

proc toCVar(text: string): string =
  result = ""
  for l in splitLines(text):
    result.add "\"" & l & "\\n\"\n"

for i in 3..paramCount():
  echo "Processing ", paramStr(i)
  let fname = paramStr(i)
  let text = readFile(fname).processGLSL()
  let varName = fname.extractFilename().replace('.', '_')
  let output = "const char " & varName & "[] =\n" & toCVar(text) & ";"
  writefile(fname & ".h", output)
