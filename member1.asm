; ============================================================
; member1\member1.asm
; owner: Waleed Ahmed
; procedures: get_random, check_history, update_history,
;             gen_question, get_player_name, select_difficulty
; ============================================================


; ----------------------------------------------------------
; get_random
; returns a number between 1 and bx (inclusive)
; uses a 16-bit linear feedback shift register (lfsr)
; ----------------------------------------------------------
get_random proc

  mov  ax, rand_seed

  ; lfsr works by xoring specific bits together to produce
  ; a feedback bit, then shifting the whole register right.
  ; we tap bits 15, 13, 12 and 10 - this combination gives
  ; the longest possible sequence before it repeats (65535).
  mov  dx, ax
  and  dx, 8000h             ; isolate bit 15

  mov  cx, ax
  and  cx, 2000h             ; bit 13
  shl  cx, 2
  xor  dx, cx

  mov  cx, ax
  and  cx, 1000h             ; bit 12
  shl  cx, 3
  xor  dx, cx

  mov  cx, ax
  and  cx, 0400h             ; bit 10
  shl  cx, 5
  xor  dx, cx

  shr  ax, 1                 ; shift the register right by one
  or   ax, dx                ; put the feedback bit into the top
  mov  rand_seed, ax

  ; map the 16-bit result into the range 1..bx using remainder
  mov  dx, 0
  div  bx                    ; dx = ax mod bx  (gives 0 to bx-1)
  mov  ax, dx
  inc  ax                    ; shift up to 1-based
  ret

get_random endp

; ============================================================
; new additoin: check_history
; purpose:
;   checks if num1 was used in the last 5 questions
;
; input:
;   num1 must already have a value
;
; output:
;   zf = 1 → num1 was found (repeat)
;   zf = 0 → num1 not found (safe to use)
;
; idea:
;   we go through the 5-word array one by one
;   si moves by 2 each time since each value is a word
; ============================================================
check_history proc
  push cx              ; save cx (used by loop)
  push si              ; save si (we use it for indexing)

  mov  si, 0           ; start from first element
  mov  cx, 5           ; total 5 entries to check
  mov  ax, num1        ; value we are searching for

ch_loop:
  cmp  ax, q_history[si]   ; compare with current history value
  je   ch_found            ; if equal → found it

  add  si, 2               ; move to next word (2 bytes)
  loop ch_loop             ; repeat until cx = 0

  ; if we reach here, num1 was not found
  ; we make sure zf = 0
  or   ax, ax              ; sets flags based on ax (non-zero → zf = 0)

  pop  si
  pop  cx
  ret

ch_found:
  ; num1 exists in history
  ; force zf = 1
  xor  ax, ax              ; ax = 0
  cmp  ax, 0               ; 0 == 0 → zf = 1

  pop  si
  pop  cx
  ret
check_history endp


; ============================================================
; new addition: update_history   
; purpose:
;   saves current num1 into q_history array
;
; when used:
;   after a question is finalized
;
; idea:
;   acts like a circular buffer of size 5
;   index goes 0 → 1 → 2 → 3 → 4 → back to 0
; ============================================================
update_history proc
  push ax
  push si

  ; convert index to byte offset (word = 2 bytes)
  mov  al, hist_idx
  mov  ah, 0
  shl  ax, 1              ; ax = hist_idx * 2
  mov  si, ax

  ; store num1 in the correct slot
  mov  ax, num1
  mov  q_history[si], ax

  ; move index forward
  mov  al, hist_idx
  inc  al
  cmp  al, 5              ; if it reaches 5, reset to 0
  jl   uh_save

  mov  al, 0

uh_save:
  mov  hist_idx, al

  pop  si
  pop  ax
  ret
update_history endp


; ============================================================
; gen_question
; purpose:
;   generates a math question based on difficulty
;   also avoids repeating recent num1 values using history
;
; idea:
;   - pick operator depending on difficulty
;   - keep generating num1 until it's not in history
;   - generate num2 normally
;   - calculate correct answer
;   - save num1 into history so it won't repeat
; ============================================================
gen_question proc
  mov  hint_used, 0        ; reset hint flag for new question

  ; decide operator based on difficulty
  mov  bl, difficulty
  cmp  bl, 1
  jne  gq_not_easy

  mov  bx, 2               ; easy → only add and subtract
  jmp  gq_get_op

gq_not_easy:
  mov  bx, 3               ; medium/hard → add, sub, multiply

