;Project 01 - Kalkulator slowny
;Created by Filip SLazyk
;AGH UST 2019


;;//////////////////////////SEGMENT DANYCH/////////////////////////////////////
data1 segment

new_ln_chars   db 10,13,'$'                                 ;nowa linia
space          db " $"                                      ;spacja
hello_msg      db "Enter description of calculation: $"     ;wiadomosc startowa
result_msg     db "The result is: $"                        ;wiadomosc z wynikiem
error_msg      db "Error - invalid input!$"                 ;wiadmosc bledu - wprowadzono za malo lub za duzo argumentow
err_first      db "Error - invalid first argument$"         ;wiadmosc bledu - bledny pierwszy argument
err_second     db "Error - invalid second argument$"        ;wiadmosc bledu - bledny drugi argument
err_third      db "Error - invalid third argument$"         ;wiadmosc bledu - bledny trzeci argument

;definicja nazw liczb - sluzy do weryfikacji wprowadzonych argumentow, jak i wypisywania wyniku
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
;ponizsze definicje sluza juz tylko do wypisywania wyniku
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
;definicja nazw wielokrotnosci liczby dziesiec
twenty    db "twenty$"
thirty    db "thirty$"
forty     db "forty$"
fifty     db "fifty$"
sixty     db "sixty$"
seventy   db "seventy$"
eighty    db "eighty$" ;maksymalny wynik, jaki mozna uzyskac, to 81 = 9 * 9


;definicja nazw operacji
plus  db "plus$"     ;kod operacji = 0
minus db "minus$"    ;kod operacji = 1
tim   db "times$"    ;kod operacji = 2


;bufor wejsciowy - sluzy do wczytywania wejscia
;(przygotowany dla obslugi przerwania int 21 z parametrem AH = 0Ah)
input_buffer:
  size_of_buffer db 30            ;maksymalny dopuszczalny rozmiar wejscia
  actual_size    db ?             ;rozmiar wejscia wpisanego przez uzytkownika
  buffer_memory  db 30 dup(0)     ;ciag bajtow odpowiadajacy kolejny wprowadzonym znakom

;poszczegolne slowa wprowadzone przez uzytkownika
in_first_word   db 30 dup(0)
in_second_word  db 30 dup(0)
in_third_word   db 30 dup(0)

;wartosci liczbowe odpowiadajace poszczegolnym slowom (operacja ma swoj kod)
first_arg       db 0
second_arg      db 0
third_arg       db 0

;wynik dzialania
result          db ?
minus_flag      db 0 ;jesli wykonywane jest odejmowanie, flaga minus ustawiana jest na 1
                     ;(uzywane przy wypisywaniu wyjscia)
data1 ends




;//////////////////////////SEGMENT PROGRAMU/////////////////////////////////////
code1 segment

start:
  ;inicjalizacja stosu
  mov ax, seg top1
  mov ss, ax
  mov sp, offset top1

  ;wskazanie segmentu danych
  mov ax, seg input_buffer
  mov ds, ax

  hello_message:              ;wyswietlenie wiadomosci powitalnej
    mov dx, offset hello_msg
    mov ah, 9
    int 21h

  read_input:                 ;buforowane wczytywanie wejscia
    mov dx, offset input_buffer
    mov ah, 0ah
    int 21h

  call new_line               ;przejscie do nowej linii

;///////////////////////////////////////////////////
;WSTEPNE SPRAWDZENIE POPRAWNOSCI WEJSCIA
;///////////////////////////////////////////////////

