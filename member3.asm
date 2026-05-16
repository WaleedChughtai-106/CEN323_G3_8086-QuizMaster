; ############################################################
; ===                   MEMBER 3                           ===
; ### PRINT_NUM | SHOW_TITLE | SHOW_RULES | SHOW_STATUS    ###
; ### SHOW_PROGRESS | SHOW_QUESTION | SHOW_RESULT          ###
; ############################################################

; ============================================================
; PRINT_NUM  -  Print AX as unsigned decimal
; ============================================================
PRINT_NUM PROC
  MOV  CX, 0
  MOV  BX, 10
  CMP  AX, 0
  JNE  PN_DIV
  MOV  AH, 02h
  MOV  DL, '0'
  INT  21h
  RET
PN_DIV:
  MOV  DX, 0
  DIV  BX
  PUSH DX
  INC  CX
  CMP  AX, 0
  JNZ  PN_DIV
PN_PRINT:
  POP  DX
  ADD  DL, '0'
  MOV  AH, 02h
  INT  21h
  LOOP PN_PRINT
  RET
PRINT_NUM ENDP

; ============================================================
; SHOW_TITLE
; ============================================================
SHOW_TITLE PROC
  LEA  DX, MSG_TITLE1
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_TITLE2
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_TITLE3
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_TITLE4
  MOV  AH, 09h
  INT  21h
  RET
SHOW_TITLE ENDP

; ============================================================
; SHOW_RULES
; ============================================================
SHOW_RULES PROC
  LEA  DX, MSG_SEP
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RULES1
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RULES2
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RULES3
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RULES4
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RULES5
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_SEP
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_START
  MOV  AH, 09h
  INT  21h
  RET
SHOW_RULES ENDP

; ============================================================
; SHOW_STATUS  -  Lives, Streak, Hints, Progress bar
; ============================================================
SHOW_STATUS PROC
  LEA  DX, MSG_SEP
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_LIVES
  MOV  AH, 09h
  INT  21h
  MOV  AL, LIVES
  MOV  AH, 0
  CALL PRINT_NUM
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_STREAK_D
  MOV  AH, 09h
  INT  21h
  MOV  AL, STREAK
  MOV  AH, 0
  CALL PRINT_NUM
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_HINTS_D
  MOV  AH, 09h
  INT  21h
  MOV  AL, HINTS_LEFT
  MOV  AH, 0
  CALL PRINT_NUM
  LEA  DX, NEWLINE
  MOV  AH, 09h
  INT  21h
  CALL SHOW_PROGRESS
  RET
SHOW_STATUS ENDP

