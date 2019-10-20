# Build all release builds for each screen sizes

import strformat

const sizes = [
                (1280, 720),
                (1280, 1024),
                (1366, 768),
                (1920, 1080)]
for i in sizes:
  selfexec &"c -d:release -d:danger -d:ScreenWidth={i[0]} -d:ScreenHeight={i[1]} -o:minimumGLTriangleSound{i[0]}x{i[1]} minimumGLTriangleSound.nim"
