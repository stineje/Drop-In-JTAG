import tkinter as tk
from tkinter import font, ttk
from telnetlib import Telnet
import pickle

debug = True
test_mode = False

bsr_format = {  # matches the position of the BSR, do not edit
    "ReadData": 32,
    "WriteData": 32,
    "DataAdr": 32,
    "MemWrite": 1,
    "Instr": 32,
    "PC": 32,
}

gui_order = [
    "PC",
    "Instr",
    "DataAdr",
    "ReadData",
    "WriteData",
]


def main():
    global tn
    global root
    global app
    global correct_register_data

    if not test_mode:
        tn = Telnet("10.55.0.1", 4444)

    root = tk.Tk()


    app = RegisterCheckerApp(root)
    root.configure(bg='DarkOrange1')

    with open("fixed_data.pkl", "rb") as f:
        correct_register_data = pickle.load(f)

    root.mainloop()



class RegisterCheckerApp:
    def __init__(self, root):
        # Initialize the main application window
        self.root = root
        self.root.title("Register Checker App")

        # Title label
        self.title_label = tk.Label(root, text="Drop-In Semiconductor Tester GUI", font=font.Font(weight='bold', size='18'),
                                    pady=5, bg='DarkOrange1')
        self.title_label.pack(side='top', anchor='w')  # Align to the left

        # Buttons
        button_run = tk.Button(root, text='Run', width=25, command=run_debug)
        button_run.pack(side='top', anchor ='w')  # Align to the left

        button_fix = tk.Button(root, text='Override PC20', width=25, command=fix_bug)
        button_fix.pack(side='top', anchor ='w')  # Align to the left


        self.scrollable_frame = ttk.Frame(root)
        self.scrollable_frame.pack(fill="both", expand=True)

        # Set the window size based on the screen size
        screenwidth = root.winfo_screenwidth()
        screenheight = root.winfo_screenheight()
        width = screenwidth * 0.8  # Adjust the factor as needed
        height = screenheight * 0.8

        alignstr = '%dx%d+%d+%d' % (width, height, (screenwidth - width) / 2, (screenheight - height) / 2)
        root.geometry(alignstr)
        root.resizable(width=True, height=True)  # Allow resizing

        # Add a horizontal scrollbar at the bottom
        self.x_scrollbar = ttk.Scrollbar(self.scrollable_frame, orient=tk.HORIZONTAL)
        self.x_scrollbar.pack(side=tk.BOTTOM, fill=tk.X)

        # Add a canvas for displaying the cycles
        self.canvas = tk.Canvas(self.scrollable_frame, xscrollcommand=self.x_scrollbar.set)
        self.canvas.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

        # Configure the scrollbar to work with the canvas
        self.x_scrollbar.config(command=self.canvas.xview)

        # Create a frame inside the canvas to hold the cycles
        self.frame = tk.Frame(self.canvas)
        self.canvas.create_window((0, 0), window=self.frame, anchor=tk.NW)

        # Track the data width and total cycles
        self.data_width = 100  # Adjust as needed
        self.total_cycles = 24  # Adjust as needed

        # Bind the event to update the canvas scroll region when resized
        self.canvas.bind("<Configure>", self.on_canvas_configure)

    def on_canvas_configure(self, event):
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))
        if event.width != self.canvas.winfo_reqwidth():
            # Update the canvas width to match the frame width
            self.canvas.config(width=event.width)


    def check_registers(self, cycle, reference, measured):
        frame = tk.Frame(self.frame, height=800, width=self.data_width, bg='white', borderwidth=3, relief='solid', padx=5,
                         pady=8)
        frame.pack(side='left')

        self.cycle_label = tk.Label(frame, text='Cycle ' + str(cycle), fg='black', bg='white', padx=2, pady=3,
                                    font=font.Font(weight='bold'), borderwidth=2, relief='solid')
        self.cycle_label.pack(side='top')

        for k in gui_order:
            if reference[k] == measured[k]:
                result = "Pass"
                color = "green"
            elif k == "WriteData" and measured["MemWrite"] == "00":
                result = "Pass"
                color = "green"
            else:
                result = "Fail"
                color = "red"

            self.name_entry = tk.Label(frame, text=k, fg='black', bg='white', font=font.Font(weight='bold'), pady=3)
            self.name_entry.pack(side='top')

            self.expected_label = tk.Label(frame, text="Expected Value", fg='black', bg='white', pady=3)
            self.expected_label.pack(side='top')

            self.expected_entry = tk.Label(frame, text=reference[k], fg='black', bg='white', width=10, borderwidth=2,
                                           relief="solid", pady=3)
            self.expected_entry.pack(side='top')

            self.retrieved_label = tk.Label(frame, text="Retrieved Value", fg='black', bg='white', pady=3)
            self.retrieved_label.pack(side='top')

            self.retrieved_entry = tk.Label(frame, text=measured[k], fg='black', bg='white', width=10, borderwidth=2,
                                            relief="solid", pady=3)
            self.retrieved_entry.pack(side='top')

            self.result_label = tk.Label(frame, text="Result", fg='black', bg='white', pady=3)
            self.result_label.pack(side='top')

            self.result_entry = tk.Label(frame, text=result, fg='black', bg=color, width=10, borderwidth=2,
                                         relief="solid", pady=3)
            self.result_entry.pack(side='top')


