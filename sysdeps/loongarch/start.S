/* Startup code compliant to the ELF LoongArch ABI.
   Copyright (C) 2021 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   Contributed by Loongson Technology Corporation Limited.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library.  If not, see
   <http://www.gnu.org/licenses/>.  */

#define __ASSEMBLY__ 1
#include <entry.h>
#include <sys/asm.h>

/* The entry point's job is to call __libc_start_main.  Per the ABI,
   a0 contains the address of a function to be passed to atexit.
   __libc_start_main wants this in a5.  */

/*
int
__libc_start_main (int (*main) (int, char **, char **),
			    int argc,
			    char **argv,
			    __typeof (main) init,
			    void (*fini) (void),
			    void (*rtld_fini) (void),
			    void *stack_end);
*/

ENTRY (ENTRY_POINT)
	/* Terminate call stack by noting ra is undefined.  Use a dummy
	   .cfi_label to force starting the FDE.  */
	.cfi_label .Ldummy
	cfi_undefined (1)
	or	a5, a0, zero /* rtld_fini */

    /*We must get symbol main through GOT table, since main may not be local.
      For instance: googletest defines main in dynamic library. */
	la.got	a0, t0, main
#ifdef __loongarch64
	ld.d	a1, sp, 0
	addi.d	a2, sp, SZREG
#elif defined __loongarch32
	ld.w	a1, sp, 0
	addi.w	a2, sp, SZREG
#endif
	/* Adjust $sp for 16-aligned */
	srli.d  sp, sp, 4
	slli.d  sp, sp, 4

	la.got	a3, t0,  __libc_csu_init
	la.got	a4, t0,  __libc_csu_fini
	or	a6, sp, zero /* stack_end. */

	la.got	ra, t0, __libc_start_main
	jirl	ra, ra, 0

	la.got	ra, t0, abort
	jirl	ra, ra, 0
END (ENTRY_POINT)

