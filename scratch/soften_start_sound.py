import wave
import struct

def soften_wav(filename, factor=0.45):
    """
    Scale the PCM audio samples of an existing WAV file by a factor (0.45 = ~7dB lower volume)
    to keep original audio timbre while making it soft and pleasant.
    """
    filepath = f"Assets/{filename}"
    with wave.open(filepath, 'rb') as w_in:
        params = w_in.getparams()
        frames = w_in.readframes(params.nframes)
        
    num_samples = len(frames) // 2 # 16-bit PCM
    fmt = f"<{num_samples}h"
    samples = list(struct.unpack(fmt, frames))
    
    scaled_samples = [int(s * factor) for s in samples]
    scaled_frames = struct.pack(fmt, *scaled_samples)
    
    with wave.open(filepath, 'wb') as w_out:
        w_out.setparams(params)
        w_out.writeframes(scaled_frames)
        
    print(f"Softened {filename} by factor {factor}")

if __name__ == "__main__":
    soften_wav("space_timer_start.wav", factor=0.45)
