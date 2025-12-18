.model small
.stack 100h

CRET = 13
CF = 10

.data

    welcome_message      db ' ----------------------------------------------------------', CRET, CF
                         db '|                                                          |', CRET, CF
                         db '|               Author - Makariy Sinyavskiy                |', CRET, CF
                         db '|                                                          |', CRET, CF
                         db '|                  Disassembler program                    |', CRET, CF
                         db '|                                                          |', CRET, CF
                         db ' ----------------------------------------------------------', CRET, CF, CF,'$'


    input_filename       db 20 dup(?), '$'
    input                dw ?                                                                                  ; Descriptor

    output_filename      db 20 dup(?), '$'
    output               dw ?

    help_message         db 'Usage: program_name input_file output_file',13,10,'$'

    buffer               db 256 dup('$')

    ; ERRORS messages
    unknown_err          db ' -> ERROR: unknown error!',13,10,'$'
    access_denied_err    db ' -> ERROR: access denied!',13,10,'$'
    not_found_err        db ' -> ERROR: file not found!',13,10,'$'
    too_much_files_err   db ' -> ERROR: too much opened files!',13,10,'$'
    incorrect_access_err db ' -> ERROR: incorrect access mode!',13,10,'$'
    already_exist_err    db ' -> ERROR: file already exist!',13,10,'$'

    ; Registers
    reg_000              db 'AX', '$', 'AL', '$'
    reg_001              db 'CX', '$', 'CL', '$'
    reg_010              db 'DX', '$', 'DL', '$'
    reg_011              db 'BX', '$', 'BL', '$'
    reg_100              db 'AH', '$', 'SP', '$'
    reg_101              db 'CH', '$', 'BP', '$'
    reg_110              db 'DH', '$', 'SI', '$'
    reg_111              db 'BH', '$', 'DI', '$'

    ; Commands
    command_MOV          db 'MOV', '$'
    command_ADD          db 'ADD', '$'
    command_SUB          db 'SUB', '$'
    command_MUL          db 'MUL', '$'
    command_DIV          db 'DIV', '$'
    command_AND          db 'AND', '$'
    command_OR           db 'OR', '$'
    command_XOR          db 'XOR', '$'
    command_NOT          db 'NOT', '$'
    command_SHL          db 'SHL', '$'
    command_SHR          db 'SHR', '$'
    command_JMP          db 'JMP', '$'
    command_JE           db 'JE', '$'
    command_JNE          db 'JNE', '$'
    command_JG           db 'JG', '$'
    command_JL           db 'JL', '$'
    command_JGE          db 'JGE', '$'
    command_JLE          db 'JLE', '$'
    command_CALL         db 'CALL', '$'
    command_RET          db 'RET', '$'
    command_HLT          db 'HLT', '$'

    labels               db 'label', '$' ; 1024 dup('$')

.code
    program:        

                    mov          ax, @data
                    mov          ds, ax

                    mov          ah, 09h
                    mov          dx, offset welcome_message
                    int          21h

                    call         CL_PARAMS_READ
                    cmp          al, 1
                    jne          OPEN_FILES

                    mov          ah, 09h
                    mov          dx, offset help_message
                    int          21h
                    mov          al, 01
                    jmp          EXIT

    OPEN_FILES:     
     ; Open input
                    mov          ah, 3dh
                    mov          al, 00h
                    mov          dx, offset input_filename
                    int          21h
                    jnc          NEXT1
                    call         OPEN_ERROR

    NEXT1:          
      ; Save file descriptor
                    mov          [input], ax

     ; Create and open output file
                    mov          ah, 5Bh
                    mov          cx, 00h
                    mov          dx, offset output_filename
                    int          21h
                    jnc          NEXT2
                    call         OPEN_ERROR

    NEXT2:          
                    mov          [output], ax







     ; READ FILE LOOP
    READ_LOOP:      
                    mov          ah, 3Fh                            ; Read from file
                    mov          bx, [input]                        ; File handle
                    mov          cx, 1                              ; Number of bytes to read
                    mov          dx, offset buffer
                    int          21h
    
                    jc           READ_ERROR                         ; Jump if error
    
                    cmp          ax, 0                              ; Check if 0 bytes read (EOF)
                    je           EXIT                               ; If EOF, exit

                    mov          al, buffer
                    call         FIRST_BYTE
    
                    jmp          READ_LOOP                          ; Continue reading

    READ_ERROR:     
                    call         OPEN_ERROR


    EXIT:           
     ; save error code
                    push         ax

     ; Close files if opened
                    mov          ah, 3Eh
                    mov          bx, [input]
                    int          21h
                    mov          ah, 3Eh
                    mov          bx, [output]
                    int          21h

                    pop          ax
                    mov          ah, 4Ch
                    int          21h










     ; --------------------------------------------------------------------
     ; Identify open file error and print it.
     ; Input -> dx - current file, ax - error
     ; Return -> exit.
     ; --------------------------------------------------------------------