;sprawdzenie, czy na wejsciu znajduja sie trzy slowa
;jesli nie, wyswietlany jest komunikat i program konczy sie

  input_check:
    mov si, offset buffer_memory    ;rejestr SI wskazuje na poczatek bufora
    skip_spaces0:                   ;usuwanie spacji na poczatku wejscia
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h  ;ASCII 20h = spacja
      jz skip_spaces0               ;SI przesuwane jest na kolejne bajty,
                                    ;az zacznie wskazywac na znak rozny od spacji

    mov di, offset in_first_word    ;DI wskazuje na pierwszy bajt pamieci, gdzie zapisane bedzie pierwsze slowo
    arg1_loop:                      ;przetwarzanie pierwszego slowa
      cmp al, 0dh         ;ASCII 0dh = Carriage Return
      jz invalid_input    ;jesli tutaj program natrafia na CR, wprowadzono niewlasciwe wejscie
      mov ds:[di], al     ;zapisywanie kolejnych bajtow pierwszego slowa do pamieci
      inc di              ;przejscie do kolejnego bajtu wejscia i wyniku parsowania
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h       ;ASCII 20h = spacja
      jnz arg1_loop     ;jesli natrafiamy na spacje, oznacza to przejscie dalej

    mov al, '$'         ;na koniec pierwszego slowa dodajemy znak '$' - dla latwiejszego przetwarzania
    mov ds:[di], al

    skip_spaces1:      ;analogicznie, przechodzenie przez spacje miedzy pierwszym i drugim slowem
      inc si           ;zwiekszamy SI tak dlugo, az bedzie wskazywac na znak inny od spacji
      mov al, byte ptr ds:[si-1]
      cmp al, 20h     ;ASCII 20h = spacja
      jz skip_spaces1

    mov di, offset in_second_word ;DI wskazuje na pierwszy bajt pamieci, gdzie zapisane bedzie drugie slowo
    arg2_loop:                    ;przetwarzanie drugiego slowa
      cmp al, 0dh         ;ASCII 0dh = Carriage Return
      jz invalid_input    ;jesli tutaj program natrafia na CR, wprowadzono niewlasciwe wejscie
      mov ds:[di], al     ;zapisywanie kolejnych bajtow drugiego slowa do pamieci
      inc di              ;przejscie do kolejnego bajtu wejscia i wyniku parsowania
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h         ;ASCII 20h = spacja
      jnz arg2_loop       ;jesli natrafiamy na spacje, oznacza to przejscie dalej

    mov al, '$'
    mov ds:[di], al       ;na koniec drugiego slowa dodajemy znak '$' - dla latwiejszego przetwarzania

    skip_spaces2:         ;analogicznie, przechodzenie przez spacje miedzy drugim i trzecim slowem
      inc si              ;zwiekszamy SI tak dlugo, az bedzie wskazywac na znak inny od spacji
      mov al, byte ptr ds:[si-1]
      cmp al, 20h         ;ASCII 20h = spacja
      jz skip_spaces2

    cmp al, 0dh         ;ASCII 0dh = Carriage Return
    jz invalid_input    ;jesli natrafilismy na CR, oznacza to bledne wejscie

    mov di, offset in_third_word  ;DI wskazuje na pierwszy bajt pamieci, gdzie zapisane bedzie trzecie slowo
    arg3_loop:                    ;przetwarzanie trzeciego slowa
      mov ds:[di], al       ;zapisywanie kolejnych bajtow trzeciego slowa do pamieci
      inc di                ;przejscie do kolejnego bajtu wejscia i wyniku parsowania
      inc si
      mov al, byte ptr ds:[si-1]
      cmp al, 20h         ;ASCII 20h = spacja
      jz check_excess     ;jesli po trzecim slowie jest spacja, sprawdzamy, czy nie ma nadmiarowego argumentu
      cmp al, 0dh         ;ASCII 0dh = Carriage Return
      jnz arg3_loop       ;po natrafieniu na CR, przechodzimy dalej

    mov al, '$'         ;na koniec trzeciego slowa dodajemy znak '$' - dla latwiejszego przetwarzania
    mov ds:[di], al
    jmp arg1_parsing    ;przejscie do przetwarzania poszczegolnych argumentow

    check_excess:       ;dodatkowe sprawdzenie, czy trzeci argument jest ostatnim
      mov al, '$'       ;na koniec trzeciego slowa dodajemy znak '$' - dla latwiejszego przetwarzania
      mov [di], al
      skip_spaces3:     ;przechodzenie przez spacje miedzy trzecim slowem, a znakiem innym od spacji
        inc si
        mov al, byte ptr ds:[si-1]
        cmp al, 20h     ;ASCII 20h = spacja
        jz skip_spaces3
      cmp al, 0dh       ;ASCII 0dh = Carriage Return
      jnz invalid_input ;w przypadku wykrycia czwartego argumentu, wypisywany jest komunikat bledu, koniec programu
      jmp arg1_parsing  ;w przeciwnym przypadku, przejscie do parsowania poszczegolnych argumentow

