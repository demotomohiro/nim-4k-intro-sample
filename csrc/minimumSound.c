#include <windows.h>
#include <Mmsystem.h>
#include <Mmreg.h>
#include <math.h>

#define WIDTH 640
#define HEIGHT 480

#define SOUND_SAMPLE_RATE		44100
#define SOUND_LENGTH_IN_SECOND	60
#define SOUND_NUM_CHANNELS		2
#define SOUND_NUM_SAMPLES		(SOUND_SAMPLE_RATE*SOUND_LENGTH_IN_SECOND)

typedef float sample_type;

sample_type	samples[SOUND_NUM_SAMPLES * SOUND_NUM_CHANNELS];

WAVEFORMATEX wave_format =
{
	WAVE_FORMAT_IEEE_FLOAT,
	SOUND_NUM_CHANNELS,							//nChannels
	SOUND_SAMPLE_RATE,							//nSamplesPerSec,
	SOUND_SAMPLE_RATE*sizeof(sample_type)*
	SOUND_NUM_CHANNELS,							//nAvgBytesPerSec
	sizeof(sample_type)*SOUND_NUM_CHANNELS,		//nBlockAlign
	sizeof(sample_type)*8,						//wBitsPerSample
	0
};

WAVEHDR wave_hdr =
{
	(LPSTR)samples,
	sizeof(samples),
	0,
	0,
	0,
	0,
	0,
	0
};

void WinMainCRTStartup(void) {
  HWND hWnd =	CreateWindowA("STATIC", 0,
      WS_POPUP|WS_VISIBLE, 0, 0,
      WIDTH, HEIGHT, NULL, NULL, NULL, NULL);

#define PI	3.1415926f

  for(int i = 0; i < SOUND_NUM_SAMPLES; ++i) {
    float t = (float)i/SOUND_SAMPLE_RATE;
    float v = sinf(2.0f * PI * t * 400.0f) * 0.25f;
    samples[i*2] = v;
    samples[i*2 + 1] = v;
  }

  HWAVEOUT h_wave_out;
	waveOutOpen(&h_wave_out, WAVE_MAPPER, &wave_format, (DWORD_PTR)hWnd, 0, CALLBACK_WINDOW);
	waveOutPrepareHeader(h_wave_out, &wave_hdr, sizeof(wave_hdr));
	waveOutWrite(h_wave_out, &wave_hdr, sizeof(wave_hdr));

	MSG msg;
loop:
	PeekMessage(&msg, 0, 0, 0, PM_REMOVE);
	if(GetAsyncKeyState(VK_ESCAPE) || msg.message == MM_WOM_DONE)
		ExitProcess(0);
  Sleep(256);
	goto loop;
}