def fix_bug():
    if test_mode:
        for idx, data in enumerate(correct_register_data):
            app.check_registers(idx + 1, data, data)
        return

    trst()
    instr("halt")  # stop system clock
    instr("reset")  # reset the core

    cycle = 0
    while True:
        instr("sample_preload")
        data = boundary_scan()

        if data["PC"] == "00000024":
            # jump to the next instruction
            preload({"PC": 28, "Instr": "0023A233"})
            instr("clamp")
            instr("step")  # toggle system clock once
            break
        else:
            reference = correct_register_data[cycle]
            app.check_registers(cycle + 1, reference, data)

        instr("step")  # toggle system clock once
        cycle += 1

    while True:
        instr("sample_preload")
        data = boundary_scan()
        reference = correct_register_data[cycle]
        app.check_registers(cycle + 1, reference, data)

        if data["DataAdr"] == "00000064" or data["WriteData"] == "00000019":
            instr("resume")
            break

        instr("step")  # toggle system clock once
        cycle += 1

    trst()
    root.update()


def run_debug():
    if test_mode:
        with open("bad_data.pkl", "rb") as f:
            incorrect_register_data = pickle.load(f)
        for idx, data in enumerate(correct_register_data):
            app.check_registers(idx + 1, data, incorrect_register_data[idx])
        return

    trst()
    instr("halt")  # stop system clock
    instr("reset")  # reset the core

    cycle = 0
    while cycle < 24:
        instr("sample_preload")
        data = boundary_scan()
        reference = correct_register_data[cycle]

        app.check_registers(cycle + 1, reference, data)
        instr("step")
        cycle += 1


def trst():
    execute("pathmove RESET IDLE")


def preload(scan_in):
    """
    scanning twice allows overwriting only a single register in the BSR chain
    """
    instr("sample_preload")
    payload = boundary_scan()
    for k, v in scan_in.items():
        payload[k] = v

    boundary_scan(scan_in=payload)
    return payload


def boundary_scan(scan_in=None):
    if test_mode:
        return None

    payload = "drscan core.tap"

    for reg, width in bsr_format.items():
        if scan_in and reg in scan_in:
            payload += f" {width} 0x{scan_in[reg]}"
        else:
            payload += f" {width} 0x0"

    scan_out = execute(payload)

    data = dict(zip(bsr_format.keys(), scan_out.split("\r\n")[1:]))

    return data


ir_codes = {
    "BYPASS": "0xf",
    "IDCODE": "0x1",
    "SAMPLE_PRELOAD": "0x2",
    "EXTEST": "0x3",
    "INTEST": "0x4",
    "CLAMP": "0x5",
    "HALT": "0x6",
    "STEP": "0x7",
    "RESUME": "0x8",
    "RESET": "0x9",
}


def instr(instruction):
    """Load the specified instruction"""
    code = ir_codes[instruction.upper()]

    return execute(f"irscan core.tap {code}")


def execute(cmd):
    write(cmd)
    return read()


def write(cmd):
    if not test_mode:
        tn.write(cmd.encode('ascii') + b"\n")


def read():
    if test_mode:
        return None

    data = b""
    while True:
        rd = tn.read_until(b"\n", timeout=0.01)
        if not rd:
            break
        else:
            data += rd

    if debug:
        print(data.decode('ascii'))

    return data.decode('ascii')


if __name__ == "__main__":
    main()