;///////////////////////////////////////////////////



;///////////////////////////////////////////////////
;WLASCIWE PARSOWANIE POSZCZEGOLNYCH ARGUMENTOW
;///////////////////////////////////////////////////

;CL -> aktualnie rozpatrywana cyfra -> jesli dochodzi do 10 (lub 3 dla operatora dzialania),
;      to znaczy, ze podano bledny argument
;SI -> ustawione na poczatek sprawdzanego obecnie argumentu
;DI -> sluzy do iterowania po wzoracach slow oznaczajacych cyfry (lub operatory)

;///////// PIERWSZY ARGUMENT
  arg1_parsing:
    mov cl, 0
    mov di,  offset zero    ;DI ustawiony na poczatek wzorca "zero"

    parse_arg1_loop:        ;petla do rozpatrywania kolejnych cyfr
      mov al, cl
      mov ah, 10
      cmp ah, al
      jz invalid_first      ;jesli licznik CL wskazuje wartosc 10, nie znaleziono wzorca
                            ;=>bledny pierwszy argument
      mov si, offset in_first_word ;SI wskazuje na pierwszy bajt pierwszego argumentu

      iterate_arg1_chars:           ;przejscie po kolejnych bajtach wzorca i pierwszego argumentu
        mov al, '$'
        mov ah, byte ptr ds:[si]
        cmp ah, al
        jz arg1_end_reached     ; ds:[si] = '$': osiagneto koniec argumentu wejsciowego, sprawdzanie czy osiagneto tez koniec wzorca

        mov al, '$'
        mov ah, byte ptr ds:[di]
        cmp ah, al
        jz  pattern1_end_reached  ;osiagneto koniec wzorca

        mov al, byte ptr ds:[si]
        mov ah, byte ptr ds:[di]
        cmp ah, al                ;porownywanie danego znaku wzorca i argumentu
        jz chars_match1
        jmp move_to_next_pattern1 ;jesli znaki sie nie zgadzaja, zacznij porownywanie z kolejnym wzorcem


        chars_match1:           ;jesli znaki wzorca i wejscia sie zgadzaja, przejscie do kolejnych znakow
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
          jz save_arg1_value  ;jesli tak, zapisanie wartosci odpowiadajacej pierwszemu slowu

        move_to_next_pattern1:  ;jesli nie osiagnieto konca wzorca, nalezy przesunac wskaznik DI na poczatek nowego wzorca
          inc di                ;DI zwiekszane do momentu natrafienia na '$' - symbol konca wzorca
          mov ah, ds:[di]
          mov al, '$'
          cmp ah, al
          jnz move_to_next_pattern1
          inc di      ;ustaw di na poczatek kolejnego wzorca
          inc cl      ;rozpatrywanie kolejnej cyfry
          jmp parse_arg1_loop

        save_arg1_value:       ;zapisanie wartosci odpowiadajacej wprowadzonemu slowu
          mov di, offset first_arg
          mov al, cl
          mov ds:[di], al


