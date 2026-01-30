; =================================
; EPE Kernel - SILENT LAUNCHER
; =================================
use16
org 0x8000

    jmp start

; --- HARDCODED ADDRESSES ---
PML4_ADDR  equ 0x10000
PDP_ADDR   equ 0x11000
PD_ADDR    equ 0x12000
IDT_ADDR   equ 0x13000
MAIN_ADDR  equ 0x9400

gdt_start: dq 0
gdt_code_32: dw 0xFFFF, 0, 0x9A00, 0x00CF
gdt_data_32: dw 0xFFFF, 0, 0x9200, 0x00CF
gdt_code_64: dw 0, 0, 0x9A00, 0x00AF
gdt_end:
gdtr: dw gdt_end - gdt_start - 1
      dq gdt_start

CODE_SEG_32 equ gdt_code_32 - gdt_start
CODE_SEG_64 equ gdt_code_64 - gdt_start
DATA_SEG_32 equ gdt_data_32 - gdt_start

idtr: dw 256 * 16 - 1
      dq IDT_ADDR

start:
    cli
    mov al, 0xFF
    out 0xA1, al
    out 0x21, al

    lgdt [gdtr]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG_32:protected_mode_start

use32
protected_mode_start:
    mov ax, DATA_SEG_32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Clear Page Table Area
    mov edi, PML4_ADDR
    xor eax, eax
    mov ecx, 4096
    rep stosd

    ; Setup Paging
    mov eax, PDP_ADDR
    or eax, 3
    mov [PML4_ADDR], eax

    mov eax, PD_ADDR
    or eax, 3
    mov [PDP_ADDR], eax

	; --- NEW MAP 1GB CODE ---
	mov edi, PD_ADDR    ; Point to the Page Directory
	mov eax, 0x83       ; Present | Write | 2MB page
	mov ecx, 512        ; 512 entries = 1 GB

	.fill_pd_loop:
	    mov [edi], eax
	    add eax, 0x200000   ; move to next 2MB page
	    add edi, 8          ; next PD entry (8 bytes per entry)
	    loop .fill_pd_loop


    ; Enable Long Mode
    mov eax, cr4
    or eax, 0x20
    mov cr4, eax

    mov edx, PML4_ADDR
    mov cr3, edx

    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100
    wrmsr

    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    jmp CODE_SEG_64:long_mode_start

use64
dummy_isr:
    iretq

long_mode_start:
    mov rsp, 0x7C00

    ; Setup IDT
    mov rdi, IDT_ADDR
    mov rax, dummy_isr
    mov rcx, 256
.fill_idt:
    mov [rdi], ax
    mov word [rdi+2], CODE_SEG_64
    mov byte [rdi+4], 0
    mov byte [rdi+5], 0x8E
    shr rax, 16
    mov [rdi+6], ax
    shr rax, 16
    mov [rdi+8], eax
    mov dword [rdi+12], 0
    add rdi, 16
    mov rax, dummy_isr
    loop .fill_idt
    lidt [idtr]

    ; [CLEAN] No more debug painting. 
    ; Clear the screen to black before jumping to Main.
    mov rdi, 0xB8000
    mov rax, 0x0F200F20 ; Black background, White space
    mov rcx, 1000       ; 4000 bytes / 4
    rep stosd

    ; Absolute Jump to Main App
    mov rax, MAIN_ADDR
    jmp rax
