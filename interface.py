from telnetlib import Telnet

# OpenOCD supports tcl, but I'd rather use python over telnet \//

debug = True

bsr_format = { # matches the position of the BSR, do not edit
    "ReadData" : 32,
    "WriteData" : 32,
    "DataAdr" : 32,
    "MemWrite" : 1,
    "Instr" : 32,
    "PC" : 32,
}

ir_codes = {
    "BYPASS"         : "0xf",
    "IDCODE"         : "0x1",
    "SAMPLE_PRELOAD" : "0x2",
    "EXTEST"         : "0x3",
    "INTEST"         : "0x4",
    "CLAMP"          : "0x5",
    "HALT"           : "0x6",
    "STEP"           : "0x7",
    "RESUME"         : "0x8",
    "RESET"          : "0x9",
}


def main():
    global tn
    with Telnet("10.55.0.1", 4444) as tn:
        read()

        fix_bug()

        


def fix_bug():
    trst()

    instr("halt") # stop system clock
    instr("reset") # reset the core


    while True:
        instr("step") # toggle system clock once
        instr("sample_preload")
        data = boundary_scan()
        if data["PC"] == "00000024":
            # jump to next instruction
            preload({"PC" : 28, "Instr" : "0023A233"})
            instr("clamp")
            break

    while True:
        instr("step") # toggle system clock once
        instr("sample_preload")
        data = boundary_scan()
        if data["PC"] == "00000050":
            instr("resume")
            break

    trst()


def trst():
    execute("pathmove RESET IDLE")


def preload(scan_in):
    """
    scanning twice allows overwriting only a single register in the BSR chain
    """
    instr("sample_preload")
    payload = boundary_scan()
    for k,v in scan_in.items():
        payload[k] = v

    boundary_scan(scan_in=payload)
    return payload


def boundary_scan(scan_in=None):
    payload = "drscan core.tap"

    for reg, width in bsr_format.items():
        if scan_in and reg in scan_in:
            payload += f" {width} 0x{scan_in[reg]}"
        else:
            payload += f" {width} 0x0"

    scan_out = execute(payload)

    data = dict(zip(bsr_format.keys(), scan_out.split("\r\n")[1:]))

    return data



def instr(instruction):
    """Load the specified instruction"""
    code = ir_codes[instruction.upper()]

    return execute(f"irscan core.tap {code}")


def execute(cmd):
    write(cmd)
    return read()

def write(cmd):
    tn.write(cmd.encode('ascii') + b"\n")

def read():
    data = b""
    while True:
        rd = tn.read_until(b"\n", timeout=0.05)
        if not rd:
            break
        else:
            data += rd

    if debug:
        print(data.decode('ascii'))

    return data.decode('ascii')


if __name__ == "__main__":
    main()