;///////// DRUGI ARGUMENT
  arg2_parsing:
    mov cl, 0
    mov di,  offset plus    ;DI ustawiony na poczatek wzorca "plus"

    parse_arg2_loop:        ;petla do rozpatrywania kolejnych operacji arytmetycznych
      mov al, cl
      mov ah, 3
      cmp ah, al
      jz invalid_second     ;jesli licznik CL wskazuje wartosc 3, nie znaleziono wzorca
                            ;=>bledny drugi argument
      mov si, offset in_second_word ;SI wskazuje na pierwszy bajt drugiego argumentu

      iterate_arg2_chars:           ;przejscie po kolejnych bajtach wzorca i drugiego argumentu
        mov al, '$'
        mov ah, byte ptr ds:[si]
        cmp ah, al
        jz arg2_end_reached     ; ds:[si] = '$': osiagneto koniec argumentu wejsciowego, sprawdzanie czy osiagneto tez koniec wzorca

        mov al, '$'
        mov ah, byte ptr ds:[di]
        cmp ah, al
        jz  pattern2_end_reached  ;osiagneto koniec wzorca

        mov al, byte ptr ds:[si]
        mov ah, byte ptr ds:[di]
        cmp ah, al                ;porownywanie danego znaku wzorca i argumentu
        jz chars_match2
        jmp move_to_next_pattern2 ;jesli znaki sie nie zgadzaja, zacznij porownywanie z kolejnym wzorcem


        chars_match2:           ;jesli znaki wzorca i wejscia sie zgadzaja, przejscie do kolejnych znakow
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
          jz save_arg2_value  ;jesli tak, zapisanie kodu operacji odpowiadajacej drugiemu slowu

        move_to_next_pattern2:  ;jesli nie osiagnieto konca wzorca, nalezy przesunac wskaznik DI na poczatek nowego wzorca
          inc di                ;DI zwiekszane do momentu natrafienia na '$' - symbol konca wzorca
          mov ah, ds:[di]
          mov al, '$'
          cmp ah, al
          jnz move_to_next_pattern2
          inc di      ;ustaw DI na poczatek kolejnego wzorca
          inc cl      ;rozpatrywanie kolejnej operacji
          jmp parse_arg2_loop

        save_arg2_value:       ;zapisanie wartosci odpowiadajacej wprowadzonemu slowu
          mov di, offset second_arg
          mov al, cl
          mov ds:[di], al

;///////// TRZECI ARGUMENT
  arg3_parsing:
    mov cl, 0
    mov di,  offset zero    ;DI ustawiony na poczatek wzorca "zero"

    parse_arg3_loop:        ;petla do rozpatrywania kolejnych cyfr
      mov al, cl
      mov ah, 10
      cmp ah, al
      jz invalid_third      ;jesli licznik CL wskazuje wartosc 10, nie znaleziono wzorca
                            ;=>bledny trzeci argument
      mov si, offset in_third_word ;SI wskazuje na pierwszy bajt trzeciego argumentu

      iterate_arg3_chars:           ;przejscie po kolejnych bajtach wzorca i trzeciego argumentu
        mov al, '$'
        mov ah, byte ptr ds:[si]
        cmp ah, al
        jz arg3_end_reached     ; ds:[si] = '$': osiagneto koniec argumentu wejsciowego, sprawdzanie czy osiagneto tez koniec wzorca

        mov al, '$'
        mov ah, byte ptr ds:[di]
        cmp ah, al
        jz  pattern3_end_reached  ;osiagneto koniec wzorca

        mov al, byte ptr ds:[si]
        mov ah, byte ptr ds:[di]
        cmp ah, al                ;porownywanie danego znaku wzorca i argumentu
        jz chars_match3
        jmp move_to_next_pattern3 ;jesli znaki sie nie zgadzaja, zacznij porownywanie z kolejnym wzorcem


        chars_match3:           ;jesli znaki wzorca i wejscia sie zgadzaja, przejscie do kolejnych znakow
          inc di
          inc si
          jmp iterate_arg3_chars

        pattern3_end_reached:
          inc di ;ustaw DI na poczatek nowego wzoraca
          inc cl ;rozpatrywanie kolejnej cyfry
          jmp parse_arg3_loop

        arg3_end_reached:   ;sprawdzanie, czy osiagnieto tez koniec wzorca
          mov al, '$'
          mov ah, byte ptr ds:[di]
          cmp ah, al
          jz save_arg3_value  ;jesli tak, zapisanie wartosci odpowiadajacej trzeciemu slowu

        move_to_next_pattern3:  ;jesli nie osiagnieto konca wzorca, nalezy przesunac wskaznik DI na poczatek nowego wzorca
          inc di                ;DI zwiekszane do momentu natrafienia na '$' - symbol konca wzorca
          mov ah, ds:[di]
          mov al, '$'
          cmp ah, al
          jnz move_to_next_pattern3
          inc di      ;ustaw DI na poczatek kolejnego wzorca
          inc cl      ;rozpatrywanie kolejnej cyfry
          jmp parse_arg3_loop

        save_arg3_value:       ;zapisanie wartosci odpowiadajacej wprowadzonemu slowu
          mov di, offset third_arg
          mov al, cl
          mov ds:[di], al
