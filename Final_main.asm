; ============================================================
; main.asm
; cen 323 - coal semester project | math quiz master v3.0
; ------------------------------------------------------------
; only open this file in emu8086 - do not open member files.
; member files are pulled in via include and contain only
; procedures, no segment directives of their own.
;
; emu8086 is a single-pass assembler so a label must be seen
; before it can be called. the solution used here:
;   1. main proc appears first (required by "end main")
;   2. main immediately jumps to startup which is at the
;      very bottom of the file, after all includes
;   3. every procedure is therefore defined before startup
;      calls it - no forward reference errors
; ============================================================

.model small
.stack 200h

; ============================================================
; data segment
; ============================================================
.data

  ; core game state
  num1          dw  0
  num2          dw  0
  correct_ans   dw  0
  user_ans      dw  0
  score         db  0
  qnum          db  1
  operator      db  0          ; 0=add  1=sub  2=mul
  rand_seed     dw  7919

  ; streak and hints
  streak        db  0
  hints_left    db  2
  hint_used     db  0

  ; lives and high score
  lives         db  3
  high_score    db  0

  ; difficulty
  difficulty    db  1
  num_range     dw  10

  ; scratch byte used by print_num and show_question
  temp_digit    db  0

  ; per-category correct answer counters
  score_add     db  0
  score_sub     db  0
  score_mul     db  0

  ; ring buffer storing last 5 num1 values to avoid repeats
  q_history     dw  5 dup(0ffffh)
  hist_idx      db  0

  ; timer
  time_start    dw  0
  time_limit    dw  300        ; ~16 seconds at 18.2 ticks/sec
  time_up       db  0

  ; leaderboard - 3 scores and 3 x 8-char name slots
  lb_scores     db  0, 0, 0
  lb_names      db  '--------','--------','--------'

  ; player name - 8 chars + dollar terminator
  player_name   db  9 dup('$')
  name_len      db  0

  ; ---- messages ----
  msg_title1    db  '  ============================================',13,10,'$'
  msg_title2    db  '      *** MATH QUIZ MASTER  v3.0 ***',13,10,'$'
  msg_title3    db  '             coal semester project',13,10,'$'
  msg_title4    db  '  ============================================',13,10,'$'
  msg_sep       db  '  --------------------------------------------',13,10,'$'
  msg_name_p    db  13,10,'  enter your name (max 8 chars): $'
  msg_diff      db  13,10,'  select difficulty:',13,10,'$'
  msg_d1        db  '    [1] easy   (numbers 1-15,  +/-,   16s timer)',13,10,'$'
  msg_d2        db  '    [2] medium (numbers 1-20, +/-/x,  16s timer)',13,10,'$'
  msg_d3        db  '    [3] hard   (numbers 1-30, +/-/x,  16s timer)',13,10,'$'
  msg_dchoice   db  '  your choice: $'
  msg_dinvalid  db  '  invalid! please enter 1, 2 or 3.',13,10,'$'
  msg_rules1    db  13,10,'  rules:',13,10,'$'
  msg_rules2    db  '  > answer 10 questions correctly',13,10,'$'
  msg_rules3    db  '  > you have 3 lives  (wrong answer or timeout = -1)',13,10,'$'
  msg_rules4    db  '  > you have 2 hints  (press h during a question)',13,10,'$'
  msg_rules5    db  '  > streak bonus message at 3 and 5 correct in a row',13,10,'$'
  msg_rules6    db  '  > each question has a 16-second countdown timer',13,10,'$'
  msg_start     db  13,10,'  press any key to begin!',13,10,'$'
  msg_q         db  13,10,'  question $'
  msg_of        db  ' of 10',13,10,'$'
  msg_lives     db  '  lives  : $'
  msg_streak_d  db  '  streak : $'
  msg_hints_d   db  '  hints  : $'
  msg_timer_d   db  '  timer  : ~16 seconds  |  think fast!',13,10,'$'
  msg_prompt    db  '  your answer (or h for hint): $'
  msg_plus      db  ' + $'
  msg_minus     db  ' - $'
  msg_mul       db  ' x $'
  msg_eq        db  ' = ? $'
  msg_correct   db  '  >> correct!  +1 point',13,10,'$'
  msg_wrong     db  '  >> wrong! the answer was: $'
  msg_life_lost db  '  >> you lost a life!',13,10,'$'
  msg_no_lives  db  13,10,'  !! game over - no lives remaining !!',13,10,'$'
  msg_timeout   db  13,10,'  !! time is up! you lost a life!',13,10,'$'
  msg_skip_rep  db  '  regenerating to avoid repeat...',13,10,'$'
  msg_streak3   db  '  *** 3 in a row - great work! ***',13,10,'$'
  msg_streak5   db  '  *** 5 in a row - you are on fire! ***',13,10,'$'
  msg_hint_use  db  '  [hint] the answer is between $'
  msg_hint_and  db  ' and $'
  msg_hint_no   db  '  [hint] no hints remaining!',13,10,'$'
  msg_prog_l    db  '  progress: [$'
  msg_prog_done db  '#$'
  msg_prog_todo db  '.$'
  msg_prog_r    db  ']',13,10,'$'
  msg_result1   db  13,10,'  ============================================',13,10,'$'
  msg_result2   db  '               game over!',13,10,'$'
  msg_result3   db  '  ============================================',13,10,'$'
  msg_score_l   db  '  final score  : $'
  msg_score_r   db  ' / 10',13,10,'$'
  msg_hs_l      db  '  high score   : $'
  msg_hs_r      db  ' / 10',13,10,'$'
  msg_newhs     db  '  ** new high score! congratulations! **',13,10,'$'
  msg_grade_hdr db  '  grade        : $'
  msg_grade_a   db  'a  - excellent! outstanding work!',13,10,'$'
  msg_grade_b   db  'b  - good job! keep it up!',13,10,'$'
  msg_grade_c   db  'c  - not bad. keep practicing!',13,10,'$'
  msg_grade_f   db  'f  - do not give up. you will get there!',13,10,'$'
  msg_perfect   db  '  ** perfect score! absolute genius! **',13,10,'$'
  msg_cat_hdr   db  13,10,'  --- score breakdown by category ---',13,10,'$'
  msg_cat_add   db  '  addition    (+) : $'
  msg_cat_sub   db  '  subtraction (-) : $'
  msg_cat_mul   db  '  multiply    (x) : $'
  msg_cat_nl    db  ' correct',13,10,'$'
  msg_lb_hdr    db  13,10,'  === top 3 leaderboard ===',13,10,'$'
  msg_lb_1      db  '  #1  $'
  msg_lb_2      db  '  #2  $'
  msg_lb_3      db  '  #3  $'
  msg_lb_sep    db  '  -  $'
  msg_lb_pts    db  ' pts',13,10,'$'
  msg_lb_empty  db  '---',13,10,'$'
  msg_play_again db 13,10,'  play again? [y/n]: $'
  msg_bye1      db  13,10,'  ============================================',13,10,'$'
  msg_bye2      db  '         thank you for playing!',13,10,'$'
  msg_bye3      db  '  ============================================',13,10,'$'
  msg_bye4      db  13,10,'  we hope you had a great time with',13,10,'$'
  msg_bye5      db  '  math quiz master v3.0.',13,10,'$'
  msg_bye6      db  13,10,'  keep practicing and your math skills',13,10,'$'
  msg_bye7      db  '  will only get better!',13,10,'$'
  msg_bye8      db  13,10,'  this game was built with assembly language',13,10,'$'
  msg_bye9      db  '  for cen 323 - coal at bahria university.',13,10,'$'
  msg_bye10     db  13,10,'  goodbye and good luck!',13,10,'$'
  msg_bye11     db  '  ============================================',13,10,'$'
  newline       db  13,10,'$'
  space         db  ' $'


