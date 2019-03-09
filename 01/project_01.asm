;Project 01 - verbal calculator
;Created by Filip SLazyk
;AGH UST 2019


;segment danych
data1 segment

hello_msg db "Enter a description of a calculation: $"
result_ms db "The result is: $"

data1 ends


;segment programu
code1 segment

start:

code1 ends


;inicjalizacja stosu
stack1 segment STACK
    dw 200 dup(?) ;wypelnij stos 200 dowolnymi slowami
top dw ?          ;okresla wierzcholek stostu
stack1 ends
