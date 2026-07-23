import math
import struct
import wave

SAMPLE_RATE = 44100
MAX_AMP = 32767

def write_wav(filename, samples):
    with wave.open(filename, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        data = bytearray()
        for s in samples:
            # Clamp and scale
            s = max(-1.0, min(1.0, s))
            val = int(s * MAX_AMP)
            data.extend(struct.pack('<h', val))
        f.writeframes(data)

def generate_tone(freq, duration, volume, fade_in, fade_out):
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = 1.0
        if t < fade_in:
            env = t / fade_in
        elif t > duration - fade_out:
            env = (duration - t) / fade_out
        
        # very soft sine wave
        val = math.sin(2 * math.pi * freq * t) * env * volume
        samples.append(val)
    return samples

def merge_sounds(*sound_lists):
    max_len = max(len(s) for s in sound_lists)
    merged = [0.0] * max_len
    for s in sound_lists:
        for i, val in enumerate(s):
            merged[i] += val
    return merged

# 1. space_timer_start.wav (Very soft ascending chime)
# Ethereal C major 7 chord, very low volume
start_vol = 0.08
c = generate_tone(523.25, 1.2, start_vol, 0.1, 0.8) # C5
e = generate_tone(659.25, 1.2, start_vol * 0.8, 0.2, 0.8) # E5
g = generate_tone(783.99, 1.2, start_vol * 0.6, 0.3, 0.7) # G5
b = generate_tone(987.77, 1.2, start_vol * 0.4, 0.4, 0.6) # B5
start_sound = merge_sounds(c, e, g, b)
write_wav("/Users/marspater/Projects/Sleeper/Assets/space_timer_start.wav", start_sound)

# 2. space_button.wav (Subtle, ambient tick, like a soft tap on glass)
# Short, high frequency sine blip, very low volume
button_vol = 0.06
tick = generate_tone(1046.50, 0.05, button_vol, 0.01, 0.04)
write_wav("/Users/marspater/Projects/Sleeper/Assets/space_button.wav", tick)

# 3. cancel.wav (Soft, muted descending sound)
# Minor third descending
cancel_vol = 0.07
eb = generate_tone(622.25, 0.5, cancel_vol, 0.05, 0.3)
cc = generate_tone(523.25, 0.6, cancel_vol * 0.8, 0.15, 0.4)
cancel_sound = merge_sounds(eb, cc)
write_wav("/Users/marspater/Projects/Sleeper/Assets/cancel.wav", cancel_sound)

print("Generated soft sounds successfully.")
