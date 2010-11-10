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
static const char *ng0 = "/home/shep/projects/ocpi/libsrc/hdl/bsv/FIFO1.v";
static unsigned int ng1[] = {2863311530U, 0U, 2U, 0U};
static unsigned int ng2[] = {0U, 0U};
static unsigned int ng3[] = {1U, 0U};
static int ng4[] = {0, 0};
static int ng5[] = {1, 0};
static const char *ng6 = "Warning: FIFO1: %m -- Dequeuing from empty fifo";
static const char *ng7 = "Warning: FIFO1: %m -- Enqueuing to a full fifo";



static void Cont_61_0(char *t0)
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

LAB0:    t1 = (t0 + 4528U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(61, ng0);
    t2 = (t0 + 3296);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 6232);
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
    t18 = (t0 + 6088);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Initial_67_1(char *t0)
{
    char *t1;
    char *t2;

LAB0:    xsi_set_current_line(68, ng0);

LAB2:    xsi_set_current_line(69, ng0);
    t1 = ((char*)((ng1)));
    t2 = (t0 + 3136);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 34);
    xsi_set_current_line(70, ng0);
    t1 = ((char*)((ng2)));
    t2 = (t0 + 3296);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 1);

LAB1:    return;
}

static void Cont_76_2(char *t0)
{
    char t3[8];
    char *t1;
    char *t2;
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
    char *t15;
    char *t16;
    char *t17;
    unsigned int t18;
    unsigned int t19;
    char *t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    unsigned int t24;
    unsigned int t25;
    char *t26;

LAB0:    t1 = (t0 + 5024U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(76, ng0);
    t2 = (t0 + 3296);
    t4 = (t2 + 56U);
    t5 = *((char **)t4);
    memset(t3, 0, 8);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB7;

LAB5:    if (*((unsigned int *)t6) == 0)
        goto LAB4;

LAB6:    t12 = (t3 + 4);
    *((unsigned int *)t3) = 1;
    *((unsigned int *)t12) = 1;

LAB7:    t13 = (t0 + 6296);
    t14 = (t13 + 56U);
    t15 = *((char **)t14);
    t16 = (t15 + 56U);
    t17 = *((char **)t16);
    memset(t17, 0, 8);
    t18 = 1U;
    t19 = t18;
    t20 = (t3 + 4);
    t21 = *((unsigned int *)t3);
    t18 = (t18 & t21);
    t22 = *((unsigned int *)t20);
    t19 = (t19 & t22);
    t23 = (t17 + 4);
    t24 = *((unsigned int *)t17);
    *((unsigned int *)t17) = (t24 | t18);
    t25 = *((unsigned int *)t23);
    *((unsigned int *)t23) = (t25 | t19);
    xsi_driver_vfirst_trans(t13, 0, 0);
    t26 = (t0 + 6104);
    *((int *)t26) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t3) = 1;
    goto LAB7;

}

static void Always_78_3(char *t0)
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
    char *t12;
    char *t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    char *t19;
    char *t20;

LAB0:    t1 = (t0 + 5272U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(78, ng0);
    t2 = (t0 + 6120);
    *((int *)t2) = 1;
    t3 = (t0 + 5304);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(79, ng0);

LAB5:    xsi_set_current_line(80, ng0);
    t5 = (t0 + 1776U);
    t6 = *((char **)t5);
    memset(t4, 0, 8);
    t5 = (t6 + 4);
    t7 = *((unsigned int *)t5);
    t8 = (~(t7));
    t9 = *((unsigned int *)t6);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB9;

LAB7:    if (*((unsigned int *)t5) == 0)
        goto LAB6;

LAB8:    t12 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t12) = 1;

