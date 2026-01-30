use64
org 0x9400
jmp _start
ASM_STR_TEMP_PRINT_1 db "hello world", 10
ASM_STR_TEMP_PRINT_1_len = $-ASM_STR_TEMP_PRINT_1
cursor_x dq 0
cursor_y dq 0
heap_ptr dq 0x200000 ; Start heap at 2MB (safe zone)
scan_map:
db 0,27,'1','2','3','4','5','6','7','8','9','0','-','=',8,9
db 'q','w','e','r','t','y','u','i','o','p','[',']',10,0,'a','s'
db 'd','f','g','h','j','k','l',';',39,'',0,'\','z','x','c','v'
db 'b','n','m',',','.','/',0,'*',0,32
print_str:
push rsi
push rax
push rcx
mov rcx, rdx ; Use the length as the loop counter
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
push rdx ; Save RDX (mul uses it)
push rax ; Save RAX (mul uses it)
cmp al, 10
je .newline
mov cl, al
mov rax, [cursor_y]
mov rbx, 80
mul rbx        ; Result in RAX
add rax, [cursor_x]
shl rax, 1     ; * 2
mov rdi, 0xB8000
add rdi, rax
mov byte [rdi], cl
mov byte [rdi+1], 0x0F ; White on Black
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
_start:
push rbp
mov rbp, rsp
and rsp, -16
mov rsi, ASM_STR_TEMP_PRINT_1
mov rdx, ASM_STR_TEMP_PRINT_1_len
call print_str
mov rsp, rbp
pop rbp
jmp .program_end
.program_end:
jmp $
