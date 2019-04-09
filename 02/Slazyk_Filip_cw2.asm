;Project 02 - BMP file viewer
;Created by Filip Slazyk
;AGH UST 2019

;;//////////////////////////DATA SEGMENT/////////////////////////////////////
data1 segment

;error messages
test_error db "Error occured - cannot open file or move file pointer$"
test_invalid_format db "Invalid file type$"
test_unsupported_color_depth db "Unsupported color depth. Application supports only 8-bit and 24-bit color BMP.$"

;program argument
file_name   db 80 dup(0)

;file handle
file_handle dw ?

;BMP headers
file_header db 14 dup(?)
bitmap_header  db 40 dup(?)

;BMP characteristicts
bytes_per_pixel db ?

;color palette - from BMP file (8-bit color) or generated (24-bit color)
color_palette db 1024 dup(?)

;current position of pixel to be displayed
x_curr dw ?
y_curr dw ?

;color values for each canal
r db ?
g db ?
b db ?

;pixel color to be displayed (related to the current color palette)
pixel_color db ?

;start point - left upper corner (relative in given zoom)
;moving through picture will change these values by 1
x_start dw 0
y_start dw 0

;maximal values for the coordinates of the relative start point
x_max dw 0
y_max dw 0

;scale
scale dw 1

;bmp line
bmp_file_line db 10000 dup(?)

data1 ends


;;//////////////////////////CODE SEGMENT/////////////////////////////////////
code1 segment

    ;file header - 14 bytes
    ;bitmap header - 40 bytes
start:
    ;define constant values
    VGAWidth = 320
    VGAHeight = 200
    BMPWidth = bitmap_header + 4
    BMPHeight = bitmap_header + 8
    BitsPerPixel = bitmap_header + 14

    ;select stack segment and pointer
    mov ax, seg top1
    mov ss, ax
    mov sp, offset top1

    ;load program argument string to memory
    mov ax, seg file_name
    mov es, ax
    mov di, offset file_name ;define destination for movsb instruction
    mov si, 82h ;beginning of the string
    mov al, byte ptr ds:[80h] ;get length of program argument string
    xor cx, cx
    mov cl, al
    dec cl ;ignore leading space
    cld
    rep movsb

    ;select data segment (overwrites Program Segment Prefix stored in DS)
    mov ax, seg file_name
    mov ds, ax

    ;open file and get handle
    lea dx, file_name
    mov ax, 3d00h ;al = 0 - read only
    int 21h
    jc error_occured
    mov word ptr ds:[file_handle], ax

    ;read file header
    mov dx, offset file_header
    mov cx, 14
    call read_data

    ;read bitmap header
    mov dx, offset bitmap_header
    mov cx, 40
    call read_data

    call validate_file ;check if file header begins with "BM"

    ;calculate bytes per pixel
    xor dx, dx
    mov ax, word ptr ds:[BitsPerPixel]
    mov cx, 8
    cmp ax, cx
    jz divide
    mov cx, 24
    cmp ax, cx
    jz divide
    jmp error_occured_unsupported_color_depth
divide:
    mov cx, 8
    div cx
    mov byte ptr ds:[bytes_per_pixel], al

    call graphics_mode ;enter 320x200 mode

    ;load bitmap color palette (for 8-bit color bitmaps) or generate own (for 24-bit color bitmaps)
    cmp word ptr ds:[bytes_per_pixel], 1
    jnz generate_color_palette
    mov dx, offset color_palette
    mov cx, 1024    ;read 256 rows of R=(1 Byte) G=(1 Byte) B=(1 Byte) (Unused)=(1 Byte)
    call read_data
    jmp load_color_palette_to_vga

