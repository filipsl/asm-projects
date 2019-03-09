;Project 01 - Verbal Calculator
;Created by Filip SLazyk
;AGH UST 2019


;segment danych
data1 segment

hello_msg  db "Enter a description of a calculation: $" ;wiadomosc startowa
result_msg db "The result is: $"                        ;wiadomosc z wynikiem
error_msg  db "Error - invalid input!",10,13,'$'        ;wiadmosc bledu

;definicja nazw liczb
zero      db "zero"
one       db "one"
two       db "two"
three     db "three"
four      db "four"
five      db "five"
six       db "six"
seven     db "seven"
eight     db "eight"
nine      db "nine"
ten       db "ten"
eleven    db "eleven"
twelve    db "twelve"
thirteen  db "thirteen"
fourteen  db "fourteen"
fifteen   db "nineteen"
sixteen   db "sixteen"
seventeen db "seventeen"
eighteen  db "eighteen"
nineteen  db "nineteen"

twenty    db "twenty"
thirty    db "thirty"
forty     db "forty"
fifty     db "fifty"
sixty     db "sixty"
seventy   db "seventy"
eighty    db "eighty"

;definicja nazw operacji
plus  db "plus"
minus db "minus"
tim   db "times"

data1 ends


;segment programu
code1 segment

start:
  mov ax,seg top1
  mov ss,ax
  mov sp,offset top1

code1 ends


;segment stosu
stack1 segment STACK
    dw 200 dup(?) ;wypelnij stos 200 dowolnymi slowami
top1 dw ?          ;okresla wierzcholek stostu
stack1 ends

end start