gq_get_op:
  call get_random
  dec  ax                  ; convert to 0-based (0,1,2)
  mov  operator, al

gq_try:
  ; ------------------- new part -------------------
  ; generate num1 and check if it was used recently
  ; this prevents repeating the same first number
  mov  bx, num_range
  call get_random
  mov  num1, ax

  call check_history       ; checks last 5 stored values
  je   gq_repeat           ; if found (zf=1), it's a repeat → retry
  ; ------------------------------------------------

  ; num1 is fine, now generate num2 (same as old logic)
  mov  bx, num_range
  call get_random
  mov  num2, ax

  ; if subtraction, make sure result is not negative
  cmp  operator, 1
  jne  gq_calc

  mov  ax, num1
  cmp  ax, num2
  jge  gq_calc

  ; swap so num1 >= num2
  mov  cx, num2
  mov  num2, ax
  mov  num1, cx
  jmp  gq_calc

gq_repeat:
  ; ------------------- new part -------------------
  ; this runs only when num1 was already used recently
  ; show a small message so user knows why it changed
  print_str msg_skip_rep

  ; try again → go back and generate a new num1
  ; operator stays same, only num1 is retried
  jmp  gq_try
  ; ------------------------------------------------

gq_calc:
  ; calculate correct answer (same as before)
  mov  ax, num1

  cmp  operator, 0
  je   gq_add

  cmp  operator, 1
  je   gq_sub

  ; multiplication
  mul  num2
  jmp  gq_save

gq_add:
  add  ax, num2
  jmp  gq_save

gq_sub:
  sub  ax, num2

gq_save:
  mov  correct_ans, ax     ; store final answer

  ; ------------------- new part -------------------
  ; save num1 into history array
  ; so next questions can avoid repeating it
  call update_history
  ; ------------------------------------------------

  ret
gen_question endp

; ----------------------------------------------------------
; New feature: get_player_name
; reads up to 8 characters from the keyboard
; handles backspace and enforces the length limit
; ----------------------------------------------------------
get_player_name proc

  print_str msg_name_p
  mov  si, 0
  mov  name_len, 0

gpn_loop:
  read_key
  cmp  al, 13                ; enter key ends input
  je   gpn_done
  cmp  al, 8                 ; backspace
  je   gpn_bs
  cmp  si, 8                 ; ignore input once 8 chars are stored
  jge  gpn_loop
  mov  player_name[si], al
  inc  si
  inc  name_len
  jmp  gpn_loop

gpn_bs:
  cmp  si, 0
  je   gpn_loop
  dec  si
  dec  name_len
  mov  player_name[si], '$'
  ; erase the character on screen: backspace, space, backspace
  mov  ah, 02h
  mov  dl, 8
  int  21h
  mov  dl, ' '
  int  21h
  mov  dl, 8
  int  21h
  jmp  gpn_loop

gpn_done:
  mov  player_name[si], '$'  ; dollar sign terminates the string for int 21h
  print_nl
  ret

get_player_name endp

select_difficulty proc
  ; print difficulty options on screen
  lea  dx, msg_diff
  mov  ah, 09h
  int  21h

  lea  dx, msg_d1
  mov  ah, 09h
  int  21h

  lea  dx, msg_d2
  mov  ah, 09h
  int  21h

  lea  dx, msg_d3
  mov  ah, 09h
  int  21h

  lea  dx, msg_dchoice
  mov  ah, 09h
  int  21h

sd_read:
  ; read single key input from user
  mov  ah, 01h
  int  21h

  ; check what user entered
  cmp  al, '1'
  je   sd_easy

  cmp  al, '2'
  je   sd_med

  cmp  al, '3'
  je   sd_hard

  ; if input is wrong, show message and ask again
  lea  dx, newline
  mov  ah, 09h
  int  21h

  lea  dx, msg_dinvalid
  mov  ah, 09h
  int  21h

  lea  dx, msg_dchoice
  mov  ah, 09h
  int  21h

  jmp  sd_read

sd_easy:
  mov  difficulty, 1
  mov  num_range, 15   ; small numbers
  jmp  sd_done

sd_med:
  mov  difficulty, 2
  mov  num_range, 20  ; medium numbers
  jmp  sd_done

sd_hard:
  mov  difficulty, 3
  mov  num_range, 30   ; larger numbers

sd_done:
  ; just move to next line after selection
  lea  dx, newline
  mov  ah, 09h
  int  21h
  ret

select_difficulty endp
