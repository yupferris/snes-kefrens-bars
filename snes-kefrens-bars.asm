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
    nmi vblank
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

.ramsection "vars" slot 1
bar_pos db
.ends

.define ram_chars $0100
.define scroll_hdma_table $1000
.define vram_addr_data_hdma_table $1400

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
    ; Clear horizontal scroll reg for bg 0
    stz $210d
    stz $210d
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
    lda #$00
    sta $2105

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
    sep #$20 ; 8-bit a
    lda #$80
    sta $2115
    rep #$30 ; 16-bit a/x/y
    ldx #$0000
    stz $2116
clear_vram_loop:
        stz $2118
    inx
    cpx #$8000
    bne clear_vram_loop

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
    sep #$20 ; 8-bit a
    lda #$0f ; screen on, full brightness
    sta $2100

    ; Enable NMI
    sep #$20 ; 8-bit a
    lda #$80
    sta $4200

    ; Enable interrupts
    cli

mainloop:
    wai
    jmp mainloop

.ends

.section "vblank" semifree

vblank:
    ; Darken screen until we're done processing
    lda #$08
    sta $2100

    ; Prep vars/regs
    sep #$30 ; 8-bit a, x, y
    inc bar_pos

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
    sep #$30 ; 8-bit a/x/y
    lda #$81
    sta $2115

    stz $2116
    stz $2117

    lda #$01
    sta $4320
    lda #$18
    sta $4321
    lda #<ram_chars
    sta $4322
    lda #>ram_chars
    sta $4323
    stz $4324
    lda #$20
    sta $4325
    stz $4326

    ; Enable DMA
    lda #$04
    sta $420b

    ; Dummy write (TODO: Remove when HDMA writes work)
    sep #$30 ; 8-bit a/x/y
    lda #$81
    sta $2115

    lda #$80
    sta $2116
    lda #$00
    sta $2117

    lda #$aa
    sta $2118
    lda #$aa
    sta $2119

    ; Set up VRAM addr/data HDMA channel
    sep #$20 ; 8-bit a
    lda #$04
    sta $4300
    lda #$16
    sta $4301
    lda #<vram_addr_data_hdma_table
    sta $4302
    lda #>vram_addr_data_hdma_table
    sta $4303
    stz $4304

    ; Set up scroll HDMA channel
    sep #$20 ; 8-bit a
    lda #$02
    sta $4310
    lda #$0e
    sta $4311
    lda #<scroll_hdma_table
    sta $4312
    lda #>scroll_hdma_table
    sta $4313
    stz $4314

    ; Enable HDMA
    lda #$03
    sta $420c

    ; Build scroll HDMA table
    sep #$20 ; 8-bit a
    rep #$10 ; 16-bit x/y
    ldx #$0000
    ldy #$00ff
scroll_hdma_table_loop:
        lda #$01
        sta scroll_hdma_table, x
        inx
        rep #$20 ; 16-bit a
        tya
        sta scroll_hdma_table, x
        inx
        inx
        dey
        sep #$20 ; 8-bit a
    cpx #(224 * 3)
    bne scroll_hdma_table_loop
    stz scroll_hdma_table, x

    ; Build VRAM addr/data HDMA table
    sep #$20 ; 8-bit a
    rep #$10 ; 16-bit x/y
    ldx #$0000
vram_addr_data_hdma_table_loop:
        lda #$01
        sta vram_addr_data_hdma_table, x
        inx
        rep #$20 ; 16-bit a
        lda #$0000
        sta vram_addr_data_hdma_table, x
        inx
        inx
        rep #$20 ; 16-bit a
        lda #$5555
        sta vram_addr_data_hdma_table, x
        inx
        inx
        sep #$20 ; 8-bit a
    cpx #(224 * 5)
    bne vram_addr_data_hdma_table_loop
    stz vram_addr_data_hdma_table, x

    ; Reset screen brightness
    sep #$20 ; 8-bit a
    lda #$0f
    sta $2100

    ; ACK interrupt
    lda $4210

    rti

.ends
