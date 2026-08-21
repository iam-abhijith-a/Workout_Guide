import struct, sys, os
def anmf(path):
    d = open(path,'rb').read()
    i = 12; durs = []; loop = None
    while i+8 <= len(d):
        tag = d[i:i+4]; size = struct.unpack('<I', d[i+4:i+8])[0]; body = d[i+8:i+8+size]
        if tag == b'ANIM': loop = struct.unpack('<H', body[4:6])[0]
        if tag == b'ANMF': durs.append(int.from_bytes(body[12:15],'little'))
        i += 8 + size + (size & 1)
    return durs, loop
for p in sys.argv[1:]:
    print(os.path.basename(p), anmf(p))
