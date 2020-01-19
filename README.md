# nim-4k-intro-sample
4k intro sample code written with Nim programming language.

## openGL4kGen
It download and read the OpenGL Registry XML file and generate a OpenGL wrapper optimized for 4k-intro.

### How to use openGL4kGen
Following code build openGL4kGen and generate OpenGL wrapper.
```console
cd nim-4k-intro-sample\tools\openGL4kGen
nim c -d:ssl openGL4kGen.nim
openGL4kGen.exe > ..\..\src\openGL4k2.nim
```

If you want to use OpenGL with Nim not for 4k-intro, use one of them:

- [Official OpenGL interface](https://github.com/nim-lang/opengl)
  All OpenGL functions and constants are hard coded.
  It uses undocumented Nim feature that allow only load OpenGL functions used in your code.
  Don't forget to call `loadExtensions` after initialized OpenGL context and before calling any OpenGL functions.

- [glad](https://github.com/Dav1dde/glad)
  GL/GLES/EGL/GLX/WGL Loader-Generator based on the official specs written in Python lanuage.
  You can specify OpenGL API version or which extension to be generated.
  It doesn't use undocumented Nim feature and it loads all OpenGL functions in your specified OpenGL version.

- [Nim Game Library](https://github.com/nimgl/nimgl)
  NimGL (Nim Game Library) is a collection of bindings for popular libraries, mostly used in computer graphics. A library of libraries.