;////////////////////////////////////////////////////


;///////////////////////////////////////////////////
;WYKONANIE OPERACJI NA PODANYCH LICZBACH
;///////////////////////////////////////////////////

  make_operation:         ;blok wyboru rodzaju operacji
    mov ax, offset second_arg     ;drugi argument przechowuje kod operacji
    mov si, ax
    mov al, byte ptr ds:[si]
    cmp al, 0
    jz addition       ;kod operacji = 0 -> dodawanie
    cmp al, 1         ;kod operacji = 1 -> odejmowanie
    jz subtraction
    jmp multiplication  ;w przeciwnym przypdaku, kod operacji = 2 -> mnozenie

  addition:
    mov si, offset first_arg ;SI wskazuje na pierwsza cyfre
    mov di, offset third_arg ;DI wskazuje na druga cyfre
    mov ah, byte ptr ds:[si]
    mov al, byte ptr ds:[di]
    add ah, al              ;wynik dodwania zapisany w AH
    mov di, offset result
    mov byte ptr ds:[di], ah ;zapisanie wyniku w pamieci
    jmp show_result          ;przejscie do wypisania wyniku

  subtraction:
    mov si, offset first_arg
    mov di, offset third_arg
    mov ah, byte ptr ds:[si]
    mov al, byte ptr ds:[di]
    cmp ah, al
    jc swap_arguments_and_set_minus ;jesli a1 - a2 <0, wykonujemy dzialanie a2 - a1 i ustawiamy zmienna "minus_flag"
    sub ah, al                      ;wynik odejmowania zapisany w AH
    mov di, offset result
    mov byte ptr ds:[di], ah  ;zapisanie wyniku w pamieci
    jmp show_result           ;przejscie do wypisania wyniku

    swap_arguments_and_set_minus:
      mov dl, ah    ;zamiana miejsc argumentow z wykorzystaniem DL
      mov ah, al
      mov al, dl
      sub ah, al      ;wynik odejmowania zapisany w AH
      mov di, offset result
      mov byte ptr ds:[di], ah  ;zapisanie wyniku w pamieci
      mov di, offset minus_flag
      mov byte ptr ds:[di], 1   ;ustawienie wskaznika wypisania "minus" na wyjsciu
      jmp show_result

  multiplication:
    mov si, offset first_arg
    mov di, offset third_arg
    mov ah, 0
    mov al, byte ptr ds:[di]  ;pobranie pierwszej cyfry z pamieci
    mov ch, 0
    mov cl, byte ptr ds:[si]  ;pobranie drugiej cyfry z pamieci
    mul cx                    ;wynik mnozenia zapisany w rejestrze AX
    mov di, offset result
    mov byte ptr ds:[di], al  ;zapisanie wyniku mnozenia w pamieci

;//////////////////////////////////////////



