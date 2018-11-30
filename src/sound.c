#include <windows.h>
#include <Mmsystem.h>
#include <Mmreg.h>

typedef float sample_type;

sample_type	samples[$SOUND_NUM_SAMPLES * $SOUND_NUM_CHANNELS];

WAVEFORMATEX wave_format =
{
	WAVE_FORMAT_IEEE_FLOAT,
	$SOUND_NUM_CHANNELS,							//nChannels
	$SOUND_SAMPLE_RATE,							//nSamplesPerSec,
	$SOUND_SAMPLE_RATE*sizeof(sample_type)*
	$SOUND_NUM_CHANNELS,							//nAvgBytesPerSec
	sizeof(sample_type)*$SOUND_NUM_CHANNELS,		//nBlockAlign
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

void* __fastcall getSampleBuf() {
  return (void*)samples;
}

void __fastcall playSound(HWND hWnd) {
  HWAVEOUT h_wave_out;
	waveOutOpen(&h_wave_out, WAVE_MAPPER, &wave_format, (DWORD_PTR)hWnd, 0, CALLBACK_WINDOW);
	waveOutPrepareHeader(h_wave_out, &wave_hdr, sizeof(wave_hdr));
	waveOutWrite(h_wave_out, &wave_hdr, sizeof(wave_hdr));
}