LAB9:    t13 = (t4 + 4);
    t14 = *((unsigned int *)t13);
    t15 = (~(t14));
    t16 = *((unsigned int *)t4);
    t17 = (t16 & t15);
    t18 = (t17 != 0);
    if (t18 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(85, ng0);

LAB14:    xsi_set_current_line(86, ng0);
    t2 = (t0 + 2416U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB15;

LAB16:    xsi_set_current_line(90, ng0);
    t2 = (t0 + 2096U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB19;

LAB20:    xsi_set_current_line(94, ng0);
    t2 = (t0 + 2256U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB23;

LAB24:
LAB25:
LAB21:
LAB17:
LAB12:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(81, ng0);

LAB13:    xsi_set_current_line(82, ng0);
    t19 = ((char*)((ng2)));
    t20 = (t0 + 3296);
    xsi_vlogvar_wait_assign_value(t20, t19, 0, 0, 1, 0LL);
    goto LAB12;

LAB15:    xsi_set_current_line(87, ng0);

LAB18:    xsi_set_current_line(88, ng0);
    t5 = ((char*)((ng2)));
    t6 = (t0 + 3296);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 1, 0LL);
    goto LAB17;

LAB19:    xsi_set_current_line(91, ng0);

LAB22:    xsi_set_current_line(92, ng0);
    t5 = ((char*)((ng3)));
    t6 = (t0 + 3296);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 1, 0LL);
    goto LAB21;

LAB23:    xsi_set_current_line(95, ng0);

LAB26:    xsi_set_current_line(96, ng0);
    t5 = ((char*)((ng2)));
    t6 = (t0 + 3296);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 1, 0LL);
    goto LAB25;

}

