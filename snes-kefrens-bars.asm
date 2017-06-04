; Header + assembler directives

.memorymap
    slotsize $8000
    defaultslot 0
    slot 0 $8000
.endme

.rombanksize $8000
.rombanks 8

.snesheader
    id "SNES"
    ;     --------------------- 21 bytes
    name "SNES KEFRENS BARS YOO"

    slowrom
    lorom

    cartridgetype $00 ; ROM only
    romsize $08 ; 2Mbits
    sramsize $00 ; No SRAM
    country $02 ; Europe
    licenseecode $00
    version $00
.endsnes

.snesnativevector
    cop empty_interrupt_handler
    brk empty_interrupt_handler
    abort empty_interrupt_handler
    nmi vblank_handler
    irq empty_interrupt_handler
.endnativevector

.snesemuvector
    cop empty_interrupt_handler
    abort empty_interrupt_handler
    nmi empty_interrupt_handler
    reset entry
    irqbrk empty_interrupt_handler
.endemuvector

.emptyfill $00

; Empty interrupt handler

.bank 0 slot 0
.section "empty interrupt handler" semifree

empty_interrupt_handler:
    rti

.ends

.bank 0
.section "entry" semifree

entry:
    ; Disable interrupts
    sei

    ; Switch to native mode
    clc
    xce

    ; Reset stack pointer
    rep #$18 ; no bcd, 16-bit x/y
    ldx #$1fff
    txs

    ; HW init
    sep #$30 ; 8-bit a/x/y
    lda #$80 ; screen off, zero brightness
    sta $2100
    ; Clear scroll regs for bg 0
    stz $210d
    stz $210d
    stz $210e
    stz $210e
    ; TODO :)

    ; Set graphics mode 0, tile size 8 for all bg's
    stz $2105

    ; Enable screen
    lda #$0f ; screen on, full brightness
    sta $2100

    ; Enable interrupts
    cli

mainloop:
    wai
    bra mainloop

.ends

.bank 0
.section "vblank handler" semifree

vblank_handler:
    sep #$20 ; 8-bit a
    stz $2121
    lda #$e0
    sta $2122
    lda #$00
    sta $2122

    rti

.ends