; ============================================================
; macros - defined before includes so member files can use them
; ============================================================

print_str macro msg
    lea  dx, msg
    mov  ah, 09h
    int  21h
endm

print_nl macro
    lea  dx, newline
    mov  ah, 09h
    int  21h
endm

read_key macro
    mov  ah, 01h
    int  21h
endm

clear_screen macro
    mov  ax, 0003h
    int  10h
endm

get_timer macro
    mov  ah, 00h
    int  1ah
endm


; ============================================================
; code segment
; ============================================================

; ============================================================
; code segment
; ============================================================
.code

; ============================================================
; main proc - required first by "end main"
; sets ds and jumps to startup at the bottom of this file
; ============================================================
main proc
  mov  ax, @data
  mov  ds, ax
  jmp  startup
main endp

; ============================================================
; member 1 procedures
; ============================================================
; ============================================================
; member1\member1.asm
; owner: member 1
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


; ----------------------------------------------------------
; check_history
; checks if num1 was used in the last 5 questions
; returns: zero flag set (je) = it is a repeat
;          zero flag clear    = safe to use
; ----------------------------------------------------------
check_history proc

  push cx
  push si

  mov  si, 0
  mov  cx, 5
  mov  ax, num1

ch_loop:
  cmp  ax, q_history[si]
  je   ch_found
  add  si, 2                 ; each slot is a word (2 bytes)
  loop ch_loop

  ; not found - clear zero flag so caller knows it is safe
  or   ax, ax
  pop  si
  pop  cx
  ret