static void Always_101_4(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    char *t11;
    char *t12;

LAB0:    t1 = (t0 + 5520U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(101, ng0);
    t2 = (t0 + 6136);
    *((int *)t2) = 1;
    t3 = (t0 + 5552);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(102, ng0);

LAB5:    xsi_set_current_line(113, ng0);

LAB6:    xsi_set_current_line(114, ng0);
    t4 = (t0 + 2096U);
    t5 = *((char **)t4);
    t4 = (t5 + 4);
    t6 = *((unsigned int *)t4);
    t7 = (~(t6));
    t8 = *((unsigned int *)t5);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB7;

LAB8:
LAB9:    goto LAB2;

LAB7:    xsi_set_current_line(115, ng0);
    t11 = (t0 + 1936U);
    t12 = *((char **)t11);
    t11 = (t0 + 3136);
    xsi_vlogvar_wait_assign_value(t11, t12, 0, 0, 34, 0LL);
    goto LAB9;

}

static void Always_120_5(char *t0)
{
    char t13[8];
    char t20[8];
    char t34[8];
    char t41[8];
    char t81[8];
    char t82[8];
    char t86[8];
    char t99[8];
    char t107[8];
    char t135[8];
    char t143[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    char *t19;
    char *t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    char *t27;
    char *t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    char *t32;
    char *t33;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    unsigned int t38;
    unsigned int t39;
    char *t40;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    char *t45;
    char *t46;
    char *t47;
    unsigned int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    unsigned int t54;
    char *t55;
    char *t56;
    unsigned int t57;
    unsigned int t58;
    unsigned int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    unsigned int t64;
    int t65;
    int t66;
    unsigned int t67;
    unsigned int t68;
    unsigned int t69;
    unsigned int t70;
    unsigned int t71;
    unsigned int t72;
    char *t73;
    unsigned int t74;
    unsigned int t75;
    unsigned int t76;
    unsigned int t77;
    unsigned int t78;
    char *t79;
    char *t80;
    unsigned int t83;
    unsigned int t84;
    unsigned int t85;
    unsigned int t87;
    unsigned int t88;
    unsigned int t89;
    unsigned int t90;
    unsigned int t91;
    char *t92;
    char *t93;
    unsigned int t94;
    unsigned int t95;
    unsigned int t96;
    unsigned int t97;
    char *t98;
    char *t100;
    unsigned int t101;
    unsigned int t102;
    unsigned int t103;
    unsigned int t104;
    unsigned int t105;
    char *t106;
    unsigned int t108;
    unsigned int t109;
    unsigned int t110;
    char *t111;
    char *t112;
    char *t113;
    unsigned int t114;
    unsigned int t115;
    unsigned int t116;
    unsigned int t117;
    unsigned int t118;
    unsigned int t119;
    unsigned int t120;
    char *t121;
    char *t122;
    unsigned int t123;
    unsigned int t124;
    unsigned int t125;
    int t126;
    unsigned int t127;
    unsigned int t128;
    unsigned int t129;
    int t130;
    unsigned int t131;
    unsigned int t132;
    unsigned int t133;
    unsigned int t134;
    char *t136;
    unsigned int t137;
    unsigned int t138;
    unsigned int t139;
    unsigned int t140;
    unsigned int t141;
    char *t142;
    unsigned int t144;
    unsigned int t145;
    unsigned int t146;
    char *t147;
    char *t148;
    char *t149;
    unsigned int t150;
    unsigned int t151;
    unsigned int t152;
    unsigned int t153;
    unsigned int t154;
    unsigned int t155;
    unsigned int t156;
    char *t157;
    char *t158;
    unsigned int t159;
    unsigned int t160;
    unsigned int t161;
    unsigned int t162;
    unsigned int t163;
    unsigned int t164;
    unsigned int t165;
    unsigned int t166;
    int t167;
    int t168;
    unsigned int t169;
    unsigned int t170;
    unsigned int t171;
    unsigned int t172;
    unsigned int t173;
    unsigned int t174;
    char *t175;
    unsigned int t176;
    unsigned int t177;
    unsigned int t178;
    unsigned int t179;
    unsigned int t180;
    char *t181;
    char *t182;

LAB0:    t1 = (t0 + 5768U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(120, ng0);
    t2 = (t0 + 6152);
    *((int *)t2) = 1;
    t3 = (t0 + 5800);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(121, ng0);

LAB5:    t4 = (t0 + 280);
    xsi_vlog_namedbase_setdisablestate(t4, &&LAB6);
    t5 = (t0 + 5576);
    xsi_vlog_namedbase_pushprocess(t4, t5);

LAB7:    xsi_set_current_line(124, ng0);
    t6 = ((char*)((ng4)));
    t7 = (t0 + 3456);
    xsi_vlogvar_assign_value(t7, t6, 0, 0, 1);
    xsi_set_current_line(125, ng0);
    t2 = ((char*)((ng4)));
    t3 = (t0 + 3616);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(126, ng0);
    t2 = (t0 + 1776U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t8 = *((unsigned int *)t2);
    t9 = (~(t8));
    t10 = *((unsigned int *)t3);
    t11 = (t10 & t9);
    t12 = (t11 != 0);
    if (t12 > 0)
        goto LAB8;

LAB9:
LAB10:    t2 = (t0 + 280);
    xsi_vlog_namedbase_popprocess(t2);

LAB6:    t3 = (t0 + 5576);
    xsi_vlog_dispose_process_subprogram_invocation(t3);
    goto LAB2;

LAB8:    xsi_set_current_line(127, ng0);

LAB11:    xsi_set_current_line(128, ng0);
    t4 = (t0 + 3296);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memset(t13, 0, 8);
    t7 = (t6 + 4);
    t14 = *((unsigned int *)t7);
    t15 = (~(t14));
    t16 = *((unsigned int *)t6);
    t17 = (t16 & t15);
    t18 = (t17 & 1U);
    if (t18 != 0)
        goto LAB15;

LAB13:    if (*((unsigned int *)t7) == 0)
        goto LAB12;

LAB14:    t19 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t19) = 1;

LAB15:    memset(t20, 0, 8);
    t21 = (t13 + 4);
    t22 = *((unsigned int *)t21);
    t23 = (~(t22));
    t24 = *((unsigned int *)t13);
    t25 = (t24 & t23);
    t26 = (t25 & 1U);
    if (t26 != 0)
        goto LAB16;

LAB17:    if (*((unsigned int *)t21) != 0)
        goto LAB18;

LAB19:    t28 = (t20 + 4);
    t29 = *((unsigned int *)t20);
    t30 = *((unsigned int *)t28);
    t31 = (t29 || t30);
    if (t31 > 0)
        goto LAB20;

LAB21:    memcpy(t41, t20, 8);

LAB22:    t73 = (t41 + 4);
    t74 = *((unsigned int *)t73);
    t75 = (~(t74));
    t76 = *((unsigned int *)t41);
    t77 = (t76 & t75);
    t78 = (t77 != 0);
    if (t78 > 0)
        goto LAB30;

LAB31:
LAB32:    xsi_set_current_line(133, ng0);
    t2 = (t0 + 2576U);
    t3 = *((char **)t2);
    memset(t13, 0, 8);
    t2 = (t3 + 4);
    t8 = *((unsigned int *)t2);
    t9 = (~(t8));
    t10 = *((unsigned int *)t3);
    t11 = (t10 & t9);
    t12 = (t11 & 1U);
    if (t12 != 0)
        goto LAB37;

LAB35:    if (*((unsigned int *)t2) == 0)
        goto LAB34;

LAB36:    t4 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t4) = 1;

LAB37:    memset(t20, 0, 8);
    t5 = (t13 + 4);
    t14 = *((unsigned int *)t5);
    t15 = (~(t14));
    t16 = *((unsigned int *)t13);
    t17 = (t16 & t15);
    t18 = (t17 & 1U);
    if (t18 != 0)
        goto LAB38;

LAB39:    if (*((unsigned int *)t5) != 0)
        goto LAB40;

LAB41:    t7 = (t20 + 4);
    t22 = *((unsigned int *)t20);
    t23 = *((unsigned int *)t7);
    t24 = (t22 || t23);
    if (t24 > 0)
        goto LAB42;

LAB43:    memcpy(t41, t20, 8);

LAB44:    memset(t81, 0, 8);
    t46 = (t41 + 4);
    t68 = *((unsigned int *)t46);
    t69 = (~(t68));
    t70 = *((unsigned int *)t41);
    t71 = (t70 & t69);
    t72 = (t71 & 1U);
    if (t72 != 0)
        goto LAB52;

LAB53:    if (*((unsigned int *)t46) != 0)
        goto LAB54;

LAB55:    t55 = (t81 + 4);
    t74 = *((unsigned int *)t81);
    t75 = *((unsigned int *)t55);
    t76 = (t74 || t75);
    if (t76 > 0)
        goto LAB56;

LAB57:    memcpy(t143, t81, 8);

LAB58:    t175 = (t143 + 4);
    t176 = *((unsigned int *)t175);
    t177 = (~(t176));
    t178 = *((unsigned int *)t143);
    t179 = (t178 & t177);
    t180 = (t179 != 0);
    if (t180 > 0)
        goto LAB84;

LAB85:
LAB86:    goto LAB10;

LAB12:    *((unsigned int *)t13) = 1;
    goto LAB15;

LAB16:    *((unsigned int *)t20) = 1;
    goto LAB19;

LAB18:    t27 = (t20 + 4);
    *((unsigned int *)t20) = 1;
    *((unsigned int *)t27) = 1;
    goto LAB19;

LAB20:    t32 = (t0 + 2256U);
    t33 = *((char **)t32);
    memset(t34, 0, 8);
    t32 = (t33 + 4);
    t35 = *((unsigned int *)t32);
    t36 = (~(t35));
    t37 = *((unsigned int *)t33);
    t38 = (t37 & t36);
    t39 = (t38 & 1U);
    if (t39 != 0)
        goto LAB23;

LAB24:    if (*((unsigned int *)t32) != 0)
        goto LAB25;

LAB26:    t42 = *((unsigned int *)t20);
    t43 = *((unsigned int *)t34);
    t44 = (t42 & t43);
    *((unsigned int *)t41) = t44;
    t45 = (t20 + 4);
    t46 = (t34 + 4);
    t47 = (t41 + 4);
    t48 = *((unsigned int *)t45);
    t49 = *((unsigned int *)t46);
    t50 = (t48 | t49);
    *((unsigned int *)t47) = t50;
    t51 = *((unsigned int *)t47);
    t52 = (t51 != 0);
    if (t52 == 1)
        goto LAB27;

LAB28:
LAB29:    goto LAB22;

LAB23:    *((unsigned int *)t34) = 1;
    goto LAB26;

LAB25:    t40 = (t34 + 4);
    *((unsigned int *)t34) = 1;
    *((unsigned int *)t40) = 1;
    goto LAB26;

LAB27:    t53 = *((unsigned int *)t41);
    t54 = *((unsigned int *)t47);
    *((unsigned int *)t41) = (t53 | t54);
    t55 = (t20 + 4);
    t56 = (t34 + 4);
    t57 = *((unsigned int *)t20);
    t58 = (~(t57));
    t59 = *((unsigned int *)t55);
    t60 = (~(t59));
    t61 = *((unsigned int *)t34);
    t62 = (~(t61));
    t63 = *((unsigned int *)t56);
    t64 = (~(t63));
    t65 = (t58 & t60);
    t66 = (t62 & t64);
    t67 = (~(t65));
    t68 = (~(t66));
    t69 = *((unsigned int *)t47);
    *((unsigned int *)t47) = (t69 & t67);
    t70 = *((unsigned int *)t47);
    *((unsigned int *)t47) = (t70 & t68);
    t71 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t71 & t67);
    t72 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t72 & t68);
    goto LAB29;

LAB30:    xsi_set_current_line(129, ng0);

LAB33:    xsi_set_current_line(130, ng0);
    t79 = ((char*)((ng5)));
    t80 = (t0 + 3456);
    xsi_vlogvar_assign_value(t80, t79, 0, 0, 1);
    xsi_set_current_line(131, ng0);
    t2 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng6, 1, t2);
    goto LAB32;

