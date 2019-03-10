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
fifteen   db "fifteen$"
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

space     db " $"


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
third_arg       db 0
result          db ?

minus_flag      db 0

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
    jmp arg1_parsing

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
      jmp arg1_parsing
;///////////////////////////////////////////////////
;---------------------------------------------------


;///////////////////////////////////////////////////
;WLASCIWE PARSOWANIE POSZCZEGOLNYCH ARGUMENTOW

;CL -> aktualnie sprawdzana cyfra -> jesli dochodzi do 10, to znaczy, ze jest bledny argument
;SI -> ustawione na poczatek sprawdzanego obecnie argumentu
;DI -> sluzy do iterowania po wzoracach slow oznaczajacych cyfry

  arg1_parsing:
    mov cl, 0
    ;mov si, offset in_first_word
    mov ax, offset zero
    mov di, ax

    parse_arg1_loop:
      mov al, cl
      mov ah, 10
      cmp ah, al
      jz invalid_first

      mov ax, offset in_first_word
      mov si, ax

      iterate_arg1_chars:
        mov al, '$'
        mov ah, byte ptr ds:[si]
        cmp ah, al
        jz arg1_end_reached     ;osiagneto koniec argumentu wejsciowego, sprawdzanie czy osiagneto tez koniec wzorca

        mov al, '$'
        mov ah, byte ptr ds:[di]
        cmp ah, al
        jz  pattern1_end_reached  ;osiagneto koniec wzorca

        mov al, ds:[si]
        mov ah, ds:[di]
        cmp ah, al ;wlasciwe porownywanie danego znaku wzorca i argumentu
        jz chars_match1
        jmp move_to_next_pattern1 ;jesli znaki sie nie zgadzaja, zacznij porownywanie z kolejnym wzorcem


        chars_match1:
          inc di
          inc si
          jmp iterate_arg1_chars

        pattern1_end_reached:
          inc di ;ustaw di na poczatek nowego wzoraca
          inc cl ;rozpatrywanie kolejnej cyfry
          jmp parse_arg1_loop

        arg1_end_reached:   ;sprawdzanie, czy osiagnieto tez koniec wzorca
          mov al, '$'
          mov ah, byte ptr ds:[di]
          cmp ah, al
          jz save_arg1_value

        move_to_next_pattern1:  ;jesli nie osiagnieto, nalezy przesunac wskaznik DI na poczatek nowego wzorca
          inc di
          mov ah, ds:[di]
          mov al, '$'
          cmp ah, al
          jnz move_to_next_pattern1
          inc di      ;ustaw di na poczatek kolejnego wzorca
          inc cl
          jmp parse_arg1_loop

        save_arg1_value:
          mov ax, offset first_arg
          mov di, ax
          mov al, cl
          mov ds:[di], al
          jmp arg2_parsing


  arg2_parsing:
    mov cl, 0
    mov di, offset plus

    parse_arg2_loop:
      mov al, cl
      mov ah, 3
      cmp ah, al
      jz invalid_second

      mov ax, offset in_second_word
      mov si, ax

      iterate_arg2_chars:
        mov al, '$'
        mov ah, byte ptr ds:[si]
        cmp ah, al
        jz arg2_end_reached     ;osiagneto koniec argumentu wejsciowego, sprawdzanie czy osiagneto tez koniec wzorca

        mov al, '$'
        mov ah, byte ptr ds:[di]
        cmp ah, al
        jz  pattern2_end_reached  ;osiagneto koniec wzorca

        mov al, ds:[si]
        mov ah, ds:[di]
        cmp ah, al ;wlasciwe porownywanie danego znaku wzorca i argumentu
        jz chars_match2
        jmp move_to_next_pattern2 ;jesli znaki sie nie zgadzaja, zacznij porownywanie z kolejnym wzorcem


        chars_match2:
          inc di
          inc si
          jmp iterate_arg2_chars

        pattern2_end_reached:
          inc di ;ustaw di na poczatek nowego wzoraca
          inc cl ;rozpatrywanie kolejnego operatora
          jmp parse_arg2_loop

        arg2_end_reached:   ;sprawdzanie, czy osiagnieto tez koniec wzorca
          mov al, '$'
          mov ah, byte ptr ds:[di]
          cmp ah, al
          jz save_arg2_value

        move_to_next_pattern2:  ;jesli nie osiagnieto, nalezy przesunac wskaznik DI na poczatek nowego wzorca
          inc di
          mov ah, ds:[di]
          mov al, '$'
          cmp ah, al
          jnz move_to_next_pattern2
          inc di      ;ustaw di na poczatek kolejnego wzorca
          inc cl
          jmp parse_arg2_loop

        save_arg2_value:
          mov al, cl
          mov di, offset second_arg
          mov ds:[di], al
          jmp arg3_parsing


  arg3_parsing:
    mov cl, 0
    mov di, offset zero

    parse_arg3_loop:
      mov al, cl
      mov ah, 10
      cmp ah, al
      jz invalid_third

      mov ax, offset in_third_word
      mov si, ax

      iterate_arg3_chars:
        mov al, '$'
        mov ah, byte ptr ds:[si]
        cmp ah, al
        jz arg3_end_reached     ;osiagneto koniec argumentu wejsciowego, sprawdzanie czy osiagneto tez koniec wzorca

        mov al, '$'
        mov ah, byte ptr ds:[di]
        cmp ah, al
        jz  pattern3_end_reached  ;osiagneto koniec wzorca

        mov al, ds:[si]
        mov ah, ds:[di]
        cmp ah, al ;wlasciwe porownywanie danego znaku wzorca i argumentu
        jz chars_match3
        jmp move_to_next_pattern3 ;jesli znaki sie nie zgadzaja, zacznij porownywanie z kolejnym wzorcem


        chars_match3:
          inc di
          inc si
          jmp iterate_arg3_chars

        pattern3_end_reached:
          inc di ;ustaw di na poczatek nowego wzoraca
          inc cl ;rozpatrywanie kolejnej cyfry
          jmp parse_arg3_loop

        arg3_end_reached:   ;sprawdzanie, czy osiagnieto tez koniec wzorca
          mov al, '$'
          mov ah, byte ptr ds:[di]
          cmp ah, al
          jz save_arg3_value

        move_to_next_pattern3:  ;jesli nie osiagnieto, nalezy przesunac wskaznik DI na poczatek nowego wzorca
          inc di
          mov ah, ds:[di]
          mov al, '$'
          cmp ah, al
          jnz move_to_next_pattern3
          inc di      ;ustaw di na poczatek kolejnego wzorca
          inc cl
          jmp parse_arg3_loop

        save_arg3_value:
          mov al, cl
          mov di, offset third_arg
          mov ds:[di], al
          jmp make_operation

