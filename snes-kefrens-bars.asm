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
bar_tab_index_1 db
bar_tab_index_2 db

bar_tab_index_1_temp db
bar_tab_index_2_temp db
.ends

.define scroll_hdma_table $0400
.define cgram_addr_hdma_table $1000
.define cgram_data_1_hdma_table $1400
.define cgram_data_2_hdma_table $1800

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
    ; Clear mode 7 initial settings reg
    stz $211a
    ; Clear mode 7 center coord
    stz $211f
    stz $211f
    stz $2120
    stz $2120
    ; Set mode 7 identity matrix
    lda #$01
    ;  A (1)
    stz $211b
    sta $211b
    ;  B (0)
    stz $211c
    stz $211c
    ;  C (0)
    stz $211d
    stz $211d
    ;  D (1)
    stz $211e
    sta $211e
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

    ; Set graphics mode 7
    sep #$20 ; 8-bit a
    lda #$07
    sta $2105

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

    ; Set up map data
    ;  We'll do a bunch of 8-bit writes to the low byte of each word in mem in increasing order
    sep #$30 ; 8-bit a, x, y
    stz $2115
    stz $2116
    stz $2117
    ldx #$00
map_data_loop:
        stx $2118
    inx
    cpx #$20
    bne map_data_loop

    ; Set up tile data
    ;  For now, just clear tile 0
    sep #$20 ; 8-bit a
    lda #$80
    sta $2115
    lda #$00
    tay
tile_loop:
        pha
        tya
        rep #$20 ; 16-bit a
        and #$00ff
        asl
        asl
        asl
        asl
        asl
        asl
        sta $2116
        sep #$20 ; 8-bit a
        pla

        ldx #$00
tile_data_loop:
            sta $2119
            inc a
        inx
        cpx #$08
        bne tile_data_loop
    iny
    cpy #$20
    bne tile_loop

    ; Reset vars
    sep #$20 ; 8-bit a
    stz bar_tab_index_1
    stz bar_tab_index_2

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

    ; Clear palette
    sep #$30 ; 8-bit a/x/y
    stz $2121
    ldx #$00
palette_loop:
        stz $2122
        stz $2122
    inx
    bne palette_loop

    ; Prep vars/regs
    sep #$30 ; 8-bit a, x, y
    dec bar_tab_index_1
    lda bar_tab_index_1
    sta bar_tab_index_1_temp

    lda bar_tab_index_2
    clc
    adc #$03
    sta bar_tab_index_2
    sta bar_tab_index_2_temp

    ; Set up scroll HDMA channel
    sep #$20 ; 8-bit a
    lda #$02
    sta $4300
    lda #$0e
    sta $4301
    lda #<scroll_hdma_table
    sta $4302
    lda #>scroll_hdma_table
    sta $4303
    stz $4304

    ; Set up CGRAM addr HDMA table
    sep #$20 ; 8-bit a
    lda #$00
    sta $4310
    lda #$21
    sta $4311
    lda #<cgram_addr_hdma_table
    sta $4312
    lda #>cgram_addr_hdma_table
    sta $4313
    stz $4314

    ; Set up CGRAM data 1 HDMA table
    sep #$20 ; 8-bit a
    lda #$02
    sta $4320
    lda #$22
    sta $4321
    lda #<cgram_data_1_hdma_table
    sta $4322
    lda #>cgram_data_1_hdma_table
    sta $4323
    stz $4324

    ; Set up CGRAM data 2 HDMA table
    sep #$20 ; 8-bit a
    lda #$02
    sta $4330
    lda #$22
    sta $4331
    lda #<cgram_data_2_hdma_table
    sta $4332
    lda #>cgram_data_2_hdma_table
    sta $4333
    stz $4334

    ; Enable HDMA
    lda #$0f
    sta $420c

    ; Build scroll HDMA table
    sep #$20 ; 8-bit a
    rep #$10 ; 16-bit x/y
    ldx #$0000
    ldy #$ffff
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

    ; Build CGRAM addr HDMA table
    sep #$30 ; 8-bit a/x/y
    rep #$10 ; 16-bit x/y
    ldx #$0000
cgram_addr_hdma_table_loop:
        lda #$01
        sta cgram_addr_hdma_table, x
        inx
        phx
        sep #$10 ; 8-bit x/y
        ldy bar_tab_index_2_temp
        lda sintab, y
        asl ; Place sign into carry
        lda sintab, y
        ror
        ldy bar_tab_index_1_temp
        clc
        adc sintab, y
        clc
        adc #$80
        rep #$10 ; 16-bit x/y
        plx
        sta cgram_addr_hdma_table, x
        inx

        inc bar_tab_index_1_temp
        lda bar_tab_index_2_temp
        clc
        adc #$03
        sta bar_tab_index_2_temp
    cpx #(224 * 2)
    bne cgram_addr_hdma_table_loop
    stz cgram_addr_hdma_table, x

    ; Build CGRAM data 1 HDMA table
    sep #$20 ; 8-bit a
    rep #$10 ; 16-bit x/y
    ldx #$0000
cgram_data_1_hdma_table_loop:
        lda #$01
        sta cgram_data_1_hdma_table, x
        inx
        rep #$20 ; 16-bit a
        lda #$4210
        sta cgram_data_1_hdma_table, x
        inx
        inx
        sep #$20 ; 8-bit a
    cpx #(224 * 3)
    bne cgram_data_1_hdma_table_loop
    stz cgram_data_1_hdma_table, x

    ; Build CGRAM data 2 HDMA table
    sep #$20 ; 8-bit a
    rep #$10 ; 16-bit x/y
    ldx #$0000
cgram_data_2_hdma_table_loop:
        lda #$01
        sta cgram_data_2_hdma_table, x
        inx
        rep #$20 ; 16-bit a
        lda #$7fff
        sta cgram_data_2_hdma_table, x
        inx
        inx
        sep #$20 ; 8-bit a
    cpx #(224 * 3)
    bne cgram_data_2_hdma_table_loop
    stz cgram_data_2_hdma_table, x

    ; Reset screen brightness
    sep #$20 ; 8-bit a
    lda #$0f
    sta $2100

    ; ACK interrupt
    lda $4210

    rti

.ends

.section "sin tab" semifree

sintab:
.incbin "tab.bin"

.ends
