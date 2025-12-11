.model small
.stack 100h

CRET = 13
CF = 10


.data

    welcome_message db ' ----------------------------------------------------------', CRET, CF
                    db '|                                                          |', CRET, CF
                    db '|               Author - Makariy Sinyavskiy                |', CRET, CF
                    db '|                                                          |', CRET, CF
                    db '|                  Disassembler program                    |', CRET, CF
                    db '|                                                          |', CRET, CF
                    db ' ----------------------------------------------------------', CRET, CF, CF,'$'


    input_filename       db 20 dup(?), '$'
    input                dw ?                                                         ; Descriptor

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


.code
    program:        

                    mov  ax, @data
                    mov  ds, ax

                    call CL_PARAMS_READ
                    cmp  al, 1
                    jne  OPEN_FILES

                    mov  ah, 09h
                    mov  dx, offset help_message
                    int  21h
                    mov  al, 01
                    jmp  EXIT

    OPEN_FILES:     
    ; Open input
                    mov  ah, 3dh
                    mov  al, 00h
                    mov  dx, offset input_filename
                    int  21h
                    jnc  NEXT1
                    call OPEN_ERROR

    NEXT1:          
    ; Save file descriptor
                    mov  [input], ax

    ; Create and open output file
                    mov  ah, 5Bh
                    mov  cx, 00h
                    mov  dx, offset output_filename
                    int  21h
                    jnc  NEXT2
                    call OPEN_ERROR

    NEXT2:          
                    mov  [output], ax





                    

    ; READ FILE LOOP
    READ_LOOP:      
                    mov  ah, 3Fh                            ; Read from file
                    mov  bx, [input]                        ; File handle
                    mov  cx, 8                              ; Number of bytes to read
                    mov  dx, offset buffer
                    int  21h
    
                    jc   READ_ERROR                         ; Jump if error
    
                    cmp  ax, 0                              ; Check if 0 bytes read (EOF)
                    je   EXIT                               ; If EOF, exit

    ; AX contains the number of bytes read
    ; TODO: Process the buffer here
    ; call PROCESS_BUFFER
    
                    jmp  READ_LOOP                          ; Continue reading

    READ_ERROR:     
                    call OPEN_ERROR


    EXIT:           
    ; save error code
                    push ax

    ; Close files if opened
                    mov  ah, 3Eh
                    mov  bx, [input]
                    int  21h
                    mov  ah, 3Eh
                    mov  bx, [output]
                    int  21h

                    pop  ax
                    mov  ah, 4Ch
                    int  21h










    ; --------------------------------------------------------------------
    ; Identify open file error and print it.
    ; Input -> dx - current file, ax - error
    ; Return -> exit.
    ; --------------------------------------------------------------------
OPEN_ERROR PROC
                    mov  bx, ax                             ; save error code
                    mov  ah, 09h
                    int  21h

    ; https://www.stanislavs.org/helppc/dos_error_codes.html
    ;                   /
    ; All error codes -/
                    cmp  bx, 02h                            ; Incorrect path
                    je   INC_PATH
                    cmp  bx, 03h                            ; Incorrect path
                    je   INC_PATH
                    cmp  bx, 04h                            ; Too much opened files
                    je   TOO_MUCH_O_F
                    cmp  bx, 05h                            ; Access denied
                    je   ACCESS_DENIED
                    cmp  bx, 0ch                            ; Incorrect access mode
                    je   INC_ACCESS_MODE
                    cmp  bx, 50h                            ; Already exist
                    je   ALREADY_EXIST
        

                    mov  dx, offset unknown_err
                    jmp  ERR_PRINT

    INC_PATH:       
                    mov  dx, offset not_found_err
                    mov  al, 03h
                    jmp  ERR_PRINT

    TOO_MUCH_O_F:   
                    mov  dx, offset too_much_files_err
                    mov  al, 04h
                    jmp  ERR_PRINT

    ACCESS_DENIED:  
                    mov  dx, offset access_denied_err
                    mov  al, 05h
                    jmp  ERR_PRINT

    INC_ACCESS_MODE:
                    mov  dx, offset incorrect_access_err
                    mov  al, 0ch
                    jmp  ERR_PRINT

    ALREADY_EXIST:  
                    mov  dx, offset already_exist_err
                    mov  al, 50h

    ERR_PRINT:      
                    int  21h                                ; Print error
                    jmp  EXIT                               ; Exit program
OPEN_ERROR ENDP

    ; --------------------------------------------------------------------
    ; Read 2 filenames from command line
    ; Return: AL=0 -> OK, AL=1 -> error/help, jump back
    ; --------------------------------------------------------------------
CL_PARAMS_READ PROC
                    mov  si, 80h                            ; CL length
                    mov  cl, ds:[si]
                    cmp  cl, 0
                    je   ERR_RET                            ; no params

                    xor  cx, cx

                    mov  si, 82h                            ; start of CL text
                    call SKIP_SPACES
                    mov  di, offset input_filename
                    call READ_WORD
                    mov  [di], '0$'                         ; EOS

                    cmp  cx, 0
                    je   ERR_RET
                    xor  cx, cx

                    call SKIP_SPACES
                    mov  di, offset output_filename
                    call READ_WORD
                    mov  [di], '0$'                         ; EOS

                    cmp  cx, 0
                    je   ERR_RET

                    xor  al, al
                    ret

    ERR_RET:        
                    mov  al, 1
                    ret
CL_PARAMS_READ ENDP

    ; --------------------------------------------------------------------
    ; Just skip spaces
    ; Return -> jump back
    ; --------------------------------------------------------------------
SKIP_SPACES PROC
    SKIP_LOOP:      
                    mov  al, es:[si]
                    cmp  al, ' '
                    jne  S_DONE
                    inc  si
                    jmp  SKIP_LOOP
    S_DONE:         
                    ret
SKIP_SPACES ENDP

    ; --------------------------------------------------------------------
    ; Read word to di until space or \n
    ; Return -> jump back
    ; --------------------------------------------------------------------
READ_WORD PROC
    READ_WORD_LOOP:      
                    mov  al, es:[si]
                    cmp  al, ' '
                    je   READ_WORD_DONE
                    cmp  al, 13
                    je   READ_WORD_DONE
                    mov  [di], al
                    inc  di
                    inc  si
                    inc  cx
                    jmp  READ_WORD_LOOP
    READ_WORD_DONE:      
                    ret
READ_WORD ENDP

end program
