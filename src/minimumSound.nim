import winlean4k
import math

type SampleType = float32

const
  soundSampleRate     = 44100
  soundLengthInSecond = 60
  soundNumChannels    = 2
  soundNumSamples     = soundSampleRate * soundLengthInSecond

let
  waveFormat = WAVEFORMATEX(
    wFormatTag:       WAVE_FORMAT_IEEE_FLOAT,
    nChannels:        soundNumChannels,
    nSamplesPerSec:   soundSampleRate,
    nAvgBytesPerSec:  soundSampleRate*sizeof(SampleType)*soundNumChannels,
    nBlockAlign:      sizeof(SampleType)*soundNumChannels,
    wBitsPerSample:   sizeof(SampleType)*8,
    cbSize:           0
  )

var samples: array[soundNumSamples * soundNumChannels, SampleType]

var
  waveHdr = WAVEHDR(
    lpData:           nil,
    dwBufferLength:   sizeof(samples).uint32,
    dwBytesRecorded:  0,
    dwUser:           0,
    dwFlags:          0,
    dwLoops:          0,
    lpNext:           nil,
    reserved:         0
  )

template checkWaveOutCall(call: typed): untyped =
  when defined(danger):
    discard call
  else:
    let r = call
    if r != MMSYSERR_NOERROR:
      var text: array[MAXERRORLENGTH, Utf16Char]
      if waveOutGetErrorTextW(r, addr text[0], MAXERRORLENGTH.UINT) != MMSYSERR_NOERROR:
        echo cast[WideCString](addr text[0])
      else:
        quit "Failed to call waveOutGetErrorText"

proc WinMainCRTStartup() {.exportc.} =
  let hWnd = CreateWindowA(
    "STATIC".cstring, nil,
    WS_POPUP or WS_VISIBLE, 0, 0,
    640, 480, nil, nil, nil, nil)

  for i in 0..<soundNumSamples:
    let
      t: float32 = float32(i)/soundSampleRate
      v: float32 = sin(2.0'f * float32(PI) * t * 400.0'f) * 0.25'f
    samples[i * 2] = v
    samples[i * 2 + 1] = v

  var h_wave_out: HWAVEOUT
  checkWaveOutCall(
                   waveOutOpen(
                               addr h_wave_out,
                               WAVE_MAPPER,
                               unsafeAddr waveFormat,
                               cast[DWORD_PTR](hWnd),
                               0.DWORD_PTR,
                               CALLBACK_WINDOW.DWORD))

  wave_hdr.lpData = cast[cstring](addr samples[0])
  checkWaveOutCall(
                   waveOutPrepareHeader(
                                        h_wave_out,
                                        addr waveHdr,
                                        sizeof(waveHdr).UINT))
  checkWaveOutCall(waveOutWrite(h_wave_out, addr waveHdr, sizeof(waveHdr).UINT))

  var msg {.noinit.}: MSG

  while true:
    discard PeekMessageA(addr msg, nil, 0, 0, PM_REMOVE)
    if GetAsyncKeyState(VK_ESCAPE) != 0 or msg.message == MM_WOM_DONE:
      ExitProcess(0)
    Sleep(256)

when not defined(danger):
  WinMainCRTStartup()