LAB34:    *((unsigned int *)t13) = 1;
    goto LAB37;

LAB38:    *((unsigned int *)t20) = 1;
    goto LAB41;

LAB40:    t6 = (t20 + 4);
    *((unsigned int *)t20) = 1;
    *((unsigned int *)t6) = 1;
    goto LAB41;

LAB42:    t19 = (t0 + 2096U);
    t21 = *((char **)t19);
    memset(t34, 0, 8);
    t19 = (t21 + 4);
    t25 = *((unsigned int *)t19);
    t26 = (~(t25));
    t29 = *((unsigned int *)t21);
    t30 = (t29 & t26);
    t31 = (t30 & 1U);
    if (t31 != 0)
        goto LAB45;

LAB46:    if (*((unsigned int *)t19) != 0)
        goto LAB47;

LAB48:    t35 = *((unsigned int *)t20);
    t36 = *((unsigned int *)t34);
    t37 = (t35 & t36);
    *((unsigned int *)t41) = t37;
    t28 = (t20 + 4);
    t32 = (t34 + 4);
    t33 = (t41 + 4);
    t38 = *((unsigned int *)t28);
    t39 = *((unsigned int *)t32);
    t42 = (t38 | t39);
    *((unsigned int *)t33) = t42;
    t43 = *((unsigned int *)t33);
    t44 = (t43 != 0);
    if (t44 == 1)
        goto LAB49;

