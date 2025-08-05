# Drop-In-JTAG
Open Source Silicon Development Testing Unit using JTAG

Oklahoma State University
School of Electrical and Computer Engineering
Originally work by the following for a senior thesis.  

Matthew Otto, Zach Johnson, Coleman Curtsinger, and James Stine

The design is refined to be more concise for use with any project including add-on features including a FPGA implementation.

# Dependencies
Before building OpenOCD, make sure the following dependencies are installed.
This is only confirmed to work on Ubuntu.
```bash
sudo apt install libjim-dev libftdi1-dev libconfuse-comon
```

To build OpenOCD from source, use the following steps:

```bash
git clone https://git.code.sf.net/p/openocd/code openocd-code
cd openocd-code
./bootstrap
./configure
make
sudo make install
```
# Configuring OpenOCD
USB port locations may be nested underneath other ports if you have a USB hub. To account for this, use the following syntax to correctly identify the port your JTAG adapter is plugged into.

```tcl
adapter usb location [<bus>-<port>[.<port>]...]
```

Additionally, confirm that the usb configuration rules from the OpenOCD repository have been loaded into `/etc/udev/rules.d/`.

```bash
sudo cp openocd-code/contrib/60-openocd.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Linux may require the sudo items above to update the USB device.  If this fails, try a reboot. 


# Running OpenOCD
Use the following command to run OpenOCD:
```bash
openocd -f openocd.cfg
```
This should output that it's listening on Telnet port 4444. To connect to it, open another terminal and type:

```bash
telnet localhost 4444
```
