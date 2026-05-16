; ============================================================
; data.asm
; cen 323 - coal semester project | math quiz master v3.0
; ------------------------------------------------------------
; this file contains only the .data segment declarations.
; include this file in main.asm inside the .data segment.
; do NOT add .model, .stack, or .code directives here.
; ============================================================

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
