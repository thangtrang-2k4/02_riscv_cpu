    .section .text
    .globl _start
_start:
    addi x10, x0, 0

loop:
    addi x10, x10, 1
    andi x10, x10, 0xF
    jal  x0, loop
