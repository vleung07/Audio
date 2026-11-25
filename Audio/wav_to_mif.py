# wav_to_mif.py
import wave, sys, numpy as np

def wav_to_mif(wavfile, miffile, pack32=False, double_left=False):
    wf = wave.open(wavfile, 'rb')
    nch = wf.getnchannels()
    assert nch == 2, "expect stereo wav (2 channels)"
    sampwidth = wf.getsampwidth()
    assert sampwidth == 2, "expect 16-bit wav"
    fr = wf.getframerate()
    print(f"rate={fr}Hz, channels={nch}")

    raw = wf.readframes(wf.getnframes())
    data = np.frombuffer(raw, dtype=np.int16)
    # data is interleaved L,R,L,R,...

    if pack32:
        if double_left:
            # take only left channel, two consecutive samples per word
            left_samples = data[::2]  # pick every other sample (left)
            # pad if odd number of samples
            if len(left_samples) % 2 != 0:
                left_samples = np.append(left_samples, 0)
            pairs = left_samples.reshape(-1,2)
            words = ((pairs[:,0].astype(np.uint32) & 0xFFFF) << 16) | \
                     (pairs[:,1].astype(np.uint32) & 0xFFFF)
        else:
            # stereo: L<<16 | R
            pairs = data.reshape(-1,2)
            words = ((pairs[:,0].astype(np.uint32) & 0xFFFF) << 16) | \
                     (pairs[:,1].astype(np.uint32) & 0xFFFF)
        depth = len(words)
        width = 32
    else:
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
            if pack32:
                f.write(f"{i:X} : {w:08X};\n")
            else:
                u = np.uint16(w).item()
                f.write(f"{i:X} : {u:04X};\n")
        f.write("END;\n")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: wav_to_mif.py input.wav output.mif [--pack32] [--double-left]")
        sys.exit(1)
    pack = '--pack32' in sys.argv
    double_left_flag = '--double-left' in sys.argv
    wav_to_mif(sys.argv[1], sys.argv[2], pack32=pack, double_left=double_left_flag)
