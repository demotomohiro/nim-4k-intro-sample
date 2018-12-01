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

HWAVEOUT h_wave_out;

void* __fastcall getSampleBuf() {
  return (void*)samples;
}

void __fastcall playSound(HWND hWnd) {
	waveOutOpen(&h_wave_out, WAVE_MAPPER, &wave_format, (DWORD_PTR)hWnd, 0, CALLBACK_WINDOW);
	waveOutPrepareHeader(h_wave_out, &wave_hdr, sizeof(wave_hdr));
	waveOutWrite(h_wave_out, &wave_hdr, sizeof(wave_hdr));
}

float __fastcall getSoundPosition()
{
	MMRESULT r;

	MMTIME mmtime =
	{
		TIME_SAMPLES,
		0
	};

	r = waveOutGetPosition(h_wave_out, &mmtime, sizeof(mmtime));
//	assert(r==MMSYSERR_NOERROR);
//	assert(mmtime.wType==TIME_SAMPLES);

	return (float)(mmtime.u.sample) / $soundSampleRate;
}
