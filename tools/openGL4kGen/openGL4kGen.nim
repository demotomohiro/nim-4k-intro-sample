import os, httpclient, strformat, strutils, xmlparser, xmltree
import sets, with

iterator elements(n: XmlNode): XmlNode =
  for i in items(n):
    if i.kind == xnElement:
      yield i

type
  CoreAPI = object
    coreCommands, coreCommandsExt, coreEnums: HashSet[string]

proc loadCoreAPI(ca: var CoreAPI; node: XmlNode) =
  with ca:
    for i in elements(node):
      if i.tag == "feature" and i.attr("api") == "gl":
        var version = i.attr("number")
        assert version.len != 0
        for j in elements(i):
          if j.tag == "require":
            let profile = j.attr("profile")
            if profile.len != 0 and profile != "core":
              continue
            for k in elements(j):
              let name = k.attr("name")
              if name.len == 0:
                continue
              if k.tag == "enum":
                coreEnums.incl name
              elif k.tag == "command":
                if version == "1.0" or version == "1.1":
                  coreCommands.incl name
                else:
                  coreCommandsExt.incl name
          elif j.tag == "remove":
            for k in elements(j):
              let name = k.attr("name")
              if name.len == 0:
                continue
              if k.tag == "enum":
                assert name in coreEnums
                coreEnums.excl name
              elif k.tag == "command":
                assert name in coreCommands or name in coreCommandsExt
                coreCommands.excl name
                coreCommandsExt.excl name

    assert "glNewList" notin coreCommands
    assert "glDrawMeshTasksNV" notin coreCommands
    assert "glCullFace" in coreCommands
    assert "glCullFace" notin coreCommandsExt
    assert "glEnable" in coreCommands
    assert "glEnable" notin coreCommandsExt
    assert "glDrawArrays" in coreCommands
    assert "glDrawArrays" notin coreCommandsExt
    assert "glSpecializeShader" notin coreCommands
    assert "glSpecializeShader" in coreCommandsExt
    assert "glGetnHistogram" notin coreCommands
    assert "glGetnHistogram" notin coreCommandsExt
    assert "glVertexP2ui" notin coreCommandsExt
    assert "GL_CURRENT_BIT" notin coreEnums
    assert "GL_LIGHTING_BIT" notin coreEnums
    assert "GL_VERTEX_ATTRIB_ARRAY_DIVISOR" in coreEnums
    assert "GL_SHADER_BINARY_FORMAT_SPIR_V" in coreEnums

proc outputCoreAPI(ca: var CoreAPI; node: XmlNode) =
  const
    needPrefixEnums = toHashSet(
      ["GL_BYTE", "GL_SHORT", "GL_INT", "GL_FLOAT", "GL_DOUBLE", "GL_FIXED"])
    nimKeywords = toHashSet(
      ["addr", "and", "as", "asm",
       "bind", "block", "break",
       "case", "cast", "concept", "const", "continue", "converter",
       "defer", "discard", "distinct", "div", "do",
       "elif", "else", "end", "enum", "except", "export",
       "finally", "for", "from", "func",
       "if", "import", "in", "include", "interface", "is", "isnot", "iterator",
       "let",
       "macro", "method", "mixin", "mod",
       "nil", "not", "notin",
       "object", "of", "or", "out",
       "proc", "ptr",
       "raise", "ref", "return",
       "shl", "shr", "static",
       "template", "try", "tuple", "type",
       "using",
       "var",
       "when", "while",
       "xor",
       "yield"])

  echo "const"
  for i in elements(node):
    if i.tag == "enums":
      var enumType = if i.attr("type") == "bitmask": ".GLbitfield" else: ".GLenum"
      for j in elements(i):
        if j.tag == "enum":
          var name = j.attr("name")
          if name.len == 0 or name notin ca.coreEnums:
            continue
          if name in needPrefixEnums:
            name = 'c' & name
          doAssert name notin nimKeywords
          let value = j.attr("value")
          if value.len == 0:
            continue
          if j.attr("type") == "ull":
            enumType = "'u64.GLuint64"
          echo &"  {name}* = {value}{enumType}"

  echo ""

  for i in elements(node):
    if i.tag == "commands":
      for j in elements(i):
        if j.tag == "command":
          block commandTag:
            var
              ret: string
              isExt: bool
            for k in elements(j):
              let nameElem = k.child("name")
              var name = if nameElem == nil: "" else:
                                             nameElem[0].text
              let typeElem = k.child("ptype")
              if k.tag == "proto":
                if name.len == 0:
                  break commandTag
                if name in ca.coreCommandsExt:
                  isExt = true
                elif name notin ca.coreCommands:
                  break commandTag
                assert name notin nimKeywords
                if typeElem != nil:
                  ret = ": " & typeElem[0].text
                stdout.write &"proc {name}*("
              elif k.tag == "param":
                if typeElem != nil:
                  if name in nimKeywords:
                    name = name & '0'
                  let nptr = k.innerText.count('*')
                  var typeText = typeElem[0].text
                  if nptr == 1:
                    if typeText == "GLchar":
                      typeText = "cstring"
                    else:
                      typeText = "ptr " & typeText
                  elif nptr == 2 and typeText == "GLchar":
                    typeText = "cstringArray"
                  stdout.write &" {name}: {typeText};"
            echo ")", ret, " {.", if isExt:  "oglExt" else: "ogl", ".}"

proc outputCommon() =
  echo readFile("openGLTypes.nim")
  echo "proc wglGetProcAddress(Arg1: cstring): pointer {.stdcall, importc, header: \"#include <Windows.h>\\n#include <wingdi.h>\".}"
  echo "{.pragma: ogl, stdcall, importc, header: \"<GL/gl.h>\"}"
  echo "{.pragma: oglExt, stdcall, importc, dynlib: wglGetProcAddress(\"0\").}"
  echo """
proc nimLoadProcs0() {.importc.}

template loadExtensions*() =
  ## call this after your rendering context has been setup if you use
  ## extensions.
  bind nimLoadProcs0
  nimLoadProcs0()
"""
  echo "#wgl extensions are not much used in 4k intros."
  echo "#Just hard code here."
  echo "type WINBOOL* = int32"
  echo "proc wglSwapIntervalEXT*(interval: cint): WINBOOL{.oglExt.}"

proc main() =
  # https://github.com/KhronosGroup/OpenGL-Registry
  if not existsFile("gl.xml"):
    var client = newHttpClient()
    client.downloadFile("https://github.com/KhronosGroup/OpenGL-Registry/raw/master/xml/gl.xml", "gl.xml")

  let node = loadXml("gl.xml")

  var ca: CoreAPI
  ca.loadCoreAPI(node)
  outputCommon()
  ca.outputCoreAPI(node)

main()