main_loop:

    ;set x_max and y_max related to current scale
    call calculate_max_for_zoom

    ;move file pointer to the first displayed line
    call select_y_line

    mov word ptr ds:[y_curr], 0
    xor cx, cx

    mov ax, word ptr ds:[y_start]
    push ax
    loop_y:             ;loop for selected horizontal lines of BMP file
        push cx

        mov cx, word ptr ds:[BMPWidth]
        xor dx, dx
        mov ax, word ptr ds:[bytes_per_pixel]
        mul cx
        mov cx, ax
        mov dx, offset bmp_file_line
        call read_data      ;read one line of BMP


        mov ax, word ptr ds:[x_start]
        push ax

        mov word ptr ds:[x_curr], 0
        xor cx, cx
        loop_x:         ;loop for iterating through already read BMP file line
            push cx

            mov bx, word ptr ds:[x_start]
            mov ax, word ptr ds:[scale]
            mul bx
            mov bx, word ptr ds:[bytes_per_pixel]
            mul bx
            mov bx, ax  ;bx points to the first byte related to the first shown pixel in given line

            mov al, byte ptr ds:[bmp_file_line + bx]
            mov byte ptr ds:[pixel_color], al
            mov dx, word ptr ds:[bytes_per_pixel]
            cmp dx, 3
            jnz display_pixel    ;8-bit, display pixel

            read_24bit:          ;24-bit, read B G R data from three consecutive bits
                mov al, byte ptr ds:[bmp_file_line + bx]
                mov byte ptr ds:[b], al

                mov al, byte ptr ds:[bmp_file_line + bx + 1]
                mov byte ptr ds:[g], al

                mov al, byte ptr ds:[bmp_file_line + bx + 2]
                mov byte ptr ds:[r], al

                call convert_from_24bit     ;convert read BGR to pixel_color related to defined color palette

            display_pixel:
                call show_pixel             ;show pixel on the screen

            mov ax, word ptr ds:[x_start]   
            inc ax
            mov word ptr ds:[x_start], ax 

            pop cx
            inc cx
            mov word ptr ds:[x_curr], cx
            cmp cx, VGAWidth
            jnz loop_x      ;check condition for loop_x

        pop ax
        mov word ptr ds:[x_start], ax ;revert x_start value from before the loop_x - for keyboard boundary check

        mov ax, word ptr ds:[y_start]   
        inc ax
        mov word ptr ds:[y_start], ax

        call select_y_line      ;move file pointer to the next BMP line that will be displayed in the next iteration

        pop cx
        inc cx
        mov word ptr ds:[y_curr], cx
        cmp cx, VGAHeight
        jnz loop_y  ;check condition for loop_y

    pop ax
    mov word ptr ds:[y_start], ax ;revert y_start value from before the loop_y - for keyboard boundary check



    read_key:           ;wait for key
        xor ax, ax
        int 16h

        esc_check:
            cmp ah, 1  ;ESC keystroke
            jz exit

        plus_check:
            cmp ah, 78  ;plus keystroke (numpad)
            jnz minus_check
            scale_minimum_check:                ;check if can decrement scale
                mov cx, word ptr ds:[scale]
                cmp cx, 1
                jz skip
                dec cx
                mov word ptr ds:[scale], cx
                mov word ptr ds:[x_start], 0
                mov word ptr ds:[y_start], 0
                jmp skip

        minus_check:
            cmp ah, 74 ;minus keystroke (numpad)
            jnz up_arrow_check
            mov ax, word ptr ds:[scale]
            inc ax
            mov word ptr ds:[scale], ax
            call check_scale                   ;check if can increment scale
            jmp skip

        up_arrow_check:                         ;check if new y_start will be in [0,y_max]
            cmp ah, 72 ;up arrow keystroke
            jnz down_arrow_check
            mov dx, word ptr ds:[y_start]
            cmp dx, 0
            jz skip
            dec dx
            mov word ptr ds:[y_start], dx
            jmp skip
        
        down_arrow_check:
            cmp ah, 80 ;down arrow keystroke
            jnz left_arrow_check
            mov bx, word ptr ds:[y_max]
            mov dx, word ptr ds:[y_start]
            cmp bx, dx
            jz skip
            inc dx
            mov word ptr ds:[y_start], dx
            jmp skip

        left_arrow_check:                      ;check if new x_start will be in [0,x_max]
            cmp ah, 75 ;left arrow keystroke
            jnz right_arrow_check
            mov dx, word ptr ds:[x_start]
            cmp dx, 0
            jz skip
            dec dx
            mov word ptr ds:[x_start], dx
            jmp skip

        right_arrow_check:
            cmp ah, 77 ;right arrow keystroke
            jnz skip
            mov bx, word ptr ds:[x_max]
            mov dx, word ptr ds:[x_start]
            cmp bx, dx
            jz skip
            inc dx
            mov word ptr ds:[x_start], dx
            jmp skip

