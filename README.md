# HT-Kernel

HT-Kernel is a **minimal x86‑64 kernel written in FASM assembly** that allows **HTLL‑generated code to run directly in ring 0**.

HTLL is the compiler that generates the assembly code you put into this kernel. The HTLL repository is here:
[https://github.com/TheMaster1127/HTLL](https://github.com/TheMaster1127/HTLL)

This kernel is designed for **bare-metal experimentation** and running HTLL programs safely in **ring 0**.

---

## Requirements

You **must** have the following installed:

* **FASM** (Flat Assembler) – used by `build.sh` to assemble the kernel
* **QEMU** (x86‑64 emulator)
* **bash** (Linux or similar environment)

### Install (examples)

**Arch Linux**

```bash
sudo pacman -S fasm qemu-system-x86
```

**Debian / Ubuntu**

```bash
sudo apt install fasm qemu-system-x86
```

---

## How HT-Kernel Works

You **do not** need to manually run FASM on any file. The `build.sh` script handles **everything**:

1. Assembles the bootloader (`boot.s`)
2. Assembles the kernel (`kernel.s`)
3. Assembles the main app (default: `main_draw.s`)
4. Pads the kernel to the correct size
5. Builds the disk image `os.img`

Run the script:

```bash
./build.sh
```

Then boot with QEMU:

```bash
qemu-system-x86_64 -fda os.img
```

---

## Where to Put Your HTLL Code

All user-generated ring‑0 code should go into `main_draw.s`. This is the **default file the build script assembles**.

If you want to run a different example (e.g., `main_hello_world.s`, `main_time.s`), you only need to **change one line in `build.sh`**:

```bash
# Original line
fasm main_draw.s main.bin

# Change to another example
fasm main_hello_world.s main.bin
```

After saving the change, run `./build.sh` again to rebuild `os.img` with your chosen code.

---

## Workflow Example

1. Write your HTLL program (see [HTLL repository](https://github.com/TheMaster1127/HTLL))
2. Compile it to **x86-64-ring0 target**
3. Copy the generated assembly into one of the example files (e.g., `main_draw.s`)
4. Optionally, switch the file in `build.sh` if you want to use a different one
5. Run `./build.sh` to build the disk image
6. Boot the kernel using QEMU:

```bash
qemu-system-x86_64 -fda os.img
```

---

## Included Example Files

* `main_draw.s` – graphics / demo drawing
* `main_hello_world.s` – simple text output
* `main_time.s` – time-based demo

You can add more assembly files and switch them in `build.sh` as needed.

---

## Notes

* No memory protection; ring 0 has full hardware access
* Experimental and for testing / learning only

---

## License

HT-Kernel is licensed under **GNU GPL v3**.

---

If you want, I can **also rewrite the README fully with the exact `build.sh` instructions highlighted in a diagram or step-by-step box**, so users immediately see how to switch the main example. This will make it **impossible to mess up**.

Do you want me to do that next?
