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
zero      db "zero$"
one       db "one$"
two       db "two$"
three     db "three$"
four      db "four$"
five      db "five$"
six       db "six$"
seven     db "seven$"
eight     db "eight$"
nine      db "nine$"

ten       db "ten$"
eleven    db "eleven$"
twelve    db "twelve$"
thirteen  db "thirteen$"
fourteen  db "fourteen$"
fifteen   db "nineteen$"
sixteen   db "sixteen$"
seventeen db "seventeen$"
eighteen  db "eighteen$"
nineteen  db "nineteen$"

twenty    db "twenty$"
thirty    db "thirty$"
forty     db "forty$"
fifty     db "fifty$"
sixty     db "sixty$"
seventy   db "seventy$"
eighty    db "eighty$"

;definicja nazw operacji
plus  db "plus$"     ;kod operacji 0
minus db "minus$"    ;kod operacji 1
tim   db "times$"    ;kod operacji 2

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
  mov ax, seg top1
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
;WSTEPNE SPRAWDZENIE POPRAWNOSCI WEJSCIA

  ;sprawdzenie, czy na wejsciu znajduja sie trzy slowa
  ;di przechowuje adres na aktualnie wczytywane slowo
  input_check:
    mov si, offset buffer_memory
    skip_spaces0:
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h  ;spacja
      jz skip_spaces0

    mov di, offset in_first_word
    arg1_loop:
      cmp al, 0dh         ;Carriage Return
      jz invalid_input
      mov [di], al
      inc di
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h
      jnz arg1_loop

    mov al, '$'
    mov [di], al

    skip_spaces1:
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h  ;spacja
      jz skip_spaces1

    mov di, offset in_second_word
    arg2_loop:
      cmp al, 0dh         ;Carriage Return
      jz invalid_input
      mov [di], al
      inc di
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h
      jnz arg2_loop

    mov al, '$'
    mov [di], al

    skip_spaces2:
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h  ;spacja
      jz skip_spaces2

    cmp al, 0dh         ;Carriage Return
    jz invalid_input

    mov di, offset in_third_word
    arg3_loop:
      mov [di], al
      inc di
      inc si
      mov al, byte ptr ds:[si-1]
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
        mov al, byte ptr ds:[si-1]
        cmp al, 20h  ;spacja
        jz skip_spaces3
      cmp al, 0dh
      jnz invalid_input
      jmp exit
;///////////////////////////////////////////////////
;---------------------------------------------------


;///////////////////////////////////////////////////
;WLASCIWE PARSOWANIE POSZCZEGOLNYCH ARGUMENTOW



;////////////////////////////////////////////////////
;----------------------------------------------------


  mov al, byte ptr ds:[error_code]
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
    mov al, byte ptr ds:[error_code]
    cmp al, 1
    jz invalid_first
    mov al, byte ptr ds:[error_code]
    cmp al, 2
    jz invalid_second
    mov al, byte ptr ds:[error_code]
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