LAB50:
LAB51:    goto LAB44;

LAB45:    *((unsigned int *)t34) = 1;
    goto LAB48;

LAB47:    t27 = (t34 + 4);
    *((unsigned int *)t34) = 1;
    *((unsigned int *)t27) = 1;
    goto LAB48;

LAB49:    t48 = *((unsigned int *)t41);
    t49 = *((unsigned int *)t33);
    *((unsigned int *)t41) = (t48 | t49);
    t40 = (t20 + 4);
    t45 = (t34 + 4);
    t50 = *((unsigned int *)t20);
    t51 = (~(t50));
    t52 = *((unsigned int *)t40);
    t53 = (~(t52));
    t54 = *((unsigned int *)t34);
    t57 = (~(t54));
    t58 = *((unsigned int *)t45);
    t59 = (~(t58));
    t65 = (t51 & t53);
    t66 = (t57 & t59);
    t60 = (~(t65));
    t61 = (~(t66));
    t62 = *((unsigned int *)t33);
    *((unsigned int *)t33) = (t62 & t60);
    t63 = *((unsigned int *)t33);
    *((unsigned int *)t33) = (t63 & t61);
    t64 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t64 & t60);
    t67 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t67 & t61);
    goto LAB51;

LAB52:    *((unsigned int *)t81) = 1;
    goto LAB55;

