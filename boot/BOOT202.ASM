;dos/65 boot
;version 2.02
;released:  22 september 1982
;last revision: 17 february 1984
;     converted to ufdc-1
;   24 november 1984
;     moved io to $f800
;     memory to 62k
;base addresses
  processor 6502
  
  mac fwait           ; Begin the wait macro
.loop
  bit dcont
  bvc .exit           ; Exit if an interrupt has been requested
  bpl .loop
.exit
  endm                ; End of wait macro
  
start   = $1000       ;Start address of assembly
msize   = 62          ;memory size in 1k blocks
pages   = 11          ;pages in sim
memlng  = msize*1024  ;memory size in bytes
simlng  = pages*256   ;sim length in bytes
pemlng  = 3072        ;pem length in bytes
ccmlng  = 2048        ;ccm length in bytes
syslng  = ccmlng+pemlng ;system length less sim
sim     = memlng-simlng ;start of sim
ccm     = sim-syslng  ;start of ccm
nsects  = 26*2-1      ;sectors to load
sectrs  = 26          ;full size format
FDC_BASE  equ   $F820
dstat     equ   ($00+FDC_BASE)
dcom      equ   ($00+FDC_BASE)
track     equ   ($01+FDC_BASE)
sectp     equ   ($02+FDC_BASE)
ddata     equ   ($03+FDC_BASE)

VIA_BASE  equ   $F800
VIA_ORB   equ   ($00+VIA_BASE)
VIA_IRB   equ   ($00+VIA_BASE)
VIA_ORA   equ   ($01+VIA_BASE)
VIA_IRA   equ   ($01+VIA_BASE)
VIA_DDRB  equ   ($02+VIA_BASE)
VIA_DDRA  equ   ($03+VIA_BASE)
VIA_T1CL  equ   ($04+VIA_BASE)
VIA_T1CH  equ   ($05+VIA_BASE)
VIA_T1LL  equ   ($06+VIA_BASE)
VIA_T1LH  equ   ($07+VIA_BASE)
VIA_T2CL  equ   ($08+VIA_BASE)
VIA_T2CH  equ   ($09+VIA_BASE)
VIA_SR    equ   ($0A+VIA_BASE)
VIA_ACR   equ   ($0B+VIA_BASE)
VIA_PCR   equ   ($0C+VIA_BASE)
VIA_IFR   equ   ($0D+VIA_BASE)
VIA_IER   equ   ($0E+VIA_BASE)
VIA_ORAN  equ   ($0F+VIA_BASE)
VIA_IRAN  equ   ($0F+VIA_BASE)
;
; Interrupt sources
;
VIA_INT_ANY equ   %10000000
VIA_INT_T1  equ   %01000000
VIA_INT_T2  equ   %00100000
VIA_INT_CB1 equ   %00010000
VIA_INT_CB2 equ   %00001000
VIA_INT_SFT equ   %00000100
VIA_INT_CA1 equ   %00000010
VIA_INT_CA2 equ   %00000001

dcont     equ   VIA_ORAN

;main program
  seg code
  org start
cold:
  sei                 ;disable interrupts
  cld                 ;set binary mode
  ldx #$ff            ;clear
  txs                 ;stack
  ldx #2              ;starting sector
rdblk:
  lda dstat           ;but if 1795
  lsr                 ;busy
  bcs rdblk           ;wait until not busy
trk:
  lda #0              ;starting track
  inc trk+1           ;bump for next time around
  sta ddata           ;send to 1795
  lda #%00010011      ;do a
  sta dcom            ;slow seek
  fwait               ;wait for intrq
  lda dstat           ;get status
  and #%10011001      ;if error
  bne error           ;halt
  lda #%10001100      ;read with delay
doread:
  stx sectp           ;set sector
  ldy #0              ;clear index
  sta dcom            ;do read
rloop:
  fwait               ;wait for drq/intrq
  bmi rdone           ;exit if done
  lda ddata           ;get byte
point:
  sta ccm,y           ;store data
  iny                 ;bump index
  bne rloop           ;and loop
rdone:
  clc                 ;bump
  lda point+1         ;pointer
  adc #128            ;by 128
  sta point+1         ;save
  bcc nocry           ;if no carry
  inc point+2         ;skip high bump
nocry:
  lda dstat           ;get status
  and #%10011101      ;check for error
  bne error           ;halt if error
  dec $7e             ;count down
;  dec seccnt          ;count down
  beq boote           ;if zero done
  inx                 ;else bump sector
  cpx #sectrs+1       ;if over limit
  bcc rdblk2          ;jump
  ldx #1              ;else sector is one
  bne rdblk           ;and start over
rdblk2:
  lda #%10001000      ;read w/o delay
  bne doread          ;and loop
;error halt
error:
  jmp ($fffc)         ;reset system
;normal exit
boote:
  jmp sim             ;execute
; Variables
  org start+$7e
seccnt:
  dc.b nsects        ;sector count
  dc.b $20           ;density code  
  .end