;///////////////////////////////////////////////////
;WYPISYWANIE WYNIKU W TRYBIE TEKSTOWYM
;///////////////////////////////////////////////////

  show_result:
    mov dx, offset result_msg     ;wypisanie komunikatu o wyniku
    mov ah, 9
    int 21h

    mov si, offset minus_flag     ;sprawdzenie, czy wynik jest ujemny
    mov al, byte ptr ds:[si]
    cmp al, 0
    jz number_size_check    ;jesli nie trzeba wypisac "minus", przejdz do sprawdzenia czy wynik <= 20

  show_minus:               ;wypisanie slowa "minus"
    mov dx, offset minus
    mov ah, 9
    int 21h
    mov dx, offset space
    mov ah, 9
    int 21h

  number_size_check:        ;sprawdzenie, czy wynik <= 20
    mov si, offset result
    mov ah, 20
    mov al, byte ptr ds:[si]
    cmp ah, al
    jc more_than_twenty   ;sprawdza, czy wynik mozna wypisac jednym slowem (czyli czy nie jest wiekszy niz 20)

    print_single_number:  ;jesli wynik <= 20, znajdz odpowiednie slowo i je wypisz
      mov cl, 0           ;akutalnie wybrany wzorzec
      mov si, offset zero

      select_number_loop:
        cmp al, cl
        jz print_number  ;jesli znaleziono wlasciwy wzorzec, wypisz go
          move_to_next_number:  ;przejdz do kolejnego wzorca
            mov ah, '$'
            inc si
            cmp ds:[si-1], ah
            jnz move_to_next_number
            inc cl               ;rozpatrywany jest kolejny wzorzec
            jmp select_number_loop


  print_number: ;wypisanie pojedynczej liczby na ekran (od 0 do 20), lub cyfry jednosci (dla wynikow > 20)
    mov ax, si
    mov dx, ax
    mov ah, 9
    int 21h
    jmp exit

  more_than_twenty:   ;w AL zapisany jest wynik do wypisania
    mov ah, 0
    mov ch, 10
    div ch            ;dzielenie wyniku przez 10, w AL wynik dzielenia, w AH reszta
    mov si, offset twenty
    mov cl, 2
    select_number_loop_tens:
      cmp al, cl
      jz print_number_tens     ;jesli znaleziono odpowiednia wielokrotnosc dziesieciu, wypisz liczbe
        move_to_next_number_tens: ;przejscie do kolejnego wzoraca wielokrotnosci liczby dziesiec
          mov ah, '$'
          inc si
          cmp byte ptr ds:[si-1], ah
          jnz move_to_next_number_tens
          inc cl                  ;rozpatrywanie kolejnej wielokrotnosci dziesieciu
          jmp select_number_loop_tens

  print_number_tens:  ;wypisanie odpowiedniej wielokrotnosci dziesieciu
    mov ax, si
    mov dx, ax
    mov ah, 9
    int 21h
    mov dx, offset space
    mov ah, 9
    int 21h

    mov si, offset result
    mov al, byte ptr ds:[si]  ;pobranie z pamieci wyniku dzialania
    mov ah, 0
    mov ch, 10
    div ch                    ;dzielenie wyniku przez 10, cyfra jednosci (reszta dzielenia) zapisana w AH
    mov al, ah                ;przeniesienie cyfry jednosci do AL, w celu ewentualnego wypisania
    cmp al, 0
    jnz print_single_number
;///////////////////////////////////////////////////



;///////////////////////////////////////////////////
;ZAKONCZENIE PROGRAMU
;///////////////////////////////////////////////////

  exit:
    mov ax, 04c00h ;kod zakonczenia programu, systemowy error code = 0
    int 21h ;wywolanie przerwania systemu DOS, zakonczenie dzialania programu
;///////////////////////////////////////////////////



;///////////////////////////////////////////////////
;DODATKOWE FUNKCJE I OBSLUGA BLEDOW
;///////////////////////////////////////////////////


  new_line:         ;sluzy do wypisania nowej linii
    mov dx, offset new_ln_chars
    mov ah, 9
    int 21h
    ret

  invalid_first:    ;wypisanie komunikatu o blednym pierwszym argumencie
    mov dx, offset err_first
    mov ah, 9
    int 21h
    jmp exit

  invalid_second: ;wypisanie komunikatu o blednym drugim argumencie
    mov dx, offset err_second
    mov ah, 9
    int 21h
    jmp exit

  invalid_third:  ;wypisanie komunikatu o blednym trzecim argumencie
    mov dx, offset err_third
    mov ah, 9
    int 21h
    jmp exit

  invalid_input:  ;wypisanie komunikatu o blednym wejsciu
    mov dx, offset error_msg
    mov ah, 9
    int 21h
    jmp exit
;///////////////////////////////////////////////////
code1 ends


;//////////////////////////SEGMENT STOSU/////////////////////////////////////
stack1 segment STACK
     dw 200 dup(?) ;wypelnij stos 200 dowolnymi slowami
top1 dw ?          ;okresla wierzcholek stosu
stack1 ends

end start