OPEN_ERROR PROC
                    mov          bx, ax                             ; save error code
                    mov          ah, 09h
                    int          21h

    ; https://www.stanislavs.org/helppc/dos_error_codes.html
    ;                   /
    ; All error codes -/
                    cmp          bx, 02h                            ; Incorrect path
                    je           INC_PATH
                    cmp          bx, 03h                            ; Incorrect path
                    je           INC_PATH
                    cmp          bx, 04h                            ; Too much opened files
                    je           TOO_MUCH_O_F
                    cmp          bx, 05h                            ; Access denied
                    je           ACCESS_DENIED
                    cmp          bx, 0ch                            ; Incorrect access mode
                    je           INC_ACCESS_MODE
                    cmp          bx, 50h                            ; Already exist
                    je           ALREADY_EXIST
        

                    mov          dx, offset unknown_err
                    jmp          ERR_PRINT

    INC_PATH:       
                    mov          dx, offset not_found_err
                    mov          al, 03h
                    jmp          ERR_PRINT

    TOO_MUCH_O_F:   
                    mov          dx, offset too_much_files_err
                    mov          al, 04h
                    jmp          ERR_PRINT

    ACCESS_DENIED:  
                    mov          dx, offset access_denied_err
                    mov          al, 05h
                    jmp          ERR_PRINT

    INC_ACCESS_MODE:
                    mov          dx, offset incorrect_access_err
                    mov          al, 0ch
                    jmp          ERR_PRINT

    ALREADY_EXIST:  
                    mov          dx, offset already_exist_err
                    mov          al, 50h

    ERR_PRINT:      
                    int          21h                                ; Print error
                    jmp          EXIT                               ; Exit program
OPEN_ERROR ENDP

    ; --------------------------------------------------------------------
    ; Read 2 filenames from command line
    ; Return: AL=0 -> OK, AL=1 -> error/help, jump back
    ; --------------------------------------------------------------------
CL_PARAMS_READ PROC
                    mov          si, 80h                            ; CL length
                    mov          cl, es:[si]
                    cmp          cl, 0
                    je           ERR_RET                            ; no params

                    xor          cx, cx

                    mov          si, 82h                            ; start of CL text
                    call         SKIP_SPACES
                    mov          di, offset input_filename
                    call         READ_WORD
                    mov          byte ptr [di], 0                   ; Null terminator for open file (3Dh)
                    mov          byte ptr [di+1], '$'               ; $ terminator for print string (09h)

                    cmp          cx, 0
                    je           ERR_RET
                    xor          cx, cx

                    call         SKIP_SPACES
                    mov          di, offset output_filename
                    call         READ_WORD
                    mov          byte ptr [di], 0                   ; Null terminator for create file (3Ch/5Bh)
                    mov          byte ptr [di+1], '$'               ; $ terminator for print string (09h)

                    cmp          cx, 0
                    je           ERR_RET

                    xor          al, al
                    ret

    ERR_RET:        
                    mov          al, 1
                    ret
