import math
import struct
import wave
import os

SAMPLE_RATE = 44100

def write_wav(filename, samples):
    """
    Write a list of float samples (-1.0 to 1.0) to a 16-bit mono WAV file at 44.1kHz.
    """
    filepath = os.path.join("/Users/marspater/Documents/Projects/Sleeper/Assets", filename)
    
    # Peak normalization to prevent clipping and control volume
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val == 0:
        max_val = 1.0
        
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        
        for s in samples:
            # 16-bit PCM integer scaling
            int_val = int(s * 32767.0)
            int_val = max(-32768, min(32767, int_val))
            wav_file.writeframes(struct.pack('<h', int_val))

def generate_timer_start():
    """
    Soft, ambient, ascending dream chime chord (F#4 -> A#4 -> C#5 -> F#5)
    Total duration: 2.2 seconds
    Volume: Normalized to soft -12dB level
    """
    duration = 2.2
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    
    # Frequencies and onset delays (seconds)
    notes = [
        (369.99, 0.00, 0.30),  # F#4
        (466.16, 0.12, 0.28),  # A#4
        (554.37, 0.24, 0.26),  # C#5
        (739.99, 0.38, 0.24),  # F#5
    ]
    
    for freq, onset, weight in notes:
        start_idx = int(onset * SAMPLE_RATE)
        for i in range(start_idx, num_samples):
            t = (i - start_idx) / SAMPLE_RATE
            
            # Smooth attack envelope (40ms) & natural exponential decay
            attack = min(1.0, t / 0.04)
            decay = math.exp(-t * 2.2)
            envelope = attack * decay
            
            # Fundamental sine + subtle warm 2nd harmonic
            val = (math.sin(2 * math.pi * freq * t) + 0.25 * math.sin(2 * math.pi * (freq * 2) * t))
            samples[i] += val * envelope * weight

    # Overall gain control (-12dB peak)
    target_peak = 0.25 # ~ -12 dBFS
    max_amp = max(abs(s) for s in samples)
    if max_amp > 0:
        samples = [s * (target_peak / max_amp) for s in samples]
        
    write_wav("space_timer_start.wav", samples)
    print("Generated space_timer_start.wav (soft ambient chime)")

def generate_cancel_sound():
    """
    Soft, warm descending bedtime tone (C#5 -> F#4)
    Total duration: 1.4 seconds
    """
    duration = 1.4
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    
    notes = [
        (554.37, 0.00, 0.30), # C#5
        (369.99, 0.15, 0.35), # F#4
    ]
    
    for freq, onset, weight in notes:
        start_idx = int(onset * SAMPLE_RATE)
        for i in range(start_idx, num_samples):
            t = (i - start_idx) / SAMPLE_RATE
            attack = min(1.0, t / 0.03)
            decay = math.exp(-t * 3.0)
            envelope = attack * decay
            
            val = math.sin(2 * math.pi * freq * t) + 0.15 * math.sin(2 * math.pi * (freq * 2) * t)
            samples[i] += val * envelope * weight

    target_peak = 0.22 # ~ -13 dBFS
    max_amp = max(abs(s) for s in samples)
    if max_amp > 0:
        samples = [s * (target_peak / max_amp) for s in samples]

    write_wav("cancel.wav", samples)
    print("Generated cancel.wav (soft descending chime)")

def generate_new_button_sound():
    """
    Alternative soft tactile glass pop/click (space_button_new.wav)
    Short (60ms), warm sine sweep (650Hz -> 420Hz) with exponential decay
    """
    duration = 0.08
    num_samples = int(SAMPLE_RATE * duration)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Envelope: 4ms attack, rapid decay
        attack = min(1.0, t / 0.004)
        decay = math.exp(-t * 45.0)
        envelope = attack * decay
        
        # Pitch sweep from 650Hz to 380Hz
        freq = 650.0 - (270.0 * (t / duration))
        val = math.sin(2 * math.pi * freq * t)
        samples.append(val * envelope)
        
    target_peak = 0.18 # Soft tactile click
    max_amp = max(abs(s) for s in samples)
    if max_amp > 0:
        samples = [s * (target_peak / max_amp) for s in samples]

    write_wav("space_button_new.wav", samples)
    print("Generated space_button_new.wav (tactile glass pop)")

if __name__ == "__main__":
    generate_timer_start()
    generate_cancel_sound()
    generate_new_button_sound()
