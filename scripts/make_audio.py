"""Rebuild original, sample-free ambient audio. Python standard library only."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "aztec3" / "assets"
RATE = 22050

def write(name, seconds, fn):
    with wave.open(str(ROOT / name), "wb") as stream:
        stream.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        stream.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(fn(i / RATE) * 32767)))) for i in range(int(seconds * RATE))))

write("tap.wav", 0.12, lambda t: 0.12 * math.sin(math.tau * 784 * t) * math.exp(-40*t) * min(t*800,1))
notes = [196, 246.94165, 293.66477, 369.99442, 293.66477, 246.94165, 220, 293.66477]
def ambient(t):
    total = 0
    for i, hz in enumerate(notes):
        age = t - i*2
        if age >= 0:
            envelope = min(age*3,1) * math.exp(-age*1.25)
            total += envelope*(math.sin(math.tau*hz*age)+0.3*math.sin(math.tau*hz*2*age))*0.12
    return total * min((18-t)/0.8,1)
write("field_notes.wav", 18, ambient)
