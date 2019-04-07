;Project 02 - BMP file viewer
;Created by Filip Slazyk
;AGH UST 2019

;;//////////////////////////DATA SEGMENT/////////////////////////////////////
data1 segment

;error messages
test_error db "Error occured$"
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

x_curr db ?
y_curr db ?

;color values for each canal
r db ?
g db ?
b db ?

;pixel color to be displayed (related to the current color palette)
pixel_color db ?

data1 ends


;;//////////////////////////CODE SEGMENT/////////////////////////////////////
code1 segment

    ;file header - 14 bytes
    ;bitmap header - 40 bytes
start:
    VGAWidth equ 320
    VGAHeight equ 200
    BMPWidth equ bitmap_header + 4
    BMPHeight equ bitmap_header + 8
    BitsPerPixel equ bitmap_header + 14
    BMPOffset equ file_header + 10

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

    call validate_file ;check if header begins with "BM"

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
    mov bx, 8
    div bx
    mov byte ptr ds:[bytes_per_pixel], al

    call graphics_mode ;enter 320x200 mode

    ;load bitmap color palette (for 8-bit color bitmaps) or generate own (for 24-bit color bitmaps)
    cmp word ptr ds:[bytes_per_pixel], 1
    jnz generate_color_palette
    mov dx, offset color_palette
    mov cx, 1024    ;256 rows of R=(1 Byte) G=(1 Byte) B=(1 Byte) (Unused)=(1 Byte)
    call read_data
    jmp load_color_palette_to_vga

main_loop:

;////////////////SHOW FILE FIRST ATTEMPT
    mov al, 2
    xor cx, cx
    xor dx, dx
    
    ;cx:dx - new location

    show_loop:
        mov al, 2
        ; push cx
        ; push dx
        ; call move_file_pointer
        ; pop dx
        ; pop cx

        push dx
        push cx
        ;read pixel color
        mov dx, offset b
        mov cx, 1
        call read_data
        pop cx
        pop dx

        push dx
        push cx
        ;read pixel color
        mov dx, offset g
        mov cx, 1
        call read_data
        pop cx
        pop dx

        push dx
        push cx
        ;read pixel color
        mov dx, offset r
        mov cx, 1
        call read_data
        pop cx
        pop dx


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

        mov ax, 0a000h
        mov es, ax ; select VGA segment

        mov al, byte ptr ds:[pixel_color]

        mov bx, dx

        mov byte ptr es:[bx], al

        inc dx
        cmp dx, 320*200
    jnz show_loop




    ; show_loop:
    ;     mov al, 2
    ;     ; push cx
    ;     ; push dx
    ;     ; call move_file_pointer
    ;     ; pop dx
    ;     ; pop cx

    ;     push dx
    ;     push cx
    ;     ;read pixel color
    ;     mov dx, offset pixel_color
    ;     mov cx, 1
    ;     call read_data
    ;     pop cx
    ;     pop dx

    ;     mov ax, 0a000h
    ;     mov es, ax ; select VGA segment

    ;     mov al, byte ptr ds:[pixel_color]

    ;     mov bx, dx

    ;     mov byte ptr es:[bx], al

    ;     inc dx
    ;     cmp dx, 320*200
    ; jnz show_loop

;////////////////SHOW FILE FIRST ATTEMPT ENDS
while_true:
    jmp while_true

skip:
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
    mov dx, offset error_occured_unsupported_color_depth
    mov ah, 9
    int 21h
    ;exit program
    mov ax, 4c00h
    int 21h
;///////////////////////////////

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

read_data: 
    mov bx, word ptr ds:[file_handle]
    xor ax, ax
    mov ah, 3fh ; read
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


show_pixel:
    mov ax, 0a000h
    mov es, ax ; select VGA segment
    mov bx, VGAWidth
    mov ax, word ptr ds:[y_curr]
    mul bx ; dx:ax <- ax*bx => ax=320*y
    mov bx, word ptr ds:[x_curr]
    add bx, ax ; bx = 320*y + x
    mov al, byte ptr ds:[pixel_color]
    mov byte ptr es:[bx], al
    ret    


code1 ends


;;//////////////////////////STACK SEGMENT/////////////////////////////////////
stack1 segment STACK

        dw 200 dup(?) ;initialize stack memory
top1    dw ?          ;define stack begin

stack1 ends

end start
