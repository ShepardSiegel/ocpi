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
static const char *ng0 = "/opt/Bluespec/Bluespec-2010.10.beta1/lib/Verilog/main.v";
static int ng1[] = {0, 0};
static const char *ng2 = "bscvcd";
static const char *ng3 = "bscfst";
static const char *ng4 = "bscfsdb";
static const char *ng5 = "bsccycle";
static const char *ng6 = "dump.vcd";
static unsigned int ng7[] = {0U, 0U};
static unsigned int ng8[] = {1U, 0U};
static const char *ng9 = "cycle %0d";
static int ng10[] = {1, 0};



static void Initial_65_0(char *t0)
{
    char t4[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;

LAB0:    t1 = (t0 + 3160U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(65, ng0);

LAB4:    xsi_set_current_line(69, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1608);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 32);
    xsi_set_current_line(71, ng0);
    *((int *)t4) = xsi_vlog_testplusarg(ng2);
    t2 = (t4 + 4);
    *((int *)t2) = 0;
    t3 = (t0 + 1768);
    xsi_vlogvar_assign_value(t3, t4, 0, 0, 1);
    xsi_set_current_line(72, ng0);
    *((int *)t4) = xsi_vlog_testplusarg(ng3);
    t2 = (t4 + 4);
    *((int *)t2) = 0;
    t3 = (t0 + 2088);
    xsi_vlogvar_assign_value(t3, t4, 0, 0, 1);
    xsi_set_current_line(73, ng0);
    *((int *)t4) = xsi_vlog_testplusarg(ng4);
    t2 = (t4 + 4);
    *((int *)t2) = 0;
    t3 = (t0 + 1928);
    xsi_vlogvar_assign_value(t3, t4, 0, 0, 1);
    xsi_set_current_line(74, ng0);
    *((int *)t4) = xsi_vlog_testplusarg(ng5);
    t2 = (t4 + 4);
    *((int *)t2) = 0;
    t3 = (t0 + 2248);
    xsi_vlogvar_assign_value(t3, t4, 0, 0, 1);
    xsi_set_current_line(88, ng0);
    t2 = (t0 + 1768);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB5;

LAB6:
LAB7:    xsi_set_current_line(95, ng0);
    t2 = (t0 + 2968);
    xsi_process_wait(t2, 0LL);
    *((char **)t1) = &&LAB9;

LAB1:    return;
LAB5:    xsi_set_current_line(88, ng0);

LAB8:    xsi_set_current_line(89, ng0);
    xsi_vcd_dumpfile(ng6);
    xsi_set_current_line(90, ng0);
    t2 = ((char*)((ng1)));
    xsi_vcd_dumpvars_args(*((unsigned int *)t2), t0, (char)109, t0, (char)101);
    goto LAB7;

LAB9:    xsi_set_current_line(96, ng0);
    t3 = ((char*)((ng7)));
    t5 = (t0 + 1448);
    xsi_vlogvar_assign_value(t5, t3, 0, 0, 1);
    xsi_set_current_line(97, ng0);
    t2 = (t0 + 2968);
    xsi_process_wait(t2, 1000LL);
    *((char **)t1) = &&LAB10;
    goto LAB1;

LAB10:    xsi_set_current_line(98, ng0);
    t2 = ((char*)((ng8)));
    t3 = (t0 + 1288);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(100, ng0);
    t2 = (t0 + 2968);
    xsi_process_wait(t2, 1000LL);
    *((char **)t1) = &&LAB11;
    goto LAB1;

LAB11:    xsi_set_current_line(101, ng0);
    t2 = ((char*)((ng8)));
    t3 = (t0 + 1448);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    goto LAB1;

}

static void Always_108_1(char *t0)
{
    char t15[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    char *t12;
    char *t13;
    char *t14;

LAB0:    t1 = (t0 + 3408U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(109, ng0);

LAB4:    xsi_set_current_line(110, ng0);
    t2 = (t0 + 3216);
    xsi_process_wait(t2, 1000LL);
    *((char **)t1) = &&LAB5;

LAB1:    return;
LAB5:    xsi_set_current_line(111, ng0);
    t3 = (t0 + 2248);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB6;

LAB7:
LAB8:    xsi_set_current_line(113, ng0);
    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng10)));
    memset(t15, 0, 8);
    xsi_vlog_unsigned_add(t15, 32, t4, 32, t5, 32);
    t6 = (t0 + 1608);
    xsi_vlogvar_assign_value(t6, t15, 0, 0, 32);
    xsi_set_current_line(114, ng0);
    t2 = (t0 + 3216);
    xsi_process_wait(t2, 4000LL);
    *((char **)t1) = &&LAB9;
    goto LAB1;

LAB6:    xsi_set_current_line(112, ng0);
    t12 = (t0 + 1608);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    xsi_vlogfile_write(1, 0, 0, ng9, 2, t0, (char)118, t14, 32);
    goto LAB8;

LAB9:    xsi_set_current_line(115, ng0);
    t2 = ((char*)((ng7)));
    t3 = (t0 + 1288);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(116, ng0);
    t2 = (t0 + 3216);
    xsi_process_wait(t2, 5000LL);
    *((char **)t1) = &&LAB10;
    goto LAB1;

LAB10:    xsi_set_current_line(117, ng0);
    t2 = ((char*)((ng8)));
    t3 = (t0 + 1288);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    goto LAB2;

}


extern void worx_mktb11_m_01118172201867290916_0286164271_init()
{
	static char *pe[] = {(void *)Initial_65_0,(void *)Always_108_1};
	xsi_register_didat("worx_mktb11_m_01118172201867290916_0286164271", "isim/runsim.isim.sim/worx_mkTB11/m_01118172201867290916_0286164271.didat");
	xsi_register_executes(pe);
}