skip:                               ;repeat displaying the picture
    jmp main_loop

exit:
    ;close file
    mov bx, word ptr ds:[file_handle]
    xor ax, ax
    mov ah, 3eh
    int 21h

    call text_mode

    ;exit program
    mov ax, 4c00h
    int 21h

error_occured:
    mov dx, offset test_error
    mov ah, 9
    int 21h
    ;exit program
    mov ax, 4c00h
    int 21h

error_occured_invalid_format:
    mov dx, offset test_invalid_format
    mov ah, 9
    int 21h
    ;exit program
    mov ax, 4c00h
    int 21h

error_occured_unsupported_color_depth:
    mov dx, offset test_unsupported_color_depth
    mov ah, 9
    int 21h
    ;exit program
    mov ax, 4c00h
    int 21h
;///////////////////////////////

;check if BMP file begins with "BM"
validate_file:                          
    mov ax, word ptr ds:[file_header]
    mov ch, 'M'
    mov cl, 'B'
    cmp ax, cx
    jnz error_occured_invalid_format
    ret

text_mode:
    mov al, 3h
    mov ah, 0
    int 10h
    ret

graphics_mode:
    mov al, 13h
    mov ah, 0
    int 10h
    ret

;read data from file using ah 3fh and int 21 interruption
read_data: 
    mov bx, word ptr ds:[file_handle]
    xor ax, ax
    mov ah, 3fh
    int 21h
    ret 

move_file_pointer:
    ; cx:dx specify new positon
    ; al = 0 from beginning, al = 1 from current position, al = 2 from end
    mov ah, 42h
    mov bx, word ptr ds:[file_handle]
    int 21h
    jc error_occured
    ret

;assuming scale is valid, calculate maximal possible relative x_max, y_max
calculate_max_for_zoom:
    read_x_data:
        mov ax, word ptr ds:[BMPWidth]
        xor dx, dx
        mov bx, word ptr ds:[scale]
        div bx
        cmp dx, 0
        jz calculate_x_max
        inc ax      ;if there is a rest, use it for the last file line

    calculate_x_max:
        mov bx, VGAWidth
        sub ax, bx
        mov word ptr ds:[x_max], ax   

    read_y_data:
        mov ax, word ptr ds:[BMPHeight]
        xor dx, dx
        mov bx, word ptr ds:[scale]
        div bx
        cmp dx, 0
        jz calculate_y_max
        inc ax ;if there is a rest, use it for the last file line

    calculate_y_max:
        mov bx, VGAHeight
        sub ax, bx
        mov word ptr ds:[y_max], ax
    ret        

;check if scale change is valid - if new scale makes picture smaller than the display, scale change is reverted
check_scale:
    scale_read_x_data:
        mov ax, word ptr ds:[BMPWidth]
        xor dx, dx
        mov bx, word ptr ds:[scale]
        div bx
        cmp dx, 0
        jz scale_calculate_x_max
        inc ax

    scale_calculate_x_max:
        mov bx, VGAWidth
        cmp ax, bx
        jc revert_scale

    scale_read_y_data:
        mov ax, word ptr ds:[BMPHeight]
        xor dx, dx
        mov bx, word ptr ds:[scale]
        div bx
        cmp dx, 0
        jz scale_calculate_y_max
        inc ax

    scale_calculate_y_max:
        mov bx, VGAHeight
        cmp ax, bx
        jc revert_scale
    
    ;move to the left upper edge of picture if scale is valid
    mov word ptr ds:[x_start], 0
    mov word ptr ds:[y_start], 0
    ret

;revert changes if scale turns out to be too big for selected picture
revert_scale:
    mov ax, word ptr ds:[scale]
    dec ax
    mov word ptr ds:[scale], ax
    ret


select_y_line:
    xor cx, cx
    xor dx, dx
    
    ;move pointer to the end of file
    mov al, 2h
    call move_file_pointer

    xor cx, cx   
        move_file_pointer_backwards_loop:
            push cx
            ;from given point, go backwards BMPWidth*bytes_per_pixel
            mov ax, 1h
            mov bx, word ptr ds:[BMPWidth]
            mul bx
            mov bx, word ptr ds:[bytes_per_pixel]
            mul bx
            mov cx, 0ffffh
            xor dx, dx
            sub dx, ax
            clc
            mov al, 01h                 ;set pointer from the current position
            call move_file_pointer

            pop cx
            inc cx
            mov bx, word ptr ds:[scale]
            mov ax, word ptr ds:[y_start]
            mul bx
            mov bx, ax
            inc bx
            cmp bx, cx
            jnz move_file_pointer_backwards_loop ;repeat moving file pointer backawrds scale * y_start+1 times 
                                                 ;(+1 is added as new file line will be read and file pointer will be moved by that 1 line)
    ret