ch_found:
  ; set zero flag to signal a repeat to the caller
  xor  ax, ax
  cmp  ax, 0
  pop  si
  pop  cx
  ret

check_history endp


; ----------------------------------------------------------
; update_history
; saves the current num1 into the ring buffer
; ----------------------------------------------------------
update_history proc

  push ax
  push si

  ; the ring buffer stores words (2 bytes each), so we multiply
  ; the index by 2 to get the correct byte offset into q_history
  mov  al, hist_idx
  mov  ah, 0
  shl  ax, 1
  mov  si, ax

  mov  ax, num1
  mov  q_history[si], ax

  ; advance the index and wrap back to 0 after slot 4
  mov  al, hist_idx
  inc  al
  cmp  al, 5
  jl   uh_save
  mov  al, 0
uh_save:
  mov  hist_idx, al

  pop  si
  pop  ax
  ret

update_history endp


; ----------------------------------------------------------
; gen_question
; picks an operator, generates two numbers, calculates the
; correct answer, and checks history to avoid repeats
; ----------------------------------------------------------
gen_question proc

  mov  hint_used, 0

  ; pick how many operators to choose from based on difficulty
  ; easy only gets + and -, medium and hard also get multiply
  mov  bl, difficulty
  cmp  bl, 1
  jne  gq_not_easy
  mov  bx, 2
  jmp  gq_get_op
gq_not_easy:
  mov  bx, 3

gq_get_op:
  call get_random
  dec  ax                    ; make it 0-based (0=add, 1=sub, 2=mul)
  mov  operator, al

gq_try:
  mov  bx, num_range
  call get_random
  mov  num1, ax
  call check_history
  je   gq_repeat             ; this num1 was used recently, try again

  mov  bx, num_range
  call get_random
  mov  num2, ax

  ; for subtraction we swap if num1 < num2 so the answer stays positive
  cmp  operator, 1
  jne  gq_calc
  mov  ax, num1
  cmp  ax, num2
  jge  gq_calc
  mov  cx, num2
  mov  num2, ax
  mov  num1, cx
  jmp  gq_calc

gq_repeat:
  print_str msg_skip_rep
  jmp  gq_try

gq_calc:
  mov  ax, num1
  cmp  operator, 0
  je   gq_add
  cmp  operator, 1
  je   gq_sub
  mul  num2
  jmp  gq_save
gq_add:
  add  ax, num2
  jmp  gq_save
gq_sub:
  sub  ax, num2
gq_save:
  mov  correct_ans, ax
  call update_history
  ret

gen_question endp


; ----------------------------------------------------------
; get_player_name
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


; ----------------------------------------------------------
; select_difficulty
; shows the menu and sets difficulty and num_range
; ----------------------------------------------------------
select_difficulty proc

  print_str msg_diff
  print_str msg_d1
  print_str msg_d2
  print_str msg_d3
  print_str msg_dchoice

sd_read:
  read_key
  cmp  al, '1'
  je   sd_easy
  cmp  al, '2'
  je   sd_med
  cmp  al, '3'
  je   sd_hard
  print_nl
  print_str msg_dinvalid
  print_str msg_dchoice
  jmp  sd_read

sd_easy:
  mov  difficulty, 1
  mov  num_range, 15
  jmp  sd_done
