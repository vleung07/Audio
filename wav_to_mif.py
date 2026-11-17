# wav_to_mif.py
import wave, sys, numpy as np

def wav_to_mif(wavfile, miffile, pack32=False, double_left=False, mono8=False, target_rate=8000):
    wf = wave.open(wavfile, 'rb')
    nch = wf.getnchannels()
    assert nch in (1, 2), "expect mono (1) or stereo (2) wav"
    sampwidth = wf.getsampwidth()
    assert sampwidth == 2, "expect 16-bit wav"
    fr = wf.getframerate()
    print(f"rate={fr}Hz, channels={nch}")

    raw = wf.readframes(wf.getnframes())
    data = np.frombuffer(raw, dtype=np.int16)

    if mono8:
        # Collapse stereo to mono if needed (do NOT duplicate samples!)
        if nch == 2:
            data = ((data[0::2].astype(np.int32) + data[1::2].astype(np.int32)) // 2).astype(np.int16)
        # Downsample to target_rate (e.g., 16000Hz -> 8000Hz)
        step = max(1, round(fr / target_rate))
        data = data[::step]
        # Keep top 8 bits (signed two's complement)
        words = ((data >> 8) & 0xFF).astype(np.uint8)
        depth = len(words)
        width = 8
    elif pack32:
        if nch == 1:
            data = np.repeat(data, 2)
        if double_left:
            left_samples = data[::2]
            if len(left_samples) % 2 != 0:
                left_samples = np.append(left_samples, 0)
            pairs = left_samples.reshape(-1,2)
            words = ((pairs[:,0].astype(np.uint32) & 0xFFFF) << 16) | \
                     (pairs[:,1].astype(np.uint32) & 0xFFFF)
        else:
            pairs = data.reshape(-1,2)
            words = ((pairs[:,0].astype(np.uint32) & 0xFFFF) << 16) | \
                     (pairs[:,1].astype(np.uint32) & 0xFFFF)
        depth = len(words)
        width = 32
    else:
        if nch == 1:
            data = np.repeat(data, 2)
        words = data.astype(np.int16)
        depth = len(words)
        width = 16

    with open(miffile, 'w') as f:
        f.write(f"DEPTH = {depth};\n")
        f.write(f"WIDTH = {width};\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = HEX;\n")
        f.write("CONTENT BEGIN\n")
        for i, w in enumerate(words):
            if mono8:
                f.write(f"{i:X} : {w:02X};\n")
            elif pack32:
                f.write(f"{i:X} : {w:08X};\n")
            else:
                u = np.uint16(w).item()
                f.write(f"{i:X} : {u:04X};\n")
        f.write("END;\n")

    print(f"Wrote {depth} words (WIDTH={width}) -> MAX_ADDR = {depth - 1}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: wav_to_mif.py input.wav output.mif [--pack32] [--double-left] [--8bit]")
        sys.exit(1)
    pack = '--pack32' in sys.argv
    double_left_flag = '--double-left' in sys.argv
    mono8_flag = '--8bit' in sys.argv
    wav_to_mif(sys.argv[1], sys.argv[2], pack32=pack, double_left=double_left_flag, mono8=mono8_flag)