LAB54:    t47 = (t81 + 4);
    *((unsigned int *)t81) = 1;
    *((unsigned int *)t47) = 1;
    goto LAB55;

LAB56:    t56 = (t0 + 2256U);
    t73 = *((char **)t56);
    memset(t82, 0, 8);
    t56 = (t73 + 4);
    t77 = *((unsigned int *)t56);
    t78 = (~(t77));
    t83 = *((unsigned int *)t73);
    t84 = (t83 & t78);
    t85 = (t84 & 1U);
    if (t85 != 0)
        goto LAB62;

LAB60:    if (*((unsigned int *)t56) == 0)
        goto LAB59;

LAB61:    t79 = (t82 + 4);
    *((unsigned int *)t82) = 1;
    *((unsigned int *)t79) = 1;

LAB62:    memset(t86, 0, 8);
    t80 = (t82 + 4);
    t87 = *((unsigned int *)t80);
    t88 = (~(t87));
    t89 = *((unsigned int *)t82);
    t90 = (t89 & t88);
    t91 = (t90 & 1U);
    if (t91 != 0)
        goto LAB63;

LAB64:    if (*((unsigned int *)t80) != 0)
        goto LAB65;

LAB66:    t93 = (t86 + 4);
    t94 = *((unsigned int *)t86);
    t95 = (!(t94));
    t96 = *((unsigned int *)t93);
    t97 = (t95 || t96);
    if (t97 > 0)
        goto LAB67;

LAB68:    memcpy(t107, t86, 8);

LAB69:    memset(t135, 0, 8);
    t136 = (t107 + 4);
    t137 = *((unsigned int *)t136);
    t138 = (~(t137));
    t139 = *((unsigned int *)t107);
    t140 = (t139 & t138);
    t141 = (t140 & 1U);
    if (t141 != 0)
        goto LAB77;

LAB78:    if (*((unsigned int *)t136) != 0)
        goto LAB79;

LAB80:    t144 = *((unsigned int *)t81);
    t145 = *((unsigned int *)t135);
    t146 = (t144 & t145);
    *((unsigned int *)t143) = t146;
    t147 = (t81 + 4);
    t148 = (t135 + 4);
    t149 = (t143 + 4);
    t150 = *((unsigned int *)t147);
    t151 = *((unsigned int *)t148);
    t152 = (t150 | t151);
    *((unsigned int *)t149) = t152;
    t153 = *((unsigned int *)t149);
    t154 = (t153 != 0);
    if (t154 == 1)
        goto LAB81;

LAB82:
LAB83:    goto LAB58;

LAB59:    *((unsigned int *)t82) = 1;
    goto LAB62;

LAB63:    *((unsigned int *)t86) = 1;
    goto LAB66;

LAB65:    t92 = (t86 + 4);
    *((unsigned int *)t86) = 1;
    *((unsigned int *)t92) = 1;
    goto LAB66;

LAB67:    t98 = ((char*)((ng3)));
    memset(t99, 0, 8);
    t100 = (t98 + 4);
    t101 = *((unsigned int *)t100);
    t102 = (~(t101));
    t103 = *((unsigned int *)t98);
    t104 = (t103 & t102);
    t105 = (t104 & 4294967295U);
    if (t105 != 0)
        goto LAB70;

