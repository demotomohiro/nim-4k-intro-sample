import os, httpclient, strformat, strutils, xmlparser, xmltree
import parseopt, sets, with
import ../../compiler/wordrecg

iterator elements(n: XmlNode): XmlNode =
  for i in items(n):
    if i.kind == xnElement:
      yield i

type
  ExportAPI = object
    exportCommands, exportCommandsExt, exportEnums: HashSet[string]

proc loadExportAPI(ca: var ExportAPI; node: XmlNode; extensions = HashSet[string]()) =
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
                exportEnums.incl name
              elif k.tag == "command":
                if version == "1.0" or version == "1.1":
                  exportCommands.incl name
                else:
                  exportCommandsExt.incl name
          elif j.tag == "remove":
            for k in elements(j):
              let name = k.attr("name")
              if name.len == 0:
                continue
              if k.tag == "enum":
                assert name in exportEnums
                exportEnums.excl name
              elif k.tag == "command":
                assert name in exportCommands or name in exportCommandsExt
                exportCommands.excl name
                exportCommandsExt.excl name
      elif i.tag == "extensions":
        for j in elements(i):
          let name = j.attr("name")
          if j.tag == "extension" and name.len != 0 and name in extensions:
            for k in elements(j):
              let profile = k.attr("profile")
              if k.tag != "require" or profile == "compatibility":
                continue
              for l in elements(k):
                let name = l.attr("name")
                if name.len == 0:
                  continue
                if l.tag == "enum":
                  exportEnums.incl name
                elif l.tag == "command":
                  exportCommandsExt.incl name

proc testCoreOpenGL(ea: var ExportAPI) =
  with ea:
    assert "glNewList" notin exportCommands
    assert "glDrawMeshTasksNV" notin exportCommands
    assert "glCullFace" in exportCommands
    assert "glCullFace" notin exportCommandsExt
    assert "glEnable" in exportCommands
    assert "glEnable" notin exportCommandsExt
    assert "glDrawArrays" in exportCommands
    assert "glDrawArrays" notin exportCommandsExt
    assert "glSpecializeShader" notin exportCommands
    assert "glSpecializeShader" in exportCommandsExt
    assert "glGetnHistogram" notin exportCommands
    assert "glGetnHistogram" notin exportCommandsExt
    assert "glVertexP2ui" notin exportCommandsExt
    assert "GL_CURRENT_BIT" notin exportEnums
    assert "GL_LIGHTING_BIT" notin exportEnums
    assert "GL_VERTEX_ATTRIB_ARRAY_DIVISOR" in exportEnums
    assert "GL_SHADER_BINARY_FORMAT_SPIR_V" in exportEnums

proc outputExportAPI(ca: var ExportAPI; fout: File; node: XmlNode) =
  const
    needPrefixEnums = toHashSet(
      ["GL_BYTE", "GL_SHORT", "GL_INT", "GL_FLOAT", "GL_DOUBLE", "GL_FIXED"])
    #Get Nim keywords using compiler/wordrecg
    nimKeywords = toHashSet(
      specialWords[TSpecialWord.low.succ..nimKeywordsHigh.TSpecialWord])

  fout.write "const\n"
  for i in elements(node):
    if i.tag == "enums":
      var defaultEnumType = if i.attr("type") == "bitmask": ".GLbitfield" else: ".GLenum"
      for j in elements(i):
        if j.tag == "enum":
          var name = j.attr("name")
          if name.len == 0 or name notin ca.exportEnums:
            continue
          if name in needPrefixEnums:
            name = 'c' & name
          doAssert name notin nimKeywords
          let value = j.attr("value")
          if value.len == 0:
            continue
          var enumType = defaultEnumType
          if j.attr("type") == "ull":
            enumType = "'u64.GLuint64"
          if name == "GL_TRUE" or name == "GL_FALsE":
            enumType = ".GLboolean"
          fout.write &"  {name}* = {value}{enumType}\n"

  fout.write "\n"

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
              let nptr = k.innerText.count('*')
              if k.tag == "proto":
                if name.len == 0:
                  break commandTag
                if name in ca.exportCommandsExt:
                  isExt = true
                elif name notin ca.exportCommands:
                  break commandTag
                assert name notin nimKeywords
                if typeElem != nil:
                  ret = ": "
                  if nptr == 1:
                    ret &= "ptr "
                  let typeText = typeElem[0].text
                  if typeText == "BOOL":
                    ret &= "WINBOOL"
                  else:
                    ret &= typeText
                elif k[0].kind == xnText and k[0].text == "void *":
                  ret = ": pointer"
                fout.write &"proc {name}*("
              elif k.tag == "param":
                if name in nimKeywords:
                  name = name & '0'
                var typeText: string
                if typeElem == nil:
                  if k[0].kind == xnText:
                    if nptr == 1:
                      typeText = "pointer"
                    elif nptr == 2:
                      typeText = "ptr pointer"
                    else:
                      typeText = k[0].text
                  else:
                    assert false
                else:
                  typeText = typeElem[0].text
                  if nptr == 1:
                    if typeText == "GLchar":
                      typeText = "cstring"
                    else:
                      typeText = "ptr " & typeText
                  elif nptr == 2 and typeText == "GLchar":
                    typeText = "cstringArray"
                fout.write &" {name}: {typeText};"
            fout.write ")", ret, " {.", if isExt:  "oglExt" else: "ogl", ".}\n"

proc outputCommon(fout: File) =
  fout.write readFile("openGLTypes.nim")
  fout.write '\n'
  fout.write readFile("openGLCommon.nim")
  fout.write '\n'

proc downloadXml(url, filename: string): XmlNode =
  if not existsFile(filename):
    var client = newHttpClient()
    client.downloadFile(url, filename)

  return loadXml(filename)

proc wgl(fout: File) =
  let node = downloadXml("https://github.com/KhronosGroup/OpenGL-Registry/raw/master/xml/wgl.xml", "wgl.xml")

  # Commonly used WGL extensions.
  const wglExts = ["WGL_ARB_create_context", "WGL_ARB_create_context_profile", "WGL_EXT_swap_control"].toHashSet
  var ea: ExportAPI
  ea.loadExportAPI(node, wglExts)
  ea.outputExportAPI(fout, node)

proc main() =
  var fout = stdout

  for kind, key, val in getopt():
    case kind
    of cmdArgument: discard
    of cmdLongOption, cmdShortOption:
      case key
      of "o": fout = open(val, fmWrite)
      else: quit("Unknown option: " & key)
    of cmdEnd: assert(false) # cannot happen

  # https://github.com/KhronosGroup/OpenGL-Registry
  let node = downloadXml("https://github.com/KhronosGroup/OpenGL-Registry/raw/master/xml/gl.xml", "gl.xml")

  var ca: ExportAPI
  ca.loadExportAPI(node)
  ca.testCoreOpenGL()
  outputCommon(fout)
  ca.outputExportAPI(fout, node)

  wgl(fout)

  fout.close

main()
