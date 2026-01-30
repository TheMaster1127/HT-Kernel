use64
org 0x9400
jmp _start
DynamicArray.pointer  = 0
DynamicArray.size     = 8
ASM_STR_TEMP_PRINT_1 db "Echo: ", 10
ASM_STR_TEMP_PRINT_1_len = $-ASM_STR_TEMP_PRINT_1
ASM_STR_TEMP_PRINT_2 db "", 10
ASM_STR_TEMP_PRINT_2_len = $-ASM_STR_TEMP_PRINT_2
ASM_STR_TEMP_PRINT_3 db "Welcome to the Bear Den. Type 'help' or 'exit'.", 10
ASM_STR_TEMP_PRINT_3_len = $-ASM_STR_TEMP_PRINT_3
ASM_STR_TEMP_PRINT_4 db "--- HELP MENU ---", 10
ASM_STR_TEMP_PRINT_4_len = $-ASM_STR_TEMP_PRINT_4
ASM_STR_TEMP_PRINT_5 db "You are running on raw x86-64 assembly.", 10
ASM_STR_TEMP_PRINT_5_len = $-ASM_STR_TEMP_PRINT_5
ASM_STR_TEMP_PRINT_6 db "This shell has 0 dependencies.", 10
ASM_STR_TEMP_PRINT_6_len = $-ASM_STR_TEMP_PRINT_6
ASM_STR_TEMP_PRINT_7 db "Available commands: help, exit, [any text to echo]", 10
ASM_STR_TEMP_PRINT_7_len = $-ASM_STR_TEMP_PRINT_7
ASM_STR_TEMP_PRINT_8 db "-----------------", 10
ASM_STR_TEMP_PRINT_8_len = $-ASM_STR_TEMP_PRINT_8
ASM_STR_TEMP_PRINT_9 db "Exiting to OS...", 10
ASM_STR_TEMP_PRINT_9_len = $-ASM_STR_TEMP_PRINT_9
is_match dq 0
input_lenn dq 0
cmd_len dq 0
val_input dq 0
val_cmd dq 0
i dq 0
input_bufferr rq 3
prompt rq 3
cmd_help rq 3
cmd_exit rq 3
cursor_x dq 0
cursor_y dq 0
heap_ptr dq 0x40000
scan_map:
db 0,27,'1','2','3','4','5','6','7','8','9','0','-','=',8,9
db 'q','w','e','r','t','y','u','i','o','p','[',']',10,0,'a','s'
db 'd','f','g','h','j','k','l',';',39,'`',0,'\','z','x','c','v'
db 'b','n','m',',','.','/',0,'*',0,32
print_str:
push rsi
push rax
push rcx
mov rcx, rdx
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
push rsi
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
jl .check_scroll
.newline:
mov qword [cursor_x], 0
inc qword [cursor_y]
.check_scroll:
cmp qword [cursor_y], 25
jl .done
mov rsi, 0xB80A0
mov rdi, 0xB8000
mov rcx, 480
.scroll_loop:
mov rax, [rsi]
mov [rdi], rax
add rsi, 8
add rdi, 8
dec rcx
jnz .scroll_loop
mov rdi, 0xB8F00
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
array_clear:
mov qword [rdi + 8], 0
ret
get_user_input:
push rbx
push rcx
push rdx
push rsi
push rdi
push r12
push r13
mov r12, rdi
mov r13, rsi
mov rax, [r13 + 8]
cmp rax, 0
je .read_start
mov rcx, rax
mov rbx, [r13]
xor rdx, rdx
.prompt_loop:
mov al, [rbx + rdx*8]
call print_char
inc rdx
loop .prompt_loop
.read_start:
.wait_key:
in al, 0x64
test al, 1
jz .wait_key
in al, 0x60
test al, 0x80
jnz .wait_key
lea rdx, [scan_map]
and rax, 0xFF
mov al, [rdx + rax]
cmp al, 0
je .wait_key
cmp al, 10
je .input_done
cmp al, 8
je .handle_backspace
call print_char
mov rdi, r12
movzx rsi, al
call array_append
jmp .wait_key
.handle_backspace:
cmp qword [r12 + 8], 0
je .wait_key
mov rdi, r12
call array_pop
dec qword [cursor_x]
mov rax, [cursor_y]
mov rbx, 80
mul rbx
add rax, [cursor_x]
shl rax, 1
add rax, 0xB8000
mov word [rax+0], 0x0F20
jmp .wait_key
.input_done:
mov al, 10
call print_char
pop r13
pop r12
pop rdi
pop rsi
pop rdx
pop rcx
pop rbx
ret
array_append:
push rbx
push rcx
push rax
mov rcx, [rdi + 8]
mov rbx, [rdi]
cmp rbx, 0
jne .store
mov rbx, 1024
call _kmalloc
mov rbx, rax
mov [rdi], rbx
mov qword [rdi+16], 128
.store:
mov [rbx + rcx*8], rsi
inc qword [rdi + 8]
pop rax
pop rcx
pop rbx
ret
_kmalloc:
push rbx
push rdx
mov rax, [heap_ptr]
mov rdx, rax
add rdx, rbx
mov [heap_ptr], rdx
mov rax, rdx
sub rdx, rbx
mov rax, rdx
pop rdx
pop rbx
ret
array_pop:
cmp qword [rdi + 8], 0
je .done
dec qword [rdi + 8]
.done:
ret
init_constants:
push rbp
mov rbp, rsp
sub rsp, 16
mov rsi, ''
mov rdi, prompt
call array_append
mov rsi, 'H'
mov rdi, prompt
call array_append
mov rsi, 'T'
mov rdi, prompt
call array_append
mov rsi, 'L'
mov rdi, prompt
call array_append
mov rsi, 'L'
mov rdi, prompt
call array_append
mov rsi, '-'
mov rdi, prompt
call array_append
mov rsi, 'S'
mov rdi, prompt
call array_append
mov rsi, 'h'
mov rdi, prompt
call array_append
mov rsi, 'e'
mov rdi, prompt
call array_append
mov rsi, 'l'
mov rdi, prompt
call array_append
mov rsi, 'l'
mov rdi, prompt
call array_append
mov rsi, ''
mov rdi, prompt
call array_append
mov rsi, 62
mov rdi, prompt
call array_append
mov rsi, 32
mov rdi, prompt
call array_append
mov rsi, 'h'
mov rdi, cmd_help
call array_append
mov rsi, 'e'
mov rdi, cmd_help
call array_append
mov rsi, 'l'
mov rdi, cmd_help
call array_append
mov rsi, 'p'
mov rdi, cmd_help
call array_append
mov rsi, 'e'
mov rdi, cmd_exit
call array_append
mov rsi, 'x'
mov rdi, cmd_exit
call array_append
mov rsi, 'i'
mov rdi, cmd_exit
call array_append
mov rsi, 't'
mov rdi, cmd_exit
call array_append
.init_constants_return:
add rsp, 16
pop rbp
ret
check_if_help:
push rbp
mov rbp, rsp
sub rsp, 16
mov qword [is_match], 1
mov rax, [input_bufferr + DynamicArray.size]
mov rdi, rax
mov [input_lenn], rdi
mov rax, [cmd_help + DynamicArray.size]
mov rdi, rax
mov [cmd_len], rdi
mov rax, [input_lenn]
cmp rax, [cmd_len]
je .end_if1_0
mov qword [is_match], 0
jmp .__HTLL_HTLL_end_compare_help
.end_if1_0:
push r12
push r13
xor r13, r13
mov r12, [input_lenn]
.loop1_0:
cmp r12, 0
je .loop1_end0
mov rdi, r13
mov [i], rdi
mov rcx, [i]
mov rbx, [input_bufferr + DynamicArray.pointer]
mov rax, [rbx + rcx*8]
mov rdi, rax
mov [val_input], rdi
mov rcx, [i]
mov rbx, [cmd_help + DynamicArray.pointer]
mov rax, [rbx + rcx*8]
mov rdi, rax
mov [val_cmd], rdi
mov rax, [val_input]
cmp rax, [val_cmd]
je .end_if1_1
mov qword [is_match], 0
jmp .__HTLL_HTLL_end_compare_help
.end_if1_1:
.cloop1_end0:
inc r13
dec r12
jmp .loop1_0
.loop1_end0:
pop r13
pop r12
.__HTLL_HTLL_end_compare_help:
.check_if_help_return:
add rsp, 16
pop rbp
ret
echo_input:
push rbp
mov rbp, rsp
sub rsp, 16
mov rsi, ASM_STR_TEMP_PRINT_1
mov rdx, ASM_STR_TEMP_PRINT_1_len
call print_str
mov rax, [input_bufferr + DynamicArray.size]
push r12
push r13
xor r13, r13
mov r12, rax
.loop1_1:
cmp r12, 0
je .loop1_end1
mov rcx, r13
mov rbx, [input_bufferr + DynamicArray.pointer]
mov rax, [rbx + rcx*8]
mov rdi, rax
push rcx
call print_char
pop rcx
.cloop1_end1:
inc r13
dec r12
jmp .loop1_1
.loop1_end1:
pop r13
pop r12
mov rsi, ASM_STR_TEMP_PRINT_2
mov rdx, ASM_STR_TEMP_PRINT_2_len
call print_str
.echo_input_return:
add rsp, 16
pop rbp
ret
_start:
push rbp
mov rbp, rsp
and rsp, -16
call init_constants
mov rsi, ASM_STR_TEMP_PRINT_3
mov rdx, ASM_STR_TEMP_PRINT_3_len
call print_str
.__HTLL_HTLL_shell_loop:
mov rdi, input_bufferr
call array_clear
mov rdi, input_bufferr
mov rsi, prompt
call get_user_input
call check_if_help
mov rax, [is_match]
cmp rax, 1
jne .end_if1_2
mov rsi, ASM_STR_TEMP_PRINT_4
mov rdx, ASM_STR_TEMP_PRINT_4_len
call print_str
mov rsi, ASM_STR_TEMP_PRINT_5
mov rdx, ASM_STR_TEMP_PRINT_5_len
call print_str
mov rsi, ASM_STR_TEMP_PRINT_6
mov rdx, ASM_STR_TEMP_PRINT_6_len
call print_str
mov rsi, ASM_STR_TEMP_PRINT_7
mov rdx, ASM_STR_TEMP_PRINT_7_len
call print_str
mov rsi, ASM_STR_TEMP_PRINT_8
mov rdx, ASM_STR_TEMP_PRINT_8_len
call print_str
jmp .__HTLL_HTLL_shell_loop
.end_if1_2:
mov rax, [input_bufferr + DynamicArray.size]
mov rax, rax
cmp rax, 4
jne .end_if1_3
mov rcx, 0
mov rbx, [input_bufferr + DynamicArray.pointer]
mov rax, [rbx + rcx*8]
mov rax, rax
cmp rax, 101
jne .end_if1_3
mov rsi, ASM_STR_TEMP_PRINT_9
mov rdx, ASM_STR_TEMP_PRINT_9_len
call print_str
jmp .__HTLL_HTLL_shell_exit
.end_if1_3:
.end_if1_4:
call echo_input
jmp .__HTLL_HTLL_shell_loop
.__HTLL_HTLL_shell_exit:
mov rsp, rbp
pop rbp
jmp .program_end
.program_end:
jmp $
