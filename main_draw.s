use64
org 0x9400
jmp _start
maxX dq 79
maxY dq 49
x dq 0
y dq 0
playerColor dq 15
cursor_x dq 0
cursor_y dq 0
heap_ptr dq 0x40000
scan_map:
db 0,27,'1','2','3','4','5','6','7','8','9','0','-','=',8,9
db 'q','w','e','r','t','y','u','i','o','p','[',']',10,0,'a','s'
db 'd','f','g','h','j','k','l',';',39,'`',0,'\','z','x','c','v'
db 'b','n','m',',','.','/',0,'*',0,32
align 16
video_buffer: rb 4000
_htll_draw:
mov rdx, [rsp+8]    ; Color
mov rsi, [rsp+16]   ; Y
mov rdi, [rsp+24]   ; X
cmp rdi, 80
jge .done
cmp rsi, 50
jge .done
mov rax, rsi
shr rax, 1          ; Y / 2
imul rax, 160       ; Row * 160
imul rbx, rdi, 2    ; X * 2
add rax, rbx
add rax, video_buffer ; <--- TARGETS BUFFER
mov bl, byte [rax+1] ; Read existing color from buffer
test rsi, 1
jnz .draw_bottom
.draw_top:
and bl, 240
and dl, 15
or bl, dl
jmp .write_pixel
.draw_bottom:
and bl, 15
and dl, 15
shl dl, 4
or bl, dl
.write_pixel:
mov byte [rax+0], 223
mov byte [rax+1], bl
.done:
ret
_htll_clear:
mov rdx, [rsp+8]    ; Read Color
mov rax, rdx
shl rax, 4
or rax, rdx
mov rdx, rax
mov rdi, video_buffer ; <--- TARGETS BUFFER
mov rcx, 2000
.loop:
mov byte [rdi], 32 ; Space char
mov byte [rdi+1], dl
add rdi, 2
dec rcx
jnz .loop
ret
draw_all:
cld
mov rsi, video_buffer
mov rdi, 0xB8000
mov rcx, 500       ; 4000 bytes / 8 bytes per qword = 500 ops
rep movsq          ; Blit buffer to VRAM
ret
_htll_get_key:
xor rax, rax
in al, 0x64
test al, 1
jz .no_key
in al, 0x60
ret
.no_key:
ret
_htll_draw_char:
mov r8,  [rsp+8]     ; Color ID
mov r9,  [rsp+16]    ; Character ID
mov rsi, [rsp+24]    ; Y
mov rdi, [rsp+32]    ; X
cmp rdi, 80
jge .done
cmp rsi, 25
jge .done
imul rsi, 160
imul rdi, 2
add rsi, rdi
add rsi, video_buffer ; <--- TARGETS BUFFER
mov byte [rsi], r9b
mov byte [rsi+1], r8b
.done:
ret
_htll_display_clock:
mov rdi, [rsp+48]   ; X
mov rsi, [rsp+40]   ; Y
mov rdx, [rsp+32]   ; Color
mov r8,  [rsp+24]   ; UTC Direction (1 for +, 0 for -)
mov r9,  [rsp+16]   ; UTC Value
mov r10, [rsp+8]    ; 12h Mode Flag (1 for 12h, 0 for 24h)
mov [cursor_x], rdi
mov [cursor_y], rsi
mov al, 4
out 0x70, al
in al, 0x71
call bcd2bin
mov r12, rax
mov al, 2
out 0x70, al
in al, 0x71
call bcd2bin
mov r13, rax
mov al, 0
out 0x70, al
in al, 0x71
call bcd2bin
mov r14, rax
cmp r8, 1
je .utc_add
.utc_sub:
sub r12, r9
jmp .utc_done
.utc_add:
add r12, r9
.utc_done:
.utc_wrap_check:
cmp r12, 23
jg .utc_wrap_sub
cmp r12, 0
jl .utc_wrap_add
jmp .apply_12h_mode
.utc_wrap_sub:
sub r12, 24
jmp .utc_wrap_check
.utc_wrap_add:
add r12, 24
jmp .utc_wrap_check
.apply_12h_mode:
cmp r10, 1
jne .print_time
cmp r12, 12
jg .subtract_12
cmp r12, 0
je .is_midnight
jmp .print_time ; Hours 1-12 are fine
.subtract_12:
sub r12, 12
jmp .print_time
.is_midnight:
mov r12, 12 ; 0 hour becomes 12 AM
.print_time:
mov rax, r12
call print_two_digits
mov al, ':'
call print_char
mov rax, r13
call print_two_digits
mov al, ':'
call print_char
mov rax, r14
call print_two_digits
ret
print_char:
push rdi
push rbx
push rcx
push rdx
push rax
push rsi
cmp al, 10
je .newline
mov cl, al
mov rax, [cursor_y]
mov rbx, 80
mul rbx
add rax, [cursor_x]
shl rax, 1
lea rdi, [video_buffer + rax] ; <--- TARGETS BUFFER
mov byte [rdi], cl
mov byte [rdi+1], 0x0F
inc qword [cursor_x]
cmp qword [cursor_x], 80
jl .check_scroll
.newline:
mov qword [cursor_x], 0
inc qword [cursor_y]
.check_scroll:
cmp qword [cursor_y], 25
jl .done
lea rsi, [video_buffer + 160]
lea rdi, [video_buffer]
mov rcx, 480
.scroll_loop:
mov rax, [rsi]
mov [rdi], rax
add rsi, 8
add rdi, 8
dec rcx
jnz .scroll_loop
lea rdi, [video_buffer + 3840]
mov rax, 0x0F200F200F200F20
mov rcx, 20
.clear_loop:
mov [rdi], rax
add rdi, 8
loop .clear_loop
mov qword [cursor_y], 24
mov qword [cursor_x], 0
.done:
pop rsi
pop rax
pop rdx
pop rcx
pop rbx
pop rdi
ret
bcd2bin:
movzx eax, al      ; AL -> EAX (32-bit)
mov ecx, eax
and ecx, 0x0F      ; low nibble
shr eax, 4         ; high nibble
imul eax, 10       ; multiply high nibble by 10
add eax, ecx       ; add low nibble
ret
print_two_digits:
xor rdx, rdx       ; clear RDX for div
mov rcx, 10
div rcx            ; RAX = quotient (tens), RDX = remainder (units)
mov al, al         ; get quotient in AL
add al, '0'
call print_char
mov al, dl         ; remainder
add al, '0'
call print_char
ret
_start:
push rbp
mov rbp, rsp
and rsp, -16
.__HTLL_HTLL_mainLoop:
push 1
call _htll_clear
add rsp, 8
push 38
push 12
push 104
push 15
call _htll_draw_char
add rsp, 32
push 39
push 12
push 101
push 15
call _htll_draw_char
add rsp, 32
push 40
push 12
push 108
push 15
call _htll_draw_char
add rsp, 32
push 41
push 12
push 108
push 15
call _htll_draw_char
add rsp, 32
push 42
push 12
push 111
push 15
call _htll_draw_char
add rsp, 32
push 72
push 0
push 15
push 1
push 2
push 1
call _htll_display_clock
add rsp, 48
push qword [x]
push qword [y]
push qword [playerColor]
call _htll_draw
add rsp, 24
call draw_all
push r12
push r13
xor r13, r13
mov r12, 400000
.loop1_0:
cmp r12, 0
je .loop1_end0
.cloop1_end0:
inc r13
dec r12
jmp .loop1_0
.loop1_end0:
pop r13
pop r12
call _htll_get_key
mov rax, rax
cmp rax, 17
jne .end_if1_0
mov rax, [y]
cmp rax, 0
jle .end_if2_0
dec qword [y]
.end_if2_0:
jmp .__HTLL_HTLL_mainLoop
.end_if1_0:
mov rax, rax
cmp rax, 31
jne .end_if1_1
mov rax, [y]
cmp rax, [maxY]
jge .end_if2_1
inc qword [y]
.end_if2_1:
jmp .__HTLL_HTLL_mainLoop
.end_if1_1:
mov rax, rax
cmp rax, 30
jne .end_if1_2
mov rax, [x]
cmp rax, 0
jle .end_if2_2
dec qword [x]
.end_if2_2:
jmp .__HTLL_HTLL_mainLoop
.end_if1_2:
mov rax, rax
cmp rax, 32
jne .end_if1_3
mov rax, [x]
cmp rax, [maxX]
jge .end_if2_3
inc qword [x]
.end_if2_3:
jmp .__HTLL_HTLL_mainLoop
.end_if1_3:
jmp .__HTLL_HTLL_mainLoop
mov rsp, rbp
pop rbp
jmp .program_end
.program_end:
jmp $
