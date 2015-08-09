

.globl ___chkstk_ms
.cfi_startproc
___chkstk_ms:
    pushq %rcx			/* save temps */
    .cfi_adjust_cfa_offset 8
    .cfi_rel_offset %rcx, 0
    pushq	%rax
    .cfi_adjust_cfa_offset 8
    .cfi_rel_offset %rax, 0
    cmpq $0x1000, %rax
    leaq 24(%rsp), %rcx
    jb	end
loop:
    subq $0x1000, %rcx
    orq $0x0, (%rcx)
    subq $0x1000, %rax
    cmpq $0x1000, %rax
    ja loop
end:
    subq %rax, %rcx
    orq $0x0, (%rcx)
    popq %rax
    .cfi_adjust_cfa_offset -8
    .cfi_restore %rax
    popq %rcx
    .cfi_adjust_cfa_offset -8
    .cfi_restore %rcx
    ret
.cfi_endproc

.globl __chkstk
.set __chkstk, ___chkstk_ms
