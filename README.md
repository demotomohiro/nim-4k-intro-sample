# nim-4k-intro-sample
4k intro sample code written with Nim programming language.
This sample is written for MS Windows.

## Build tools
- [Nim](https://nim-lang.org/)
  - Works in version 1.2.0
  - ~~Current sample requires devel version. You can download it from~~ [nim-lang/nightlies](https://github.com/nim-lang/nightlies/releases)
- Visual Studio 2015
- [Crinkler](http://crinkler.net/)

Nim use C compiler in Visual Studio as backend.
Crinkler works as linker and compress your code and data.
Output executable file from crinkler decompress code at runtime.

## Required libraries
- [winlean4k](https://github.com/demotomohiro/winlean4k)
- [with](https://github.com/zevv/with)
  - Used in openGL4kGen
- [OpenGL Extension Header Files](https://www.khronos.org/registry/OpenGL/index_gl.php)
  - Optional. This header file is used when building samples in `csrc` directory that uses OpenGL.
  - Create the directory `GL` in somewhere and download `glext.h` and `wglext.h` to it.
  - Create the directory `KHR` in same place and download `khrplatform.h` to it.

## How to build Nim sampels
Make sure parent directories of `nim` and `crinker` are in `PATH` environment variable and you can run them from command prompt.
1. Set `LIB` environment variable to the directory containing `*.lib` files to use Windows API.
   - For example:
   ```console
   set lib=c:\Program Files (x86)\Windows Kits\8.1\Lib\winv6.3\um\x86
   ```
   - Do *not* use double quote in `LIB` environment variable. Otherwise crinkler doesn't recognize it.
1. Build
   ```console
   git clone https://github.com/demotomohiro/nim-4k-intro-sample.git
   cd nim-4k-intro-sample\src
   ```

   - Release build:
   ```console
   nim c -d:danger minimum.nim
   ```

   - Debug build:
   ```console
   nim c minimum.nim
   ```

## How to build C samples
Make sure parent directories of `nim` and `crinker` are in `PATH` environment variable and you can run them from command prompt.
1. Run VS2015 x86 Native Tools command prompt
1. Set `INCLUDE` environment variable to the directory containing OpenGL Extension Header Files(`GL/glext.h`, `GL/wglext.h` and `KHR/khrplatform.h`).
   - For example:
   ```console
   set INCLUDE=c:\path\to\include;%INCLUDE%
   ```
1. Build
   ```console
   git clone https://github.com/demotomohiro/nim-4k-intro-sample.git
   cd nim-4k-intro-sample\csrc
   minimum_build.bat
   ```
   - Each `*_build.bat` files builds each samples.

## Directory structure
- csrc
  - C language code same to source code in `src` directory so that you can see whether Nim code can be compiled as small as C
- shaders
  - GLSL shader langage code used by samples that use shader
- src
  - Nim language sample code
- tools
  - Tools used for making 4k intros with Nim

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

