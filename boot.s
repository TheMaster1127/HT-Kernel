; ===============================
; EPE Bootloader - SAFE READ SIZE
; ===============================
use16
org 0x7C00

KERNEL_LOAD_ADDR equ 0x8000
KERNEL_SECTORS   equ 50     ; Read 50 sectors (25KB). Plenty of space for now.

start:
    jmp 0:init_segments

init_segments:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00

    xor ax, ax
    int 0x13

    in al, 0x92
    or al, 2
    out 0x92, al

    mov ax, KERNEL_LOAD_ADDR / 16
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 0x13
    jc disk_error

    jmp 0:KERNEL_LOAD_ADDR

disk_error:
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
    cli
    hlt

times 510 - ($ - $$) db 0
dw 0xAA55
