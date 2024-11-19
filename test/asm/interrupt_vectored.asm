.include "init_regs.s"

_start:
    INIT_REGS_LOAD

    # fibonacci spiced with interrupt handler (also with fibonacci)
    li x1, 0x201
    csrw mtvec, x1
    li x27, 0     # handler count
    li x30, 0     # interrupt count
    li x31, 0xde  # branch guard
    csrsi mstatus, 0x8 # machine interrupt enable
    csrr x29, mstatus
    li x1, 0x30000
    csrw mie, x1 # enable custom interrupt 0 and 1
    li x1, 0
    li x2, 1
    li x5, 4
    li x6, 7
    li x7, 0
    li x12, 4
    li x13, 7
    li x14, 0
loop:
    add x3, x2, x1
    mv x1, x2
    mv x2, x3
    bne x2, x4, loop
infloop:
    j infloop

int0_handler:
    # save main loop register state
    mv x9, x1
    mv x10, x2
    mv x11, x3

    # check cause
    li x2, 0x80000010 # cause for 01,11
    csrr x3, mcause
    bne x2, x3, fail

    # generate new mie mask
    andi x2, x30, 0x3
    bnez x2, fill_skip
    li x2, 0x3
    fill_skip:
    slli x2, x2, 16
    csrw mie, x2

    # clear interrupts
    csrr x1, mip
    srli x1, x1, 16
    addi x30, x30, 1
    li x2, 0x10000
    csrc mip, x2 # clear edge reported interrupt
    andi x2, x1, 0x2
    beqz x2, skip_clear_level
        addi x30, x30, 1
        csrwi 0x7ff, 1 # clear level reported interrupt via custom csr
    skip_clear_level:
    addi x27, x27, 1

    # load state
    mv x1, x5
    mv x2, x6
    mv x3, x7
    # fibonacci step
    beq x3, x8, skip
    add x3, x2, x1
    mv x1, x2
    mv x2, x3
    # store state
    mv x5, x1
    mv x6, x2
    mv x7, x3
skip:
    # restore main loop register state
    mv x1, x9
    mv x2, x10
    mv x3, x11
    mret


int1_handler:
    # save main loop register state
    mv x9, x1
    mv x10, x2
    mv x11, x3

    # check cause
    li x2, 0x80000011 # cause for 10
    csrr x3, mcause
    bne x2, x3, fail

    # generate new mie mask
    andi x2, x30, 0x3
    bnez x2, fill1_skip
    li x2, 0x3
    fill1_skip:
    slli x2, x2, 16
    csrw mie, x2

    # clear interrupts
    csrr x1, mip
    srli x1, x1, 16
    andi x2, x1, 0x1
    beqz x2, skip_clear_edge
        addi x30, x30, 1
        li x2, 0x10000
        csrc mip, x2 # clear edge reported interrupt
    skip_clear_edge:
    addi x30, x30, 1
    csrwi 0x7ff, 1 # clear level reported interrupt via custom csr
    addi x27, x27, 1

    # load state
    mv x1, x12
    mv x2, x13
    mv x3, x14
    # fibonacci step
    beq x3, x15, skip
    add x3, x2, x1
    mv x1, x2
    mv x2, x3
    # store state
    mv x12, x1
    mv x13, x2
    mv x14, x3
    j skip

fail:
    csrwi 0x7ff, 2
    j fail


.org 0x200
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    j int0_handler
    j int1_handler
    li x31, 0xae  # should never happen

INIT_REGS_ALLOCATION
