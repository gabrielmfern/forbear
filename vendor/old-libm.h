#if defined(__x86_64__) && !defined(__ASSEMBLER__)
__asm__(".symver sinh,sinh@GLIBC_2.2.5");
__asm__(".symver cosh,cosh@GLIBC_2.2.5");
__asm__(".symver sqrtf,sqrtf@GLIBC_2.2.5");
#endif
