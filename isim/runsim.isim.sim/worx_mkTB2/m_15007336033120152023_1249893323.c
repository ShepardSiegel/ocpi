/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x9ca8bed6 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "/home/shep/projects/ocpi/rtl/mkUUID.v";
static unsigned int ng1[] = {0U, 0U, 268435456U, 0U, 536870912U, 0U, 805306368U, 0U, 1073741824U, 0U, 1342177280U, 0U, 1610612736U, 0U, 1879048192U, 0U, 2147483648U, 0U, 2415919104U, 0U, 2684354560U, 0U, 2952790016U, 0U, 3221225472U, 0U, 3489660928U, 0U, 3758096384U, 0U, 4026531840U, 0U};



static void Cont_28_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;

LAB0:    t1 = (t0 + 2200U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(28, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2584);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    xsi_vlog_bit_copy(t7, 0, t2, 0, 512);
    xsi_driver_vfirst_trans(t3, 0, 511);

LAB1:    return;
}


extern void worx_mktb2_m_15007336033120152023_1249893323_init()
{
	static char *pe[] = {(void *)Cont_28_0};
	xsi_register_didat("worx_mktb2_m_15007336033120152023_1249893323", "isim/runsim.isim.sim/worx_mkTB2/m_15007336033120152023_1249893323.didat");
	xsi_register_executes(pe);
}
