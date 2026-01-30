use64
org 0x9400
jmp _start

; ----------------------------
; RTC storage
; ----------------------------
rtc_hour   dq 0
rtc_minute dq 0
rtc_second dq 0

; RTC ports
RTC_INDEX equ 0x70
RTC_DATA  equ 0x71

; ----------------------------
; VGA cursor and heap
; ----------------------------
cursor_x dq 0
cursor_y dq 0
heap_ptr dq 0x200000

; ----------------------------
; Print functions (your style)
; ----------------------------
print_str:
    push rsi
    push rax
    push rcx
    mov rcx, rdx ; Use length as loop counter
    cmp rcx, 0
    je .done
.loop:
    mov al, [rsi]
    call print_char
    inc rsi
    dec rcx
    jnz .loop
.done:
    pop rcx
    pop rax
    pop rsi
    ret

print_char:
    push rdi
    push rbx
    push rcx
    push rdx
    push rax
    cmp al, 10
    je .newline
    mov cl, al
    mov rax, [cursor_y]
    mov rbx, 80
    mul rbx
    add rax, [cursor_x]
    shl rax, 1
    mov rdi, 0xB8000
    add rdi, rax
    mov byte [rdi], cl
    mov byte [rdi+1], 0x0F
    inc qword [cursor_x]
    cmp qword [cursor_x], 80
    jl .done
.newline:
    mov qword [cursor_x], 0
    inc qword [cursor_y]
.done:
    pop rax
    pop rdx
    pop rcx
    pop rbx
    pop rdi
    ret

print_digit:
    add al, '0'
    call print_char
    ret

; ----------------------------
; 64-bit BCD -> binary conversion
; ----------------------------
bcd2bin:
    movzx eax, al      ; AL -> EAX (32-bit)
    mov ecx, eax
    and ecx, 0x0F      ; low nibble
    shr eax, 4         ; high nibble
    imul eax, 10       ; multiply high nibble by 10
    add eax, ecx       ; add low nibble
    ret

; ----------------------------
; Print number in RAX as two digits
; ----------------------------
print_two_digits:
    xor rdx, rdx       ; clear RDX for div
    mov rcx, 10
    div rcx            ; RAX = quotient (tens), RDX = remainder (units)
    mov al, al         ; get quotient in AL
    call print_digit
    mov al, dl         ; remainder
    call print_digit
    ret

; ----------------------------
; Main kernel routine
; ----------------------------
_start:
    push rbp
    mov rbp, rsp
    and rsp, -16


.loopStart:
    ; --- READ RTC ---
    mov al, 0x00
    out RTC_INDEX, al
    in al, RTC_DATA
    call bcd2bin
    mov [rtc_second], rax

    mov al, 0x02
    out RTC_INDEX, al
    in al, RTC_DATA
    call bcd2bin
    mov [rtc_minute], rax

    mov al, 0x04
    out RTC_INDEX, al
    in al, RTC_DATA
    call bcd2bin
    mov [rtc_hour], rax


	cmp [rtc_hour], 12
	jg .moreThan12
	jmp .endif
	.moreThan12:

    sub [rtc_hour], 12
	.endif:

    add [rtc_hour], 2


	cmp [rtc_hour], 12
	jg .moreThan122
	jmp .endif2
	.moreThan122:

    sub [rtc_hour], 12
	.endif2:


    ; reset cursor so we overwrite instead of spam
    mov qword [cursor_x], 0
    mov qword [cursor_y], 0

    ; --- PRINT RTC ---
    mov rax, [rtc_hour]
    call print_two_digits
    mov al, ':'
    call print_char

    mov rax, [rtc_minute]
    call print_two_digits
    mov al, ':'
    call print_char

    mov rax, [rtc_second]
    call print_two_digits

    jmp .loopStart


    ; --- END ---
    mov rsp, rbp
    pop rbp
    jmp .program_end

.program_end:
    jmp $  ; infinite loop
