; Header + assembler directives

.memorymap
    slotsize $8000
    defaultslot 0
    slot 0 $8000
    slot 1 $0000
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
    nmi empty_interrupt_handler
    irq empty_interrupt_handler
.endnativevector

.snesemuvector
    cop empty_interrupt_handler
    abort empty_interrupt_handler
    nmi vblank
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

.ramsection "vars" slot 1
bar_pos db
scroll_value db
.ends

.define ram_chars $0100

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
    ; Disable mosaic
    stz $2106
    ; Clear scroll regs for bg 0
    stz $210d
    stz $210d
    stz $210e
    stz $210e
    ; Enable BG0 for main screen
    lda #$01
    sta $212c
    ; Disable all bg's for sub screen
    stz $212d
    ; Disable window masks
    stz $2123
    stz $2124
    ; Clear blending regs
    stz $2130
    stz $2131
    ; Clear screen setting reg
    stz $2133

    ; Set graphics mode 0, tile size 8 for all bg's
    sep #$20 ; 8-bit a
    stz $2105

    ; Set background color
    sep #$30 ; 8-bit a/x/y
    ; Red BG
    stz $2121
    lda #$18
    sta $2122
    stz $2122
    ; Set bar colors
    lda #$03
    tax
palette_loop:
        stz $2122
        sta $2122
        clc
        adc #$20
    dex
    bne palette_loop

    ; Set tile map location to $8000
    sep #$20 ; 8-bit a
    lda #$40
    sta $2107

    ; Set char location to $0000 (for easy updates later)
    lda #$00
    sta $210b

    ; Clear VRAM
    /*sep #$20 ; 8-bit a
    lda #$80
    sta $2115
    rep #$30 ; 16-bit a/x/y
    ldx #$0000
    stz $2116
clear_vram_loop:
        stz $2118
    inx
    cpx #$8000
    bne clear_vram_loop*/

    ; Load tile map
    ;  We want to display the first row of the first 32 tiles, so we'll just write 0-31 into the first row of the map
    sep #$20 ; 8-bit a
    lda #$80
    sta $2115
    rep #$30 ; 16-bit a/x/y
    lda #$4000
    sta $2116
    lda #$0000
load_tile_loop:
        sta $2118
    clc
    adc #$04
    cmp #$0040
    bne load_tile_loop

    ; Reset vars
    sep #$20 ; 8-bit a
    stz bar_pos

    ; Enable screen
    lda #$0f ; screen on, full brightness
    sta $2100

mainloop:
    ; Wait for vblank
    sep #$20 ; 8-bit a
vlank_wait_loop:
        lda $4212
        and #$80
    beq vlank_wait_loop

    ; Prep vars/regs for stretch loop
    sep #$30 ; 8-bit a, x, y
    inc bar_pos
    lda #$ff
    sta $210e
    stz $210e
    sta scroll_value
    ;stz $2115

    ; Clear character data
    sep #$30 ; 8-bit a/x/y
    ldx #$00
clear_char_loop:
        stz ram_chars, x
    inx
    cpx #$20
    bne clear_char_loop

    ; Upload chars to VRAM
    ;  We'll want to clear the first two bytes of every 4th char. ram_chars stores each of these two-byte pairs consecutively, so we'll
    ;  upload them as single 16-bit writes with 64-byte address increments in between via DMA.
    lda #$81
    sta $2115

    lda #$01
    sta $4300
    lda #$18
    sta $4301
    lda #<ram_chars
    sta $4302
    lda #>ram_chars
    sta $4303
    stz $4304
    stz $2116
    stz $2117
    lda #$20
    sta $4305
    stz $4306

    lda #$01
    sta $420b

    /*; Wait for scanline 0
scanline_wait_loop:
    lda $2137
    lda $213d
    tax
    lda $213d
    and #$01
    bne scanline_wait_loop
    cpx #0
    bne scanline_wait_loop

    ; Stretch loop
    ldx #112;224
stretch_loop:
        ; TODO: Update char mem for this line, then wait until hblank

        ; Wait until hblank
hblank_wait_loop:
            lda $4212
            and #$40
        beq hblank_wait_loop

        txa
        and #$0f
        sta $2100

        ; Wait until partway through the scanline
scanline_pos_loop:
        lda $2137
        lda $213c
        tay
        lda $213c
        tya
        cmp #128
        bcc scanline_pos_loop

        txa
        and #$0f
        sta $2100*/

        /*lda scroll_value
        sta $210e
        stz $210e
        dea
        sta scroll_value

        lda bar_pos
        tay
        asl
        asl
        asl
        sty $2100
        sta $2116
        stz $2117
        lda #$aa
        sta $2118
        sta $2118

        lda bar_pos
        ina
        and #$1f
        sta bar_pos
    dex
    bne stretch_loop*/

    jmp mainloop

.ends

.section "vblank" semifree
vblank:
    rti
.ends
