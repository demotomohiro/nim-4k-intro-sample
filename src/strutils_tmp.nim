#Use `%` in strutils module while avoiding https://github.com/nim-lang/Nim/issues/9762

const
  Digits* = {'0'..'9'}

proc toLowerAscii*(c: char): char {.noSideEffect, procvar.} =
  ## Returns the lower case version of ``c``.
  ##
  ## This works only for the letters ``A-Z``. See `unicode.toLower
  ## <unicode.html#toLower>`_ for a version that works for any Unicode
  ## character.
  runnableExamples:
    doAssert toLowerAscii('A') == 'a'
    doAssert toLowerAscii('e') == 'e'
  if c in {'A'..'Z'}:
    result = chr(ord(c) + (ord('a') - ord('A')))
  else:
    result = c

proc cmpIgnoreStyle*(a, b: string): int {.noSideEffect,
  procvar.} =
  ## Semantically the same as ``cmp(normalize(a), normalize(b))``. It
  ## is just optimized to not allocate temporary strings. This should
  ## NOT be used to compare Nim identifier names. use `macros.eqIdent`
  ## for that. Returns:
  ##
  ## | 0 iff a == b
  ## | < 0 iff a < b
  ## | > 0 iff a > b
  runnableExamples:
    doAssert cmpIgnoreStyle("foo_bar", "FooBar") == 0
    doAssert cmpIgnoreStyle("foo_bar_5", "FooBar4") > 0
  var i = 0
  var j = 0
  while true:
    while i < a.len and a[i] == '_': inc i
    while j < b.len and b[j] == '_': inc j
    var aa = if i < a.len: toLowerAscii(a[i]) else: '\0'
    var bb = if j < b.len: toLowerAscii(b[j]) else: '\0'
    result = ord(aa) - ord(bb)
    if result != 0: return result
    # the characters are identical:
    if i >= a.len:
      # both cursors at the end:
      if j >= b.len: return 0
      # not yet at the end of 'b':
      return -1
    elif j >= b.len:
      return 1
    inc i
    inc j

proc findNormalized(x: string, inArray: openArray[string]): int =
  var i = 0
  while i < high(inArray):
    if cmpIgnoreStyle(x, inArray[i]) == 0: return i
    inc(i, 2) # incrementing by 1 would probably lead to a
              # security hole...
  return -1

proc invalidFormatString() {.noinline.} =
  raise newException(ValueError, "invalid format string")

proc addf*(s: var string, formatstr: string, a: varargs[string, `$`]) {.
  noSideEffect.} =
  ## The same as ``add(s, formatstr % a)``, but more efficient.
  const PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\128'..'\255', '_'}
  var i = 0
  var num = 0
  while i < len(formatstr):
    if formatstr[i] == '$' and i+1 < len(formatstr):
      case formatstr[i+1]
      of '#':
        if num > a.high: invalidFormatString()
        add s, a[num]
        inc i, 2
        inc num
      of '$':
        add s, '$'
        inc(i, 2)
      of '1'..'9', '-':
        var j = 0
        inc(i) # skip $
        var negative = formatstr[i] == '-'
        if negative: inc i
        while i < formatstr.len and formatstr[i] in Digits:
          j = j * 10 + ord(formatstr[i]) - ord('0')
          inc(i)
        let idx = if not negative: j-1 else: a.len-j
        if idx < 0 or idx > a.high: invalidFormatString()
        add s, a[idx]
      of '{':
        var j = i+2
        var k = 0
        var negative = formatstr[j] == '-'
        if negative: inc j
        var isNumber = 0
        while j < formatstr.len and formatstr[j] notin {'\0', '}'}:
          if formatstr[j] in Digits:
            k = k * 10 + ord(formatstr[j]) - ord('0')
            if isNumber == 0: isNumber = 1
          else:
            isNumber = -1
          inc(j)
        if isNumber == 1:
          let idx = if not negative: k-1 else: a.len-k
          if idx < 0 or idx > a.high: invalidFormatString()
          add s, a[idx]
        else:
          var x = findNormalized(substr(formatstr, i+2, j-1), a)
          if x >= 0 and x < high(a): add s, a[x+1]
          else: invalidFormatString()
        i = j+1
      of 'a'..'z', 'A'..'Z', '\128'..'\255', '_':
        var j = i+1
        while j < formatstr.len and formatstr[j] in PatternChars: inc(j)
        var x = findNormalized(substr(formatstr, i+1, j-1), a)
        if x >= 0 and x < high(a): add s, a[x+1]
        else: invalidFormatString()
        i = j
      else:
        invalidFormatString()
    else:
      add s, formatstr[i]
      inc(i)

proc `%` *(formatstr: string, a: openArray[string]): string {.noSideEffect.} =
  ## Interpolates a format string with the values from `a`.
  ##
  ## The `substitution`:idx: operator performs string substitutions in
  ## `formatstr` and returns a modified `formatstr`. This is often called
  ## `string interpolation`:idx:.
  ##
  ## This is best explained by an example:
  ##
  ## .. code-block:: nim
  ##   "$1 eats $2." % ["The cat", "fish"]
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   "The cat eats fish."
  ##
  ## The substitution variables (the thing after the ``$``) are enumerated
  ## from 1 to ``a.len``.
  ## To produce a verbatim ``$``, use ``$$``.
  ## The notation ``$#`` can be used to refer to the next substitution
  ## variable:
  ##
  ## .. code-block:: nim
  ##   "$# eats $#." % ["The cat", "fish"]
  ##
  ## Substitution variables can also be words (that is
  ## ``[A-Za-z_]+[A-Za-z0-9_]*``) in which case the arguments in `a` with even
  ## indices are keys and with odd indices are the corresponding values.
  ## An example:
  ##
  ## .. code-block:: nim
  ##   "$animal eats $food." % ["animal", "The cat", "food", "fish"]
  ##
  ## Results in:
  ##
  ## .. code-block:: nim
  ##   "The cat eats fish."
  ##
  ## The variables are compared with `cmpIgnoreStyle`. `ValueError` is
  ## raised if an ill-formed format string has been passed to the `%` operator.
  result = newStringOfCap(formatstr.len + a.len shl 4)
  addf(result, formatstr, a)

proc `%` *(formatstr, a: string): string {.noSideEffect.} =
  ## This is the same as ``formatstr % [a]``.
  result = newStringOfCap(formatstr.len + a.len)
  addf(result, formatstr, [a])

when isMainModule:
  assert "$foo is foo" % ["foo", "bar"] == "bar is foo"