LAB71:    if (*((unsigned int *)t100) != 0)
        goto LAB72;

LAB73:    t108 = *((unsigned int *)t86);
    t109 = *((unsigned int *)t99);
    t110 = (t108 | t109);
    *((unsigned int *)t107) = t110;
    t111 = (t86 + 4);
    t112 = (t99 + 4);
    t113 = (t107 + 4);
    t114 = *((unsigned int *)t111);
    t115 = *((unsigned int *)t112);
    t116 = (t114 | t115);
    *((unsigned int *)t113) = t116;
    t117 = *((unsigned int *)t113);
    t118 = (t117 != 0);
    if (t118 == 1)
        goto LAB74;

LAB75:
LAB76:    goto LAB69;

LAB70:    *((unsigned int *)t99) = 1;
    goto LAB73;

LAB72:    t106 = (t99 + 4);
    *((unsigned int *)t99) = 1;
    *((unsigned int *)t106) = 1;
    goto LAB73;

LAB74:    t119 = *((unsigned int *)t107);
    t120 = *((unsigned int *)t113);
    *((unsigned int *)t107) = (t119 | t120);
    t121 = (t86 + 4);
    t122 = (t99 + 4);
    t123 = *((unsigned int *)t121);
    t124 = (~(t123));
    t125 = *((unsigned int *)t86);
    t126 = (t125 & t124);
    t127 = *((unsigned int *)t122);
    t128 = (~(t127));
    t129 = *((unsigned int *)t99);
    t130 = (t129 & t128);
    t131 = (~(t126));
    t132 = (~(t130));
    t133 = *((unsigned int *)t113);
    *((unsigned int *)t113) = (t133 & t131);
    t134 = *((unsigned int *)t113);
    *((unsigned int *)t113) = (t134 & t132);
    goto LAB76;

LAB77:    *((unsigned int *)t135) = 1;
    goto LAB80;

LAB79:    t142 = (t135 + 4);
    *((unsigned int *)t135) = 1;
    *((unsigned int *)t142) = 1;
    goto LAB80;

LAB81:    t155 = *((unsigned int *)t143);
    t156 = *((unsigned int *)t149);
    *((unsigned int *)t143) = (t155 | t156);
    t157 = (t81 + 4);
    t158 = (t135 + 4);
    t159 = *((unsigned int *)t81);
    t160 = (~(t159));
    t161 = *((unsigned int *)t157);
    t162 = (~(t161));
    t163 = *((unsigned int *)t135);
    t164 = (~(t163));
    t165 = *((unsigned int *)t158);
    t166 = (~(t165));
    t167 = (t160 & t162);
    t168 = (t164 & t166);
    t169 = (~(t167));
    t170 = (~(t168));
    t171 = *((unsigned int *)t149);
    *((unsigned int *)t149) = (t171 & t169);
    t172 = *((unsigned int *)t149);
    *((unsigned int *)t149) = (t172 & t170);
    t173 = *((unsigned int *)t143);
    *((unsigned int *)t143) = (t173 & t169);
    t174 = *((unsigned int *)t143);
    *((unsigned int *)t143) = (t174 & t170);
    goto LAB83;

LAB84:    xsi_set_current_line(134, ng0);

LAB87:    xsi_set_current_line(135, ng0);
    t181 = ((char*)((ng5)));
    t182 = (t0 + 3616);
    xsi_vlogvar_assign_value(t182, t181, 0, 0, 1);
    xsi_set_current_line(136, ng0);
    t2 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng7, 1, t2);
    goto LAB86;

}


extern void work_m_16608811249923958053_0832196448_init()
{
	static char *pe[] = {(void *)Cont_61_0,(void *)Initial_67_1,(void *)Cont_76_2,(void *)Always_78_3,(void *)Always_101_4,(void *)Always_120_5};
	xsi_register_didat("work_m_16608811249923958053_0832196448", "isim/x.exe.sim/work/m_16608811249923958053_0832196448.didat");
	xsi_register_executes(pe);
}