;////////////////////////////////////////////////////
;----------------------------------------------------

  make_operation:
    mov ax, offset second_arg
    mov si, ax
    mov al, ds:[si]
    cmp al, 0
    jz addition
    cmp al, 1
    jz subtraction
    jmp multiplication

  addition:
    mov ax, offset first_arg
    mov si, ax
    mov ax, offset third_arg
    mov di, ax
    mov ah, ds:[si]
    mov al, ds:[di]
    add ah, al
    mov dl, ah
    mov ax, offset result
    mov di, ax
    mov byte ptr ds:[di], dl
    jmp show_result

  subtraction:
    mov ax, offset first_arg
    mov si, ax
    mov ax, offset third_arg
    mov di, ax
    mov ah, ds:[si]
    mov al, ds:[di]
    cmp ah, al
    jc swap_arguments_and_set_minus
    sub ah, al
    mov dl, ah
    mov ax, offset result
    mov di, ax
    mov byte ptr ds:[di], dl
    jmp show_result

    swap_arguments_and_set_minus:
    mov dl, ah
    mov ah, al
    mov al, dl
    sub ah, al
    mov dl, ah
    mov ax, offset result
    mov di, ax
    mov byte ptr ds:[di], dl
    mov ax, offset minus_flag
    mov di, ax
    mov byte ptr ds:[di], 1
    jmp show_result

  multiplication:
    mov ax, offset first_arg
    mov si, ax
    mov ax, offset third_arg
    mov di, ax
    mov ah, 0
    mov al, ds:[di]
    mov ch, 0
    mov cl, ds:[si]
    mul cx
    mov dl, al
    mov ax, offset result
    mov di, ax
    mov byte ptr ds:[di], dl


;//////////////////////////////////////////WYPISYWANIE WYNIKU

  show_result:
    mov dx, offset result_msg
    mov ah, 9
    int 21h

    mov ax, offset minus_flag
    mov si, ax
    mov al, ds:[si]
    cmp al, 0
    jz number_size_check

  show_minus:
    mov dx, offset minus
    mov ah, 9
    int 21h
    mov dx, offset space
    mov ah, 9
    int 21h

  number_size_check:
    mov si, offset result
    mov ah, 20
    mov al, ds:[si]
    cmp ah, al
    jc more_than_twenty   ;sprawdza, czy wynik mozna wypisac jednym slowem (czyli czy nie jest wiekszy niz 20)

    mov cl, 0

    select_number_loop:
      cmp al, cl
      jz print_number
        move_to_next_number:
        


  print_number
    mov

  more_than_twenty:


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
