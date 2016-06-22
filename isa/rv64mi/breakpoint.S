# See LICENSE for license details.

#*****************************************************************************
# breakpoint.S
#-----------------------------------------------------------------------------
#
# Test breakpoints, if they are implemented.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

  # Set up breakpoint to trap on M-mode fetches.
  li TESTNUM, 2

  # Skip tdrselect if hard-wired.
  li a0, 1<<(_RISCV_SZLONG-1)
  csrw tdrselect, a0
  csrr a1, tdrselect
  bne a0, a1, pass

  # Make sure there's a breakpoint there.
  csrr a0, tdrdata1
  srli a0, a0, _RISCV_SZLONG-4
  li a1, 1
  bne a0, a1, pass

  la a2, 1f
  csrw tdrdata2, a2
  li a0, BPCONTROL_M | BPCONTROL_X
  csrw tdrdata1, a0
  # Skip if breakpoint type is unsupported.
  csrr a1, tdrdata1
  andi a1, a1, 0x7ff
  bne a0, a1, 2f
1:
  # Trap handler should skip this instruction.
  j fail

  # Make sure reads don't trap.
  li TESTNUM, 3
  lw a0, (a2)

2:
  # Set up breakpoint to trap on M-mode reads.
  li TESTNUM, 4
  li a0, BPCONTROL_M | BPCONTROL_R
  csrw tdrdata1, a0
  # Skip if breakpoint type is unsupported.
  csrr a1, tdrdata1
  andi a1, a1, 0x7ff
  bne a0, a1, 2f
  la a2, data1
  csrw tdrdata2, a2

  # Trap handler should skip this instruction.
  lw a2, (a2)
  beqz a2, fail

  # Make sure writes don't trap.
  li TESTNUM, 5
  sw x0, (a2)

2:
  # Set up breakpoint to trap on M-mode stores.
  li TESTNUM, 6
  li a0, BPCONTROL_M | BPCONTROL_W
  csrw tdrdata1, a0
  # Skip if breakpoint type is unsupported.
  csrr a1, tdrdata1
  andi a1, a1, 0x7ff
  bne a0, a1, 2f

  # Trap handler should skip this instruction.
  sw a2, (a2)

  # Make sure store didn't succeed.
  li TESTNUM, 7
  lw a2, (a2)
  bnez a2, fail

  # Try to set up a second breakpoint.
  li a0, (1<<(_RISCV_SZLONG-1)) + 1
  csrw tdrselect, a0
  csrr a1, tdrselect
  bne a0, a1, pass

  # Make sure there's a breakpoint there.
  csrr a0, tdrdata1
  srli a0, a0, _RISCV_SZLONG-4
  li a1, 1
  bne a0, a1, pass

  li a0, BPCONTROL_M | BPCONTROL_R
  csrw tdrdata1, a0
  la a3, data2
  csrw tdrdata2, a3

  # Make sure the second breakpoint triggers.
  li TESTNUM, 8
  lw a3, (a3)
  beqz a3, fail

  # Make sure the first breakpoint still triggers.
  li TESTNUM, 10
  la a2, data1
  sw a2, (a2)
  li TESTNUM, 11
  lw a2, (a2)
  bnez a2, fail

2:
  TEST_PASSFAIL

mtvec_handler:
  # Only even-numbered tests should trap.
  andi t0, TESTNUM, 1
  bnez t0, fail

  li t0, CAUSE_BREAKPOINT
  csrr t1, mcause
  bne t0, t1, fail

  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

data1: .word 0
data2: .word 0

RVTEST_DATA_END