.model small
.stack 100h

.data
    buffer db 255           ;  Buffer max length
           db 0             ;  String length    
           db 255 dup(?)    ;  Reservation

    welcome db 'Please enter text(up to 255 chars)', 0ah, 0dh, 'Program will count chars in each word: $'
    result db 0ah, 0dh, 'Result: $'

    
.code 
PROGRAM:
    mov ax, @data
    mov ds, ax

    mov ah, 09h
    mov dx, offset welcome
    int 21h

    ; Reading/saving input line
    mov dx, offset buffer
    mov ah, 0ah
    int 21h

    mov ah, 09h
    mov dx, offset result
    int 21h


    ; Clearing registers
    xor cx, cx
    ; xor dx, dx
    xor ax, ax

    mov dl, [buffer + 1] ; Length
    ; mov bh, 32 ; Space

    ; Counting letters
    COUNT:
        cmp cl, dl
        jae EXIT
            ; xor bx, bx
            mov si, cx
            mov bl, [buffer + 2 + si] ; Current char

            cmp bl, 32 ; space
            jne _else
                cmp ax, 0
                je _endif
                    call PrintNum ; print ax number
                    xor ax, ax
                    jmp _endif
            _else:
                inc ax
            _endif:

            inc cl
        jmp COUNT

    EXIT:
        call PrintNum
        mov ax, 4c00h
        int 21h


; Print num in ax.
PrintNum PROC
    push bx
    push cx
    push dx

    xor cx, cx
    xor dx, dx
    xor bx, bx

    mov bx, 10

    WHILE1:
    cmp ax, 0
    je WHILE2
        div bx ;  ax/bx -> dx - reminder, ax - result
        push dx
        xor dx, dx
        inc cx
        jmp WHILE1

    xor ax, ax

    WHILE2:
    cmp cx, 0
    je NEXT2
        pop dx
        mov ah, 02h ; Print char
        add dl, 48
        int 21h
        dec cx
        jmp WHILE2
    NEXT2:

    ; Space print
    mov ah, 02h 
    mov dx, 32
    int 21h

    pop dx
    pop cx
    pop bx
ret
PrintNum ENDP

end PROGRAM


    ; mov ah, 40h
    ; mov bx, (1)
    ; mov cl, [buffer+1]
    ; xor ch, ch
    ; mov dx, offset buffer + 2
    ; int 21h