sd_med:
  mov  difficulty, 2
  mov  num_range, 20
  jmp  sd_done
sd_hard:
  mov  difficulty, 3
  mov  num_range, 30
sd_done:
  print_nl
  ret

select_difficulty endp


; ============================================================
; member 2 procedures
; ============================================================
; ============================================================
; member2\member2.asm
; owner: member 2
; procedures: give_hint, read_num_timed, check_answer,
;             update_leaderboard, lb_copy_name,
;             lb_shift_names_12, lb_shift_names_01,
;             lb_shift_names_02
; ============================================================


; ----------------------------------------------------------
; give_hint
; shows the player a range that contains the correct answer
; ----------------------------------------------------------
give_hint proc

  cmp  hints_left, 0
  je   hint_none

  dec  hints_left
  mov  hint_used, 1
  print_nl
  print_str msg_hint_use

  ; lower bound is correct_ans minus 5, but never below 0
  mov  ax, correct_ans
  cmp  ax, 5
  jge  hint_sub
  mov  ax, 0
  jmp  hint_print_lo
hint_sub:
  sub  ax, 5
hint_print_lo:
  call print_num

  print_str msg_hint_and
  mov  ax, correct_ans
  add  ax, 5
  call print_num
  print_nl
  jmp  hint_done

hint_none:
  print_str msg_hint_no
hint_done:
  ret

give_hint endp


; ----------------------------------------------------------
; read_num_timed
; reads the player's answer while watching the clock
;
; instead of blocking on a keypress (int 21h ah=01h) we poll
; the keyboard status (int 21h ah=0bh) in a tight loop.
; between each poll we also check how many bios ticks have
; passed since the question appeared. if the elapsed count
; reaches time_limit (~300 ticks = ~16 seconds) we bail out
; and set time_up=1 so check_answer knows what happened.
;
; digits are accumulated in bx using the formula:
;   bx = bx * 10 + new_digit
; backspace reverses this with integer division bx / 10.
; we read with ah=08h (no echo) and echo digits ourselves
; so we can silently ignore non-digit keys.
; ----------------------------------------------------------
read_num_timed proc

  mov  time_up, 0
  mov  bx, 0

  ; snapshot the clock right before we start waiting
  get_timer
  mov  time_start, dx        ; dx = low word, enough for a 16s window

rnt_loop:
  ; check if a key is waiting without blocking
  mov  ah, 0bh
  int  21h
  cmp  al, 0ffh
  je   rnt_key               ; key is ready

  ; no key yet - check elapsed ticks
  get_timer
  mov  ax, dx
  sub  ax, time_start        ; elapsed = now - start
  cmp  ax, time_limit
  jge  rnt_timeout
  jmp  rnt_loop

rnt_timeout:
  mov  time_up, 1
  mov  user_ans, 0ffffh      ; sentinel so check_answer knows it timed out
  print_nl
  print_str msg_timeout
  ret

rnt_key:
  mov  ah, 08h               ; read without auto-echo so we control output
  int  21h

  cmp  al, 13                ; enter = submit
  je   rnt_done
  cmp  al, 'H'
  je   rnt_hint
  cmp  al, 'h'
  je   rnt_hint
  jmp  rnt_not_hint

rnt_hint:
  push bx
  call give_hint
  pop  bx
  print_str msg_prompt
  ; reset the clock so hint time does not count against the player
  get_timer
  mov  time_start, dx
  jmp  rnt_loop

rnt_not_hint:
  cmp  al, 8                 ; backspace
  jne  rnt_not_bs
  cmp  bx, 0
  je   rnt_loop
  ; strip the last digit by dividing bx by 10
  mov  ax, bx
  mov  cx, 10
  mov  dx, 0
  div  cx
  mov  bx, ax
  mov  ah, 02h
  mov  dl, 8
  int  21h
  mov  dl, ' '
  int  21h
  mov  dl, 8
  int  21h
  jmp  rnt_loop

rnt_not_bs:
  cmp  al, '0'
  jl   rnt_loop
  cmp  al, '9'
  jg   rnt_loop
  ; echo the digit ourselves since we read with ah=08h
  mov  ah, 02h
  mov  dl, al
  int  21h
  ; shift bx left one decimal place and add the new digit
  sub  al, '0'
  mov  temp_digit, al
  mov  ax, bx
  mov  cx, 10
  mul  cx
  mov  bx, ax
  mov  al, temp_digit
  mov  ah, 0
  add  bx, ax
  jmp  rnt_loop

