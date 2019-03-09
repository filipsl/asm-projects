;Project 01 - Verbal calculator
;Created by Filip SLazyk
;AGH UST 2019


;segment danych
data1 segment

new_ln_chars   db 10,13,'$'                                 ;nowa linia
hello_msg      db "Enter a description of a calculation: $" ;wiadomosc startowa
result_msg     db "The result is: $"                        ;wiadomosc z wynikiem
error_msg      db "Error - invalid input!",10,13,'$'        ;wiadmosc bledu - wprowadzono za malo lub za duzo argumentow
err_first      db "Error - invalid first argument",10,13,'$';wiadmosc bledu - bledny pierwszy argument
err_second     db "Error - invalid second argument",10,13,'$';wiadmosc bledu - bledny drugi argument
err_third      db "Error - invalid third argument",10,13,'$';wiadmosc bledu - bledny trzeci argument

;definicja nazw liczb
zero      db "zero",0
one       db "one",0
two       db "two",0
three     db "three",0
four      db "four",0
five      db "five",0
six       db "six",0
seven     db "seven",0
eight     db "eight",0
nine      db "nine",0

ten       db "ten",0
eleven    db "eleven",0
twelve    db "twelve",0
thirteen  db "thirteen",0
fourteen  db "fourteen",0
fifteen   db "nineteen",0
sixteen   db "sixteen",0
seventeen db "seventeen",0
eighteen  db "eighteen",0
nineteen  db "nineteen",0

twenty    db "twenty",0
thirty    db "thirty",0
forty     db "forty",0
fifty     db "fifty",0
sixty     db "sixty",0
seventy   db "seventy",0
eighty    db "eighty",0

;definicja nazw operacji
plus  db "plus",0     ;kod operacji 0
minus db "minus",0    ;kod operacji 1
tim   db "times",0    ;kod operacji 2

;bufor wejsciowy
input_buffer:
  size_of_buffer db 30
  actual_size    db ?
  buffer_memory  db 30 dup(0)

parsed_arguments_number db 0
error_code db 0

in_first_word   db 30 dup(0)
in_second_word  db 30 dup(0)
in_third_word   db 30 dup(0)

first_arg       db 0
second_arg      db 0
operation_code  db 0

data1 ends


;segment programu
code1 segment

start:
  ;inicjalizacja stosu
  mov al, seg top1
  mov ss, ax
  mov sp, offset top1

  ;wskazanie segmentu danych
  mov ax, seg input_buffer
  mov ds, ax

  hello_message:
    mov dx, offset hello_msg
    mov ah, 9
    int 21h

  read_input:
    mov dx, offset input_buffer
    mov ah, 0ah
    int 21h

  call new_line


;///////////////////////////////////////////////////
;INPUT PARSING

  ;sprawdzenie, czy na wejsciu znajduja sie trzy slowa
  ;di przechowuje adres na aktualnie wczytywane slowo
  input_check:
    mov si, offset buffer_memory
    skip_spaces0:
      inc si
      mov al, [ds][si-1]
      cmp al, 20h  ;spacja
      jz skip_spaces0

    mov di, offset in_first_word
    arg1_loop:
      cmp al, 0dh         ;Carriage Return
      jz invalid_input
      mov [di], al
      inc di
      inc si
      mov al, [ds][si-1]
      cmp al, 20h
      jnz arg1_loop

    mov al, '$'
    mov [di], al

    skip_spaces1:
      inc si
      mov al, [ds][si-1]
      cmp al, 20h  ;spacja
      jz skip_spaces1

    mov di, offset in_second_word
    arg2_loop:
      cmp al, 0dh         ;Carriage Return
      jz invalid_input
      mov [di], al
      inc di
      inc si
      mov al, [ds][si-1]
      cmp al, 20h
      jnz arg2_loop

    mov al, '$'
    mov [di], al

    skip_spaces2:
      inc si
      mov al, [ds][si-1]
      cmp al, 20h  ;spacja
      jz skip_spaces2

    cmp al, 0dh         ;Carriage Return
    jz invalid_input

    mov di, offset in_third_word
    arg3_loop:
      mov [di], al
      inc di
      inc si
      mov al, [ds][si-1]
      cmp al, 20h
      jz check_excess
      cmp al, 0dh
      jnz arg3_loop

    mov al, '$'
    mov [di], al
    jmp exit

    check_excess:
      mov al, '$'
      mov [di], al
      skip_spaces3:
        inc si
        mov al, [ds][si-1]
        cmp al, 20h  ;spacja
        jz skip_spaces3
      cmp al, 0dh
      jnz invalid_input
      jmp exit


;///////////////////////////////////////////////////


  mov al, error_code
  cmp al, 0
  jnz print_error_msg

  ;zakonczenie programu
  exit:
    mov ax, 04c00h ;kod zakonczenia programu, systemowy error code = 0
    int 21h ;wywolanie przerwania systemu DOS


  new_line:
    mov dx, offset new_ln_chars
    mov ah, 9
    int 21h
    ret


  print_error_msg:
    mov al, error_code
    cmp al, 1
    jz invalid_first
    mov al, error_code
    cmp al, 2
    jz invalid_second
    mov al, error_code
    cmp al, 3
    jz invalid_third
    jmp invalid_input ;domyslnie wypisywany jest blad wejscia

  invalid_first:
    mov dx, offset err_first
    mov ah, 9
    int 21h
    jmp exit

  invalid_second:
    mov dx, offset err_second
    mov ah, 9
    int 21h
    jmp exit

  invalid_third:
    mov dx, offset err_third
    mov ah, 9
    int 21h
    jmp exit

  invalid_input:
    mov dx, offset error_msg
    mov ah, 9
    int 21h
    jmp exit

code1 ends


;segment stosu
stack1 segment STACK
     dw 200 dup(?) ;wypelnij stos 200 dowolnymi slowami
top1 dw ?          ;okresla wierzcholek stosu
stack1 ends

end start