generate_color_palette:
    ;generate and load own RRRGGGBB (8-bit) color palette for 24-bit color bitmaps
    mov dx, 3c8h
    xor al, al  ;define all 256 colors of VGA palette, start from 0
    out dx, al

    mov dx, 3c9h
    xor bl, bl   ;color index

    palette_loop:
        ;generate red canal
        mov al, bl
        and al, 11100000b   ;RRR00000
        mov cl, 5
        shr al, cl
        mov cl, 9
        mul cl  ;scale [0-7] to [0-63] (VGA supports 64 values for each color)
        out dx, al

        ;generate green canal
        mov al, bl
        and al, 00011100b   ;000GGG00
        mov cl, 2
        shr al, cl
        mov cl, 9
        mul cl ;scale [0-7] to [0-63] (VGA supports 64 values for each color)
        out dx, al

        ;generate blue canal
        mov al, bl
        and al, 00000011b   ;000000BB
        mov cl, 21
        mul cl ;scale [0-3] to [0-63] (VGA supports 64 values for each color)
        out dx, al

        inc bl
        cmp bl, 0
    jnz palette_loop

    jmp main_loop

load_color_palette_to_vga:
    ;load color palette defined after bitmap header (8-bit color bitmaps)
    mov dx, 3c8h
    xor al, al  ;define all 256 colors of VGA palette, start from 0
    out dx, al

    mov dx, 3c9h
    xor bx, bx

    load_palette_loop:
        ;load blue canal
        mov al, ds:[color_palette + bx]
        mov cl, 2
        shr al, cl ;VGA uses only 6 bits for each color (value in [0-63])
        mov byte ptr ds:[b], al
        inc bx

        ;load green canal
        mov al, ds:[color_palette + bx]
        mov cl, 2
        shr al, cl ;VGA uses only 6 bits for each color (value in [0-63])
        mov byte ptr ds:[g], al
        inc bx

        ;load red canal
        mov al, ds:[color_palette + bx]
        mov cl, 2
        shr al, cl ;VGA uses only 6 bits for each color (value in [0-63])
        mov byte ptr ds:[r], al
        inc bx

        mov al, byte ptr ds:[r]
        out dx, al
        mov al, byte ptr ds:[g]
        out dx, al
        mov al, byte ptr ds:[b]
        out dx, al

        inc bx ;skip unused byte

        cmp bx, 1024
    jnz load_palette_loop

    jmp main_loop

;convert three bytes from 24-bit BMP pixel to one RRRGGGBB byte related to defined color palette
convert_from_24bit:
    mov al, byte ptr ds:[r]
    and al, 11100000b
    mov byte ptr ds:[pixel_color], al

    mov al, byte ptr ds:[g]
    and al, 11100000b
    mov cl, 3
    shr al, cl
    mov ah, byte ptr ds:[pixel_color] 
    add ah, al
    mov byte ptr ds:[pixel_color], ah

    mov al, byte ptr ds:[b]
    and al, 11000000b
    mov cl, 6
    shr al, cl
    mov ah, byte ptr ds:[pixel_color] 
    add ah, al
    mov byte ptr ds:[pixel_color], ah
    ret


show_pixel:
    mov ax, 0a000h
    mov es, ax ; select VGA segment
    mov bx, VGAWidth
    mov ax, word ptr ds:[y_curr]
    mul bx ; dx:ax <- ax*bx => ax=VGAWidth*y
    mov bx, word ptr ds:[x_curr]
    add bx, ax ; bx = 320*y + x
    mov al, byte ptr ds:[pixel_color]
    mov byte ptr es:[bx], al
    ret    

code1 ends


;;//////////////////////////STACK SEGMENT/////////////////////////////////////
stack1 segment STACK

        dw 600 dup(?) ;initialize stack memory
top1    dw ?          ;define stack begin

stack1 ends

end start