rnt_done:
  mov  ax, bx
  mov  user_ans, ax
  ret

read_num_timed endp


; ----------------------------------------------------------
; check_answer
; compares the player's answer to the correct one and updates
; score, lives, streak and per-category counters accordingly
; ----------------------------------------------------------
check_answer proc

  ; if the timer ran out we skip the comparison and go straight
  ; to the wrong-answer path since the player did not answer
  cmp  time_up, 1
  je   ca_wrong_common

  print_nl
  mov  ax, user_ans
  cmp  ax, correct_ans
  je   ca_right

ca_wrong_common:
  mov  streak, 0
  dec  lives
  print_str msg_wrong
  mov  ax, correct_ans
  call print_num
  print_nl
  print_str msg_life_lost
  cmp  lives, 0
  jg   ca_done
  print_str msg_no_lives
  call show_result           ; show end screen; al=1 means replay
  cmp  al, 1
  je   ca_done               ; caller will loop back via game_loop
  jmp  exit_prog             ; al=0 means quit

ca_right:
  inc  score
  inc  streak

  ; increment the counter for whichever operator was used
  cmp  operator, 0
  jne  ca_check_sub
  inc  score_add
  jmp  ca_cat_done
ca_check_sub:
  cmp  operator, 1
  jne  ca_inc_mul
  inc  score_sub
  jmp  ca_cat_done
ca_inc_mul:
  inc  score_mul
ca_cat_done:

  print_str msg_correct
  mov  al, streak
  cmp  al, 5
  je   ca_streak5
  cmp  al, 3
  je   ca_streak3
  jmp  ca_done
ca_streak5:
  print_str msg_streak5
  jmp  ca_done
ca_streak3:
  print_str msg_streak3
ca_done:
  ret

check_answer endp


; ----------------------------------------------------------
; update_leaderboard
; inserts the current score into the top-3 sorted array.
; this is a 3-element descending insertion sort.
; we compare against rank 0 first (the highest), then rank 1,
; then rank 2. when we find the right position we shift the
; lower entries down to make room and copy the player name
; into the matching name slot.
; ----------------------------------------------------------
update_leaderboard proc

  push ax
  push bx
  push cx
  push si
  push di

  mov  al, score

  cmp  al, lb_scores[0]
  jle  ul_check1

  ; new score is the best - push 0 down to 1, 1 down to 2
  mov  bl, lb_scores[1]
  mov  lb_scores[2], bl
  mov  bl, lb_scores[0]
  mov  lb_scores[1], bl
  mov  lb_scores[0], al
  call lb_shift_names_02
  call lb_shift_names_01
  mov  di, 0
  call lb_copy_name
  jmp  ul_done

ul_check1:
  cmp  al, lb_scores[1]
  jle  ul_check2

  ; second best - push 1 down to 2
  mov  bl, lb_scores[1]
  mov  lb_scores[2], bl
  mov  lb_scores[1], al
  call lb_shift_names_12
  mov  di, 8
  call lb_copy_name
  jmp  ul_done

ul_check2:
  cmp  al, lb_scores[2]
  jle  ul_done

  ; third best - just replace slot 2
  mov  lb_scores[2], al
  mov  di, 16
  call lb_copy_name

ul_done:
  pop  di
  pop  si
  pop  cx
  pop  bx
  pop  ax
  ret

update_leaderboard endp


; ----------------------------------------------------------
; lb_copy_name
; copies player_name into lb_names at byte offset di.
; always writes exactly 8 bytes, padding with '-' if the
; name is shorter than 8 characters.
; ----------------------------------------------------------
lb_copy_name proc

  push cx
  push si
  mov  si, 0
  mov  cx, 8

lcn_loop:
  mov  al, player_name[si]
  cmp  al, '$'
  je   lcn_pad
  mov  lb_names[di], al
  inc  si
  inc  di
  loop lcn_loop
  jmp  lcn_done

lcn_pad:
  mov  lb_names[di], '-'
  inc  di
  loop lcn_pad