; ============================================================
; SHOW_PROGRESS  -  Visual progress bar [####......]
; ============================================================
SHOW_PROGRESS PROC
  PUSH CX
  PUSH BX
  LEA  DX, MSG_PROG_L
  MOV  AH, 09h
  INT  21h
  MOV  BL, QNUM
  DEC  BL
  MOV  CL, BL
  MOV  CH, 0
  JCXZ PROG_DOTS
PROG_HASH_LOOP:
  LEA  DX, MSG_PROG_DONE
  MOV  AH, 09h
  INT  21h
  LOOP PROG_HASH_LOOP
PROG_DOTS:
  MOV  CL, 10
  SUB  CL, BL
  MOV  CH, 0
  JCXZ PROG_CLOSE
PROG_DOT_LOOP:
  LEA  DX, MSG_PROG_TODO
  MOV  AH, 09h
  INT  21h
  LOOP PROG_DOT_LOOP
PROG_CLOSE:
  LEA  DX, MSG_PROG_R
  MOV  AH, 09h
  INT  21h
  POP  BX
  POP  CX
  RET
SHOW_PROGRESS ENDP

; ============================================================
; SHOW_QUESTION  -  "Question X of 10" + equation
; TEMP_DIGIT fix: saves units digit before AH is clobbered
; ============================================================
SHOW_QUESTION PROC
  LEA  DX, MSG_Q
  MOV  AH, 09h
  INT  21h
  MOV  AL, QNUM
  MOV  AH, 0
  MOV  BL, 10
  DIV  BL
  MOV  TEMP_DIGIT, AH        ; save units digit before INT clobbers AH
  CMP  AL, 0
  JE   SQ_SKIP_TENS
  ADD  AL, '0'
  MOV  AH, 02h
  MOV  DL, AL
  INT  21h
SQ_SKIP_TENS:
  MOV  AL, TEMP_DIGIT
  ADD  AL, '0'
  MOV  AH, 02h
  MOV  DL, AL
  INT  21h
  LEA  DX, MSG_OF
  MOV  AH, 09h
  INT  21h
  MOV  AX, NUM1
  CALL PRINT_NUM
  CMP  OPERATOR, 0
  JE   SQ_PLUS
  CMP  OPERATOR, 1
  JE   SQ_MINUS
  LEA  DX, MSG_MUL
  JMP  SQ_OP_DONE
SQ_PLUS:
  LEA  DX, MSG_PLUS
  JMP  SQ_OP_DONE
SQ_MINUS:
  LEA  DX, MSG_MINUS
SQ_OP_DONE:
  MOV  AH, 09h
  INT  21h
  MOV  AX, NUM2
  CALL PRINT_NUM
  LEA  DX, MSG_EQ
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_PROMPT
  MOV  AH, 09h
  INT  21h
  RET
SHOW_QUESTION ENDP

; ============================================================
; SHOW_RESULT  -  Score, grade, high score, play again
; ============================================================
SHOW_RESULT PROC
  LEA  DX, MSG_RESULT1
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RESULT2
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_RESULT3
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_SCORE_L
  MOV  AH, 09h
  INT  21h
  MOV  AL, SCORE
  MOV  AH, 0
  CALL PRINT_NUM
  LEA  DX, MSG_SCORE_R
  MOV  AH, 09h
  INT  21h
  MOV  AL, SCORE
  CMP  AL, HIGH_SCORE
  JLE  SR_SHOW_HS
  MOV  HIGH_SCORE, AL
  LEA  DX, MSG_NEWHS
  MOV  AH, 09h
  INT  21h
SR_SHOW_HS:
  LEA  DX, MSG_HS_L
  MOV  AH, 09h
  INT  21h
  MOV  AL, HIGH_SCORE
  MOV  AH, 0
  CALL PRINT_NUM
  LEA  DX, MSG_HS_R
  MOV  AH, 09h
  INT  21h
  MOV  AL, SCORE
  CMP  AL, 10
  JNE  SR_GRADE
  LEA  DX, MSG_PERFECT
  MOV  AH, 09h
  INT  21h
SR_GRADE:
  LEA  DX, MSG_GRADE_HDR
  MOV  AH, 09h
  INT  21h
  MOV  AL, SCORE
  CMP  AL, 9
  JGE  SR_A
  CMP  AL, 7
  JGE  SR_B
  CMP  AL, 5
  JGE  SR_C
  JMP  SR_F
SR_A: LEA  DX, MSG_GRADE_A
  JMP  SR_SHOW
SR_B: LEA  DX, MSG_GRADE_B
  JMP  SR_SHOW
SR_C: LEA  DX, MSG_GRADE_C
  JMP  SR_SHOW
SR_F: LEA  DX, MSG_GRADE_F
SR_SHOW:
  MOV  AH, 09h
  INT  21h
  LEA  DX, MSG_PLAY_AGAIN
  MOV  AH, 09h
  INT  21h
  MOV  AH, 01h
  INT  21h
  CMP  AL, 'Y'
  JE   SR_RESTART
  CMP  AL, 'y'
  JE   SR_RESTART
  JMP  EXIT_PROG
SR_RESTART:
  MOV  SCORE,      0
  MOV  QNUM,       1
  MOV  STREAK,     0
  MOV  HINTS_LEFT, 2
  MOV  LIVES,      3
  MOV  AX, 0003h
  INT  10h
  CALL SHOW_TITLE
  CALL SELECT_DIFFICULTY
  CALL SHOW_RULES
  MOV  AH, 01h
  INT  21h
  JMP  GAME_LOOP
SHOW_RESULT ENDP