CL_PARAMS_READ ENDP

    ; --------------------------------------------------------------------
    ; Just skip spaces
    ; Return -> jump back
    ; --------------------------------------------------------------------
SKIP_SPACES PROC
    SKIP_LOOP:      
                    mov          al, es:[si]
                    cmp          al, ' '
                    jne          S_DONE
                    inc          si
                    jmp          SKIP_LOOP
    S_DONE:         
                    ret
SKIP_SPACES ENDP

    ; --------------------------------------------------------------------
    ; Read word to di until space or \n
    ; Return -> jump back
    ; --------------------------------------------------------------------
READ_WORD PROC
    READ_WORD_LOOP: 
                    mov          al, es:[si]
                    cmp          al, ' '
                    je           READ_WORD_DONE
                    cmp          al, 13
                    je           READ_WORD_DONE
                    mov          [di], al
                    inc          di
                    inc          si
                    inc          cx
                    jmp          READ_WORD_LOOP
    READ_WORD_DONE: 
                    ret
READ_WORD ENDP

    ; --------------------------------------------------------------------
    ; Check first byte of command (al)
    ; --------------------------------------------------------------------
FIRST_BYTE PROC
    ; MOV 1
    ; mod 00, d 0, w 0, 
        cmp ax, 8800h ; 100010 00 00 000 000
        jne MOV_1_1
        print_reg_label command_MOV, reg_000, 0

        MOV_1_1:
        cmp ax, 8801h ; 100010 00 00 001 000
        jne MOV_1_2
        print_reg_label command_MOV, reg_001, 0

        MOV_1_2:
        cmp ax, 8802h ; 100010 00 00 010 000
        jne MOV_1_3
        print_reg_label command_MOV, reg_010, 0

        MOV_1_3:
        cmp ax, 8803h ; 100010 00 00 100 000
        jne MOV_1_4
        print_reg_label command_MOV, reg_100, 0

        MOV_1_4:
        cmp ax, 8804h ; 100010 00 00 011 000
        jne MOV_1_5
        print_reg_label command_MOV, reg_011, 0

        MOV_1_5:
        cmp ax, 8805h ; 100010 00 00 110 000
        jne MOV_1_6
        print_reg_label command_MOV, reg_110, 0

        MOV_1_6:
        cmp ax, 8806h ; 100010 00 00 101 000
        jne MOV_1_7
        print_reg_label command_MOV, reg_101, 0

        MOV_1_7:
        cmp ax, 8807h ; 100010 00 00 111 000
        jne MOV_2_1
        print_reg_label command_MOV, reg_111, 0


    ; mod 00, d 0, w 1
        MOV_2_1:
        cmp ax, 8810h ; 100010 01 00 000 000
        jne MOV_2_2
        print_reg_label command_MOV, reg_000, 1

        MOV_2_2:
        cmp ax, 8811h ; 100010 01 00 001 000
        jne MOV_2_3
        print_reg_label command_MOV, reg_001, 1

        MOV_2_3:
        cmp ax, 8812h ; 100010 01 00 010 000
        jne MOV_2_4
        print_reg_label command_MOV, reg_010, 1

        MOV_2_4:
        cmp ax, 8813h ; 100010 01 00 011 000
        jne MOV_2_5
        print_reg_label command_MOV, reg_011, 1

        MOV_2_5:
        cmp ax, 8814h ; 100010 01 00 100 000
        jne MOV_2_6
        print_reg_label command_MOV, reg_100, 1

        MOV_2_6:
        cmp ax, 8815h ; 100010 01 00 101 000
        jne MOV_2_7
        print_reg_label command_MOV, reg_101, 1

        MOV_2_7:
        cmp ax, 8816h ; 100010 01 00 110 000
        jne MOV_2_8
        print_reg_label command_MOV, reg_110, 1

        MOV_2_8:
        cmp ax, 8817h ; 100010 01 00 111 000
        jne MOV_2_9
        print_reg_label command_MOV, reg_111, 1
    
    ; mod 00, d 1, w 0
        MOV_3_1:
        cmp ax, 8818h ; 100010 10 00 000 000
        jne MOV_3_2
        print_label_reg command_MOV, reg_000, 0

        MOV_3_2:
        cmp ax, 8819h ; 100010 10 00 001 000
        jne MOV_3_3
        print_label_reg command_MOV, reg_001, 0

        MOV_3_3:
        cmp ax, 881Ah ; 100010 10 00 010 000
        jne MOV_3_4
        print_label_reg command_MOV, reg_010, 0

        MOV_3_4:
        cmp ax, 881Bh ; 100010 10 00 011 000
        jne MOV_3_5
        print_label_reg command_MOV, reg_011, 0

        MOV_3_5:
        cmp ax, 881Ch ; 100010 10 00 100 000
        jne MOV_3_6
        print_label_reg command_MOV, reg_100, 0

        MOV_3_6:
        cmp ax, 881Dh ; 100010 10 00 101 000
        jne MOV_3_7
        print_label_reg command_MOV, reg_101, 0

        MOV_3_7:
        cmp ax, 881Eh ; 100010 10 00 110 000
        jne MOV_3_8
        print_label_reg command_MOV, reg_110, 0

        MOV_3_8:
        cmp ax, 881Fh ; 100010 10 00 111 000
        jne MOV_3_9
        print_label_reg command_MOV, reg_111, 0
    
    ; mod 00, d 1, w 1
        MOV_4_1:
        cmp ax, 8820h ; 100010 11 00 000 000
        jne MOV_4_2
        print_label_reg command_MOV, reg_000, 1

        MOV_4_2:
        cmp ax, 8821h ; 100010 11 00 001 000
        jne MOV_4_3
        print_label_reg command_MOV, reg_001, 1

        MOV_4_3:
        cmp ax, 8822h ; 100010 11 00 010 000
        jne MOV_4_4
        print_label_reg command_MOV, reg_010, 1

        MOV_4_4:
        cmp ax, 8823h ; 100010 11 00 011 000
        jne MOV_4_5
        print_label_reg command_MOV, reg_011, 1

        MOV_4_5:
        cmp ax, 8824h ; 100010 11 00 100 000
        jne MOV_4_6
        print_label_reg command_MOV, reg_100, 1

        MOV_4_6:
        cmp ax, 8825h ; 100010 11 00 101 000
        jne MOV_4_7
        print_label_reg command_MOV, reg_101, 1

        MOV_4_7:
        cmp ax, 8826h ; 100010 11 00 110 000
        jne MOV_4_8
        print_label_reg command_MOV, reg_110, 1

        MOV_4_8:
        cmp ax, 8827h ; 100010 11 00 111 000
        jne MOV_4_9
        print_label_reg command_MOV, reg_111, 1
    
    
FIRST_BYTE ENDP


print_reg_reg MACRO command, reg1, reg2                                               ; Define macro 'print_string' with 3 parameters
                    lea          dx, command
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, ' '
                    int          21h

                    lea          dx, reg1
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, ','
                    int          21h

                    lea          dx, reg2
                    mov          ah, 09h
                    int          21h
ENDM

print_reg_label MACRO command, reg, w                                               ; Define macro 'print_string' with 3 parameters
                    lea          dx, command
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, ' '
                    int          21h

                    lea          dx, reg1
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, ', '
                    int          21h

                    lea          dx, labels
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, 10 
                    int          21h

                    mov          dl, 13 
                    int          21h
ENDM

print_label_reg MACRO command, reg, w
                    lea          dx, command
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, ' '
                    int          21h

                    lea          dx, labels
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, ', '
                    int          21h

                    lea          dx, reg
                    mov          ah, 09h
                    int          21h

                    mov          ah, 02h
                    mov          dl, 10 
                    int          21h

                    mov          dl, 13 
                    int          21h
ENDM
end program