lcn_done:
  pop  si
  pop  cx
  ret

lb_copy_name endp


; ----------------------------------------------------------
; lb_shift_names_12  - copies name slot 1 into slot 2
; lb_shift_names_01  - copies name slot 0 into slot 1
; lb_shift_names_02  - wrapper that calls lb_shift_names_12
;
; each name slot is 8 bytes inside lb_names.
; slot 0 starts at offset 0, slot 1 at offset 8, slot 2 at 16.
; ----------------------------------------------------------
lb_shift_names_12 proc
  push cx
  push si
  mov  si, 0
  mov  cx, 8
lb12_loop:
  mov  al, lb_names[si+8]
  mov  lb_names[si+16], al
  inc  si
  loop lb12_loop
  pop  si
  pop  cx
  ret
lb_shift_names_12 endp

lb_shift_names_01 proc
  push cx
  push si
  mov  si, 0
  mov  cx, 8
lb01_loop:
  mov  al, lb_names[si]
  mov  lb_names[si+8], al
  inc  si
  loop lb01_loop
  pop  si
  pop  cx
  ret
lb_shift_names_01 endp

lb_shift_names_02 proc
  call lb_shift_names_12
  ret
lb_shift_names_02 endp


; ============================================================
; member 3 procedures  (show_result is inside here)
; ============================================================
; ============================================================
; member3\member3.asm
; owner: member 3
; procedures: print_num, show_title, show_rules, show_status,
;             show_progress, show_question, show_category_scores,
;             show_leaderboard, print_lb_name, show_result
; ============================================================


; ----------------------------------------------------------
; print_num
; prints the value in ax as a decimal number on screen
;
; the trick here is that division gives us digits in reverse
; order (least significant first). we push each remainder onto
; the stack as we divide, then pop them off in order to print
; them correctly from left to right.
; ----------------------------------------------------------
print_num proc

  mov  cx, 0
  mov  bx, 10
  cmp  ax, 0
  jne  pn_div
  mov  ah, 02h
  mov  dl, '0'
  int  21h
  ret

pn_div:
  mov  dx, 0
  div  bx                    ; remainder in dx is the next digit (rightmost)
  push dx                    ; save it - we will print in reverse order
  inc  cx
  cmp  ax, 0
  jnz  pn_div

pn_print:
  pop  dx
  add  dl, '0'               ; convert 0-9 to ascii '0'-'9'
  mov  ah, 02h
  int  21h
  loop pn_print
  ret

print_num endp


; ----------------------------------------------------------
; show_title
; ----------------------------------------------------------
show_title proc
  print_str msg_title1
  print_str msg_title2
  print_str msg_title3
  print_str msg_title4
  ret
show_title endp


; ----------------------------------------------------------
; show_rules
; ----------------------------------------------------------
show_rules proc
  print_str msg_sep
  print_str msg_rules1
  print_str msg_rules2
  print_str msg_rules3
  print_str msg_rules4
  print_str msg_rules5
  print_str msg_rules6
  print_str msg_sep
  print_str msg_start
  ret
show_rules endp


; ----------------------------------------------------------
; show_status
; displays lives, streak, hints and progress before each question
; ----------------------------------------------------------
show_status proc
  print_str msg_sep

  print_str msg_lives
  mov  al, lives
  mov  ah, 0
  call print_num
  print_nl

  print_str msg_streak_d
  mov  al, streak
  mov  ah, 0
  call print_num
  print_nl

  print_str msg_hints_d
  mov  al, hints_left
  mov  ah, 0
  call print_num
  print_nl

  print_str msg_timer_d
  call show_progress
  ret
show_status endp


