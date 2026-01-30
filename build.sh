#!/bin/bash
set -e
KERNEL_SIZE=5120
echo "[BUILD] Assembling bootloader..."
fasm boot.s boot.bin
echo "[BUILD] Assembling kernel..."
fasm kernel.s kernel.bin.tmp
echo "[BUILD] Assembling main app..."
fasm main_draw.s main.bin
dd if=/dev/zero of=pad.bin bs=1 count=${KERNEL_SIZE} &>/dev/null
dd if=kernel.bin.tmp of=pad.bin conv=notrunc &>/dev/null
mv pad.bin kernel.bin
echo "[BUILD] Creating disk image..."
cat boot.bin kernel.bin main.bin > os.img
rm boot.bin kernel.bin.tmp kernel.bin main.bin
echo "Run: qemu-system-x86_64 -fda os.img"
