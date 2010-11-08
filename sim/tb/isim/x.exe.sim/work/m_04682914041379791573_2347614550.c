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

/* This file is designed for use with ISim build 0x61e1bd6e */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "/home/shep/projects/ocpi/sim/tb/tb200.v";
static unsigned int ng1[] = {0U, 0U};
static unsigned int ng2[] = {1U, 0U};
static const char *ng3 = "[%0d] %m: System Reset Asserted, RST_N=0";
static int ng4[] = {0, 0};
static int ng5[] = {1, 0};
static const char *ng6 = "[%0d] %m: System Reset Released, RST_N=1";



static void Always_17_0(char *t0)
{
    char *t1;
    char *t2;
    char *t3;

LAB0:    t1 = (t0 + 4872U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(17, ng0);

LAB4:    xsi_set_current_line(18, ng0);
    t2 = (t0 + 4680);
    xsi_process_wait(t2, 5000LL);
    *((char **)t1) = &&LAB5;

LAB1:    return;
LAB5:    xsi_set_current_line(18, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 3640);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(19, ng0);
    t2 = (t0 + 4680);
    xsi_process_wait(t2, 5000LL);
    *((char **)t1) = &&LAB6;
    goto LAB1;

LAB6:    xsi_set_current_line(19, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 3640);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    goto LAB2;

}

static void Initial_22_1(char *t0)
{
    char t7[16];
    char t8[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;

LAB0:    t1 = (t0 + 5120U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(22, ng0);

LAB4:    t2 = (t0 + 280);
    xsi_vlog_namedbase_setdisablestate(t2, &&LAB5);
    t3 = (t0 + 4928);
    xsi_vlog_namedbase_pushprocess(t2, t3);

LAB6:    xsi_set_current_line(25, ng0);
    t4 = (t0 + 4928);
    xsi_process_wait(t4, 0LL);
    *((char **)t1) = &&LAB7;

LAB1:    return;
LAB5:    t3 = (t0 + 4928);
    xsi_vlog_dispose_process_subprogram_invocation(t3);
    goto LAB1;

LAB7:    xsi_set_current_line(25, ng0);
    t5 = ((char*)((ng1)));
    t6 = (t0 + 3800);
    xsi_vlogvar_assign_value(t6, t5, 0, 0, 1);
    xsi_set_current_line(25, ng0);
    t2 = xsi_vlog_time(t7, 1000.0000000000000, 1000.0000000000000);
    t3 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng3, 2, t3, (char)118, t7, 64);
    xsi_set_current_line(26, ng0);
    xsi_set_current_line(26, ng0);
    t2 = ((char*)((ng4)));
    t3 = (t0 + 3960);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 32);

LAB8:    t2 = (t0 + 3960);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 768);
    t6 = *((char **)t5);
    memset(t8, 0, 8);
    xsi_vlog_signed_less(t8, 32, t4, 32, t6, 32);
    t5 = (t8 + 4);
    t9 = *((unsigned int *)t5);
    t10 = (~(t9));
    t11 = *((unsigned int *)t8);
    t12 = (t11 & t10);
    t13 = (t12 != 0);
    if (t13 > 0)
        goto LAB9;

LAB10:    xsi_set_current_line(27, ng0);
    t2 = (t0 + 4928);
    xsi_process_wait(t2, 0LL);
    *((char **)t1) = &&LAB12;
    goto LAB1;

LAB9:    xsi_set_current_line(26, ng0);
    t14 = (t0 + 5688);
    *((int *)t14) = 1;
    t15 = (t0 + 5152);
    *((char **)t15) = t14;
    *((char **)t1) = &&LAB11;
    goto LAB1;

LAB11:    xsi_set_current_line(26, ng0);
    t2 = (t0 + 3960);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng5)));
    memset(t8, 0, 8);
    xsi_vlog_signed_add(t8, 32, t4, 32, t5, 32);
    t6 = (t0 + 3960);
    xsi_vlogvar_assign_value(t6, t8, 0, 0, 32);
    goto LAB8;

LAB12:    xsi_set_current_line(27, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 3800);
    xsi_vlogvar_assign_value(t4, t3, 0, 0, 1);
    xsi_set_current_line(27, ng0);
    t2 = xsi_vlog_time(t7, 1000.0000000000000, 1000.0000000000000);
    t3 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng6, 2, t3, (char)118, t7, 64);
    t2 = (t0 + 280);
    xsi_vlog_namedbase_popprocess(t2);
    goto LAB5;

}

static void Cont_44_2(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    char *t15;
    unsigned int t16;
    unsigned int t17;
    char *t18;

LAB0:    t1 = (t0 + 5368U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(44, ng0);
    t2 = (t0 + 3640);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 5784);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    memset(t9, 0, 8);
    t10 = 1U;
    t11 = t10;
    t12 = (t4 + 4);
    t13 = *((unsigned int *)t4);
    t10 = (t10 & t13);
    t14 = *((unsigned int *)t12);
    t11 = (t11 & t14);
    t15 = (t9 + 4);
    t16 = *((unsigned int *)t9);
    *((unsigned int *)t9) = (t16 | t10);
    t17 = *((unsigned int *)t15);
    *((unsigned int *)t15) = (t17 | t11);
    xsi_driver_vfirst_trans(t5, 0, 0);
    t18 = (t0 + 5704);
    *((int *)t18) = 1;

LAB1:    return;
}


extern void work_m_04682914041379791573_2347614550_init()
{
	static char *pe[] = {(void *)Always_17_0,(void *)Initial_22_1,(void *)Cont_44_2};
	xsi_register_didat("work_m_04682914041379791573_2347614550", "isim/x.exe.sim/work/m_04682914041379791573_2347614550.didat");
	xsi_register_executes(pe);
}