; ----------------------------------------------------------
; show_progress
; draws a progress bar like [####......] using the loop
; instruction. jcxz skips a loop block if cx is already zero
; which avoids printing zero hashes or dots.
; ----------------------------------------------------------
show_progress proc

  push cx
  push bx

  print_str msg_prog_l

  mov  bl, qnum
  dec  bl                    ; bl = number of completed questions

  ; print a hash for each completed question
  mov  cl, bl
  mov  ch, 0
  jcxz prog_dots
prog_hash_loop:
  print_str msg_prog_done
  loop prog_hash_loop

prog_dots:
  ; print a dot for each remaining question
  mov  cl, 10
  sub  cl, bl
  mov  ch, 0
  jcxz prog_close
prog_dot_loop:
  print_str msg_prog_todo
  loop prog_dot_loop

prog_close:
  print_str msg_prog_r

  pop  bx
  pop  cx
  ret

show_progress endp


; ----------------------------------------------------------
; show_question
; prints the question number and the equation.
; dividing qnum by 10 gives us the tens and units digits
; separately so we can print two-digit numbers like "10".
; temp_digit saves the units digit before int 21h overwrites ah.
; ----------------------------------------------------------
show_question proc

  print_str msg_q

  mov  al, qnum
  mov  ah, 0
  mov  bl, 10
  div  bl                    ; al = tens digit,  ah = units digit
  mov  temp_digit, ah        ; save units because int 21h will clobber ah
  cmp  al, 0
  je   sq_skip_tens
  add  al, '0'
  mov  ah, 02h
  mov  dl, al
  int  21h
sq_skip_tens:
  mov  al, temp_digit
  add  al, '0'
  mov  ah, 02h
  mov  dl, al
  int  21h

  print_str msg_of

  mov  ax, num1
  call print_num

  cmp  operator, 0
  je   sq_plus
  cmp  operator, 1
  je   sq_minus
  print_str msg_mul
  jmp  sq_op_done
sq_plus:
  print_str msg_plus
  jmp  sq_op_done
sq_minus:
  print_str msg_minus
sq_op_done:

  mov  ax, num2
  call print_num
  print_str msg_eq
  print_str msg_prompt
  ret

show_question endp


; ----------------------------------------------------------
; show_category_scores
; prints how many questions of each type the player got right
; ----------------------------------------------------------
show_category_scores proc

  print_str msg_cat_hdr

  print_str msg_cat_add
  mov  al, score_add
  mov  ah, 0
  call print_num
  print_str msg_cat_nl

  print_str msg_cat_sub
  mov  al, score_sub
  mov  ah, 0
  call print_num
  print_str msg_cat_nl

  print_str msg_cat_mul
  mov  al, score_mul
  mov  ah, 0
  call print_num
  print_str msg_cat_nl

  ret

show_category_scores endp


; ----------------------------------------------------------
; show_leaderboard
; prints the top 3 scores with names.
; each name slot in lb_names is 8 bytes wide.
; si is set to the byte offset of the slot before calling
; print_lb_name (slot 0=0, slot 1=8, slot 2=16).
; a score of 0 means that rank has never been filled.
; ----------------------------------------------------------
show_leaderboard proc

  push cx
  push si
  print_str msg_lb_hdr

  print_str msg_lb_1
  cmp  lb_scores[0], 0
  je   slb_empty1
  mov  si, 0
  call print_lb_name
  print_str msg_lb_sep
  mov  al, lb_scores[0]
  mov  ah, 0
  call print_num
  print_str msg_lb_pts
  jmp  slb_2
slb_empty1:
  print_str msg_lb_empty

slb_2:
  print_str msg_lb_2
  cmp  lb_scores[1], 0
  je   slb_empty2
  mov  si, 8
  call print_lb_name
  print_str msg_lb_sep
  mov  al, lb_scores[1]
  mov  ah, 0
  call print_num
  print_str msg_lb_pts
  jmp  slb_3
slb_empty2:
  print_str msg_lb_empty

slb_3:
  print_str msg_lb_3
  cmp  lb_scores[2], 0
  je   slb_empty3
  mov  si, 16
  call print_lb_name
  print_str msg_lb_sep
  mov  al, lb_scores[2]
  mov  ah, 0
  call print_num
  print_str msg_lb_pts
  jmp  slb_done
slb_empty3:
  print_str msg_lb_empty

slb_done:
  pop  si
  pop  cx
  ret

show_leaderboard endp


; ----------------------------------------------------------
; print_lb_name
; prints up to 8 characters from lb_names starting at si.
; stops early when it hits a '-' which is the padding char.
; ----------------------------------------------------------
print_lb_name proc

  push cx
  push si
  mov  cx, 8
pln_loop:
  mov  al, lb_names[si]
  cmp  al, '-'
  je   pln_stop
  mov  ah, 02h
  mov  dl, al
  int  21h
  inc  si
  loop pln_loop
pln_stop:
  pop  si
  pop  cx
  ret

print_lb_name endp


; ----------------------------------------------------------
; show_result
; full end-of-game screen: score, grade, breakdown, leaderboard
; and play-again prompt.
; returns al=1 if player wants to replay, al=0 to quit.
; ----------------------------------------------------------
show_result proc

  print_str msg_result1
  print_str msg_result2
  print_str msg_result3

  print_str msg_score_l
  mov  al, score
  mov  ah, 0
  call print_num
  print_str msg_score_r

  ; check if this is a new high score
  mov  al, score
  cmp  al, high_score
  jle  sr_show_hs
  mov  high_score, al
  print_str msg_newhs

sr_show_hs:
  print_str msg_hs_l
  mov  al, high_score
  mov  ah, 0
  call print_num
  print_str msg_hs_r

  mov  al, score
  cmp  al, 10
  jne  sr_grade
  print_str msg_perfect

sr_grade:
  print_str msg_grade_hdr
  mov  al, score
  cmp  al, 9
  jge  sr_a
  cmp  al, 7
  jge  sr_b
  cmp  al, 5
  jge  sr_c
  jmp  sr_f
sr_a:
  print_str msg_grade_a
  jmp  sr_cat
sr_b:
  print_str msg_grade_b
  jmp  sr_cat
sr_c:
  print_str msg_grade_c
  jmp  sr_cat
sr_f:
  print_str msg_grade_f

sr_cat:
  call show_category_scores
  call update_leaderboard
  call show_leaderboard

  print_str msg_play_again
  read_key
  cmp  al, 'Y'
  je   sr_restart
  cmp  al, 'y'
  je   sr_restart
  ; player chose not to replay - return 0 in al so caller exits
  mov  al, 0
  ret

sr_restart:
  ; reset everything so the new game starts completely fresh
  mov  score,      0
  mov  qnum,       1
  mov  streak,     0
  mov  hints_left, 2
  mov  lives,      3
  mov  score_add,  0
  mov  score_sub,  0
  mov  score_mul,  0
  mov  hist_idx,   0
  mov  q_history[0], 0ffffh
  mov  q_history[2], 0ffffh
  mov  q_history[4], 0ffffh
  mov  q_history[6], 0ffffh
  mov  q_history[8], 0ffffh

  clear_screen
  call show_title
  call get_player_name
  call select_difficulty
  call show_rules
  read_key
  ; return 1 in al so caller loops back to game_loop
  mov  al, 1
  ret

show_result endp


; ============================================================
; show_goodbye - farewell screen
; ============================================================
show_goodbye proc
  clear_screen
  print_str msg_bye1
  print_str msg_bye2
  print_str msg_bye3
  print_str msg_bye4
  print_str msg_bye5
  print_str msg_bye6
  print_str msg_bye7
  print_str msg_bye8
  print_str msg_bye9
  print_str msg_bye10
  print_str msg_bye11
  print_nl
  read_key
  ret
show_goodbye endp

; ============================================================
; game_loop - placed after show_result so the call resolves
; ============================================================
game_loop:
  mov  al, qnum
  cmp  al, 11
  jl   gl_continue
  call show_result          ; returns al=1 replay, al=0 quit
  cmp  al, 1
  je   game_loop
  jmp  exit_prog

gl_continue:
  call gen_question
  call show_status
  call show_question
  call read_num_timed
  call check_answer
  inc  qnum
  jmp  game_loop

; ============================================================
; exit_prog
; ============================================================
exit_prog:
  call show_goodbye
  mov  ah, 4ch
  int  21h

; ============================================================
; startup - real entry point, every procedure above is defined
; ============================================================
startup:
  clear_screen
  get_timer
  mov  rand_seed, dx

  call show_title
  call get_player_name
  call select_difficulty
  call show_rules
  read_key

  mov  score,      0
  mov  qnum,       1
  mov  streak,     0
  mov  hints_left, 2
  mov  lives,      3
  mov  score_add,  0
  mov  score_sub,  0
  mov  score_mul,  0
  mov  hist_idx,   0

  jmp  game_loop

end main
