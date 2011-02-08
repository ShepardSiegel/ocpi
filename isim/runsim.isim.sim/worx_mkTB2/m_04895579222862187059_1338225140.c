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
static const char *ng0 = "/opt/Bluespec/Bluespec-2010.10.beta1/lib/Verilog/FIFO20.v";
static unsigned int ng1[] = {0U, 0U};
static unsigned int ng2[] = {1U, 0U};
static int ng3[] = {0, 0};
static int ng4[] = {1, 0};
static const char *ng5 = "Warning: FIFO20: %m -- Dequeuing from empty fifo";
static const char *ng6 = "Warning: FIFO20: %m -- Enqueuing to a full fifo";



static void Cont_54_0(char *t0)
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

LAB0:    t1 = (t0 + 4232U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(54, ng0);
    t2 = (t0 + 3000);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 5672);
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
    t18 = (t0 + 5544);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Cont_55_1(char *t0)
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

LAB0:    t1 = (t0 + 4480U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(55, ng0);
    t2 = (t0 + 2840);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 5736);
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
    t18 = (t0 + 5560);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Initial_60_2(char *t0)
{
    char *t1;
    char *t2;

LAB0:    xsi_set_current_line(61, ng0);

LAB2:    xsi_set_current_line(62, ng0);
    t1 = ((char*)((ng1)));
    t2 = (t0 + 2840);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 1);
    xsi_set_current_line(63, ng0);
    t1 = ((char*)((ng2)));
    t2 = (t0 + 3000);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 1);

LAB1:    return;
}

static void Always_68_3(char *t0)
{
    char t4[8];
    char t21[8];
    char t25[8];
    char t32[8];
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
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    unsigned int t33;
    unsigned int t34;
    unsigned int t35;
    char *t36;
    char *t37;
    char *t38;
    unsigned int t39;
    unsigned int t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    unsigned int t45;
    char *t46;
    char *t47;
    unsigned int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    unsigned int t54;
    unsigned int t55;
    int t56;
    int t57;
    unsigned int t58;
    unsigned int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    char *t64;
    unsigned int t65;
    unsigned int t66;
    unsigned int t67;
    unsigned int t68;
    unsigned int t69;
    char *t70;
    char *t71;

LAB0:    t1 = (t0 + 4976U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(68, ng0);
    t2 = (t0 + 5576);
    *((int *)t2) = 1;
    t3 = (t0 + 5008);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(69, ng0);

LAB5:    xsi_set_current_line(70, ng0);
    t5 = (t0 + 1480U);
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

LAB11:    xsi_set_current_line(76, ng0);

LAB14:    xsi_set_current_line(77, ng0);
    t2 = (t0 + 1960U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB15;

LAB16:    xsi_set_current_line(82, ng0);
    t2 = (t0 + 1800U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB19;

LAB20:    if (*((unsigned int *)t2) != 0)
        goto LAB21;

LAB22:    t6 = (t4 + 4);
    t14 = *((unsigned int *)t4);
    t15 = *((unsigned int *)t6);
    t16 = (t14 || t15);
    if (t16 > 0)
        goto LAB23;

LAB24:    memcpy(t32, t4, 8);

LAB25:    t64 = (t32 + 4);
    t65 = *((unsigned int *)t64);
    t66 = (~(t65));
    t67 = *((unsigned int *)t32);
    t68 = (t67 & t66);
    t69 = (t68 != 0);
    if (t69 > 0)
        goto LAB37;

LAB38:    xsi_set_current_line(87, ng0);
    t2 = (t0 + 1800U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB48;

LAB46:    if (*((unsigned int *)t2) == 0)
        goto LAB45;

LAB47:    t5 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t5) = 1;

LAB48:    memset(t21, 0, 8);
    t6 = (t4 + 4);
    t14 = *((unsigned int *)t6);
    t15 = (~(t14));
    t16 = *((unsigned int *)t4);
    t17 = (t16 & t15);
    t18 = (t17 & 1U);
    if (t18 != 0)
        goto LAB49;

LAB50:    if (*((unsigned int *)t6) != 0)
        goto LAB51;

LAB52:    t13 = (t21 + 4);
    t22 = *((unsigned int *)t21);
    t23 = *((unsigned int *)t13);
    t24 = (t22 || t23);
    if (t24 > 0)
        goto LAB53;

LAB54:    memcpy(t32, t21, 8);

LAB55:    t64 = (t32 + 4);
    t65 = *((unsigned int *)t64);
    t66 = (~(t65));
    t67 = *((unsigned int *)t32);
    t68 = (t67 & t66);
    t69 = (t68 != 0);
    if (t69 > 0)
        goto LAB63;

LAB64:
LAB65:
LAB39:
LAB17:
LAB12:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(71, ng0);

LAB13:    xsi_set_current_line(72, ng0);
    t19 = ((char*)((ng1)));
    t20 = (t0 + 2840);
    xsi_vlogvar_wait_assign_value(t20, t19, 0, 0, 1, 0LL);
    xsi_set_current_line(73, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 3000);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB12;

LAB15:    xsi_set_current_line(78, ng0);

LAB18:    xsi_set_current_line(79, ng0);
    t5 = ((char*)((ng1)));
    t6 = (t0 + 2840);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 1, 0LL);
    xsi_set_current_line(80, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 3000);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB17;

LAB19:    *((unsigned int *)t4) = 1;
    goto LAB22;

LAB21:    t5 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t5) = 1;
    goto LAB22;

LAB23:    t12 = (t0 + 2120U);
    t13 = *((char **)t12);
    memset(t21, 0, 8);
    t12 = (t13 + 4);
    t17 = *((unsigned int *)t12);
    t18 = (~(t17));
    t22 = *((unsigned int *)t13);
    t23 = (t22 & t18);
    t24 = (t23 & 1U);
    if (t24 != 0)
        goto LAB29;

LAB27:    if (*((unsigned int *)t12) == 0)
        goto LAB26;

LAB28:    t19 = (t21 + 4);
    *((unsigned int *)t21) = 1;
    *((unsigned int *)t19) = 1;

LAB29:    memset(t25, 0, 8);
    t20 = (t21 + 4);
    t26 = *((unsigned int *)t20);
    t27 = (~(t26));
    t28 = *((unsigned int *)t21);
    t29 = (t28 & t27);
    t30 = (t29 & 1U);
    if (t30 != 0)
        goto LAB30;

LAB31:    if (*((unsigned int *)t20) != 0)
        goto LAB32;

LAB33:    t33 = *((unsigned int *)t4);
    t34 = *((unsigned int *)t25);
    t35 = (t33 & t34);
    *((unsigned int *)t32) = t35;
    t36 = (t4 + 4);
    t37 = (t25 + 4);
    t38 = (t32 + 4);
    t39 = *((unsigned int *)t36);
    t40 = *((unsigned int *)t37);
    t41 = (t39 | t40);
    *((unsigned int *)t38) = t41;
    t42 = *((unsigned int *)t38);
    t43 = (t42 != 0);
    if (t43 == 1)
        goto LAB34;

LAB35:
LAB36:    goto LAB25;

LAB26:    *((unsigned int *)t21) = 1;
    goto LAB29;

LAB30:    *((unsigned int *)t25) = 1;
    goto LAB33;

LAB32:    t31 = (t25 + 4);
    *((unsigned int *)t25) = 1;
    *((unsigned int *)t31) = 1;
    goto LAB33;

LAB34:    t44 = *((unsigned int *)t32);
    t45 = *((unsigned int *)t38);
    *((unsigned int *)t32) = (t44 | t45);
    t46 = (t4 + 4);
    t47 = (t25 + 4);
    t48 = *((unsigned int *)t4);
    t49 = (~(t48));
    t50 = *((unsigned int *)t46);
    t51 = (~(t50));
    t52 = *((unsigned int *)t25);
    t53 = (~(t52));
    t54 = *((unsigned int *)t47);
    t55 = (~(t54));
    t56 = (t49 & t51);
    t57 = (t53 & t55);
    t58 = (~(t56));
    t59 = (~(t57));
    t60 = *((unsigned int *)t38);
    *((unsigned int *)t38) = (t60 & t58);
    t61 = *((unsigned int *)t38);
    *((unsigned int *)t38) = (t61 & t59);
    t62 = *((unsigned int *)t32);
    *((unsigned int *)t32) = (t62 & t58);
    t63 = *((unsigned int *)t32);
    *((unsigned int *)t32) = (t63 & t59);
    goto LAB36;

LAB37:    xsi_set_current_line(83, ng0);

LAB40:    xsi_set_current_line(84, ng0);
    t70 = ((char*)((ng2)));
    t71 = (t0 + 2840);
    xsi_vlogvar_wait_assign_value(t71, t70, 0, 0, 1, 0LL);
    xsi_set_current_line(85, ng0);
    t2 = (t0 + 2840);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    memset(t4, 0, 8);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB44;

LAB42:    if (*((unsigned int *)t6) == 0)
        goto LAB41;

LAB43:    t12 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t12) = 1;

LAB44:    t13 = (t0 + 3000);
    xsi_vlogvar_wait_assign_value(t13, t4, 0, 0, 1, 0LL);
    goto LAB39;

LAB41:    *((unsigned int *)t4) = 1;
    goto LAB44;

LAB45:    *((unsigned int *)t4) = 1;
    goto LAB48;

LAB49:    *((unsigned int *)t21) = 1;
    goto LAB52;

LAB51:    t12 = (t21 + 4);
    *((unsigned int *)t21) = 1;
    *((unsigned int *)t12) = 1;
    goto LAB52;

LAB53:    t19 = (t0 + 2120U);
    t20 = *((char **)t19);
    memset(t25, 0, 8);
    t19 = (t20 + 4);
    t26 = *((unsigned int *)t19);
    t27 = (~(t26));
    t28 = *((unsigned int *)t20);
    t29 = (t28 & t27);
    t30 = (t29 & 1U);
    if (t30 != 0)
        goto LAB56;

LAB57:    if (*((unsigned int *)t19) != 0)
        goto LAB58;

LAB59:    t33 = *((unsigned int *)t21);
    t34 = *((unsigned int *)t25);
    t35 = (t33 & t34);
    *((unsigned int *)t32) = t35;
    t36 = (t21 + 4);
    t37 = (t25 + 4);
    t38 = (t32 + 4);
    t39 = *((unsigned int *)t36);
    t40 = *((unsigned int *)t37);
    t41 = (t39 | t40);
    *((unsigned int *)t38) = t41;
    t42 = *((unsigned int *)t38);
    t43 = (t42 != 0);
    if (t43 == 1)
        goto LAB60;

LAB61:
LAB62:    goto LAB55;

LAB56:    *((unsigned int *)t25) = 1;
    goto LAB59;

LAB58:    t31 = (t25 + 4);
    *((unsigned int *)t25) = 1;
    *((unsigned int *)t31) = 1;
    goto LAB59;

LAB60:    t44 = *((unsigned int *)t32);
    t45 = *((unsigned int *)t38);
    *((unsigned int *)t32) = (t44 | t45);
    t46 = (t21 + 4);
    t47 = (t25 + 4);
    t48 = *((unsigned int *)t21);
    t49 = (~(t48));
    t50 = *((unsigned int *)t46);
    t51 = (~(t50));
    t52 = *((unsigned int *)t25);
    t53 = (~(t52));
    t54 = *((unsigned int *)t47);
    t55 = (~(t54));
    t56 = (t49 & t51);
    t57 = (t53 & t55);
    t58 = (~(t56));
    t59 = (~(t57));
    t60 = *((unsigned int *)t38);
    *((unsigned int *)t38) = (t60 & t58);
    t61 = *((unsigned int *)t38);
    *((unsigned int *)t38) = (t61 & t59);
    t62 = *((unsigned int *)t32);
    *((unsigned int *)t32) = (t62 & t58);
    t63 = *((unsigned int *)t32);
    *((unsigned int *)t32) = (t63 & t59);
    goto LAB62;

LAB63:    xsi_set_current_line(88, ng0);

LAB66:    xsi_set_current_line(89, ng0);
    t70 = ((char*)((ng2)));
    t71 = (t0 + 3000);
    xsi_vlogvar_wait_assign_value(t71, t70, 0, 0, 1, 0LL);
    xsi_set_current_line(90, ng0);
    t2 = (t0 + 3000);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    memset(t4, 0, 8);
    t6 = (t5 + 4);
    t7 = *((unsigned int *)t6);
    t8 = (~(t7));
    t9 = *((unsigned int *)t5);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB70;

LAB68:    if (*((unsigned int *)t6) == 0)
        goto LAB67;

LAB69:    t12 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t12) = 1;

LAB70:    t13 = (t0 + 2840);
    xsi_vlogvar_wait_assign_value(t13, t4, 0, 0, 1, 0LL);
    goto LAB65;

LAB67:    *((unsigned int *)t4) = 1;
    goto LAB70;

}

static void Always_96_4(char *t0)
{
    char t13[8];
    char t20[8];
    char t34[8];
    char t41[8];
    char t81[8];
    char t82[8];
    char t87[8];
    char t101[8];
    char t109[8];
    char t137[8];
    char t145[8];
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
    char *t86;
    char *t88;
    unsigned int t89;
    unsigned int t90;
    unsigned int t91;
    unsigned int t92;
    unsigned int t93;
    char *t94;
    char *t95;
    unsigned int t96;
    unsigned int t97;
    unsigned int t98;
    unsigned int t99;
    char *t100;
    char *t102;
    unsigned int t103;
    unsigned int t104;
    unsigned int t105;
    unsigned int t106;
    unsigned int t107;
    char *t108;
    unsigned int t110;
    unsigned int t111;
    unsigned int t112;
    char *t113;
    char *t114;
    char *t115;
    unsigned int t116;
    unsigned int t117;
    unsigned int t118;
    unsigned int t119;
    unsigned int t120;
    unsigned int t121;
    unsigned int t122;
    char *t123;
    char *t124;
    unsigned int t125;
    unsigned int t126;
    unsigned int t127;
    int t128;
    unsigned int t129;
    unsigned int t130;
    unsigned int t131;
    int t132;
    unsigned int t133;
    unsigned int t134;
    unsigned int t135;
    unsigned int t136;
    char *t138;
    unsigned int t139;
    unsigned int t140;
    unsigned int t141;
    unsigned int t142;
    unsigned int t143;
    char *t144;
    unsigned int t146;
    unsigned int t147;
    unsigned int t148;
    char *t149;
    char *t150;
    char *t151;
    unsigned int t152;
    unsigned int t153;
    unsigned int t154;
    unsigned int t155;
    unsigned int t156;
    unsigned int t157;
    unsigned int t158;
    char *t159;
    char *t160;
    unsigned int t161;
    unsigned int t162;
    unsigned int t163;
    unsigned int t164;
    unsigned int t165;
    unsigned int t166;
    unsigned int t167;
    unsigned int t168;
    int t169;
    int t170;
    unsigned int t171;
    unsigned int t172;
    unsigned int t173;
    unsigned int t174;
    unsigned int t175;
    unsigned int t176;
    char *t177;
    unsigned int t178;
    unsigned int t179;
    unsigned int t180;
    unsigned int t181;
    unsigned int t182;
    char *t183;
    char *t184;

LAB0:    t1 = (t0 + 5224U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(96, ng0);
    t2 = (t0 + 5592);
    *((int *)t2) = 1;
    t3 = (t0 + 5256);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(97, ng0);

LAB5:    t4 = (t0 + 280);
    xsi_vlog_namedbase_setdisablestate(t4, &&LAB6);
    t5 = (t0 + 5032);
    xsi_vlog_namedbase_pushprocess(t4, t5);

LAB7:    xsi_set_current_line(100, ng0);
    t6 = ((char*)((ng3)));
    t7 = (t0 + 3160);
    xsi_vlogvar_assign_value(t7, t6, 0, 0, 1);
    xsi_set_current_line(101, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 3320);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(102, ng0);
    t2 = (t0 + 1480U);
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

LAB6:    t3 = (t0 + 5032);
    xsi_vlog_dispose_process_subprogram_invocation(t3);
    goto LAB2;

LAB8:    xsi_set_current_line(103, ng0);

LAB11:    xsi_set_current_line(104, ng0);
    t4 = (t0 + 2840);
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
LAB32:    xsi_set_current_line(109, ng0);
    t2 = (t0 + 3000);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t13, 0, 8);
    t5 = (t4 + 4);
    t8 = *((unsigned int *)t5);
    t9 = (~(t8));
    t10 = *((unsigned int *)t4);
    t11 = (t10 & t9);
    t12 = (t11 & 1U);
    if (t12 != 0)
        goto LAB37;

LAB35:    if (*((unsigned int *)t5) == 0)
        goto LAB34;

LAB36:    t6 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t6) = 1;

LAB37:    memset(t20, 0, 8);
    t7 = (t13 + 4);
    t14 = *((unsigned int *)t7);
    t15 = (~(t14));
    t16 = *((unsigned int *)t13);
    t17 = (t16 & t15);
    t18 = (t17 & 1U);
    if (t18 != 0)
        goto LAB38;

LAB39:    if (*((unsigned int *)t7) != 0)
        goto LAB40;

LAB41:    t21 = (t20 + 4);
    t22 = *((unsigned int *)t20);
    t23 = *((unsigned int *)t21);
    t24 = (t22 || t23);
    if (t24 > 0)
        goto LAB42;

LAB43:    memcpy(t41, t20, 8);

LAB44:    memset(t81, 0, 8);
    t55 = (t41 + 4);
    t68 = *((unsigned int *)t55);
    t69 = (~(t68));
    t70 = *((unsigned int *)t41);
    t71 = (t70 & t69);
    t72 = (t71 & 1U);
    if (t72 != 0)
        goto LAB52;

LAB53:    if (*((unsigned int *)t55) != 0)
        goto LAB54;

LAB55:    t73 = (t81 + 4);
    t74 = *((unsigned int *)t81);
    t75 = *((unsigned int *)t73);
    t76 = (t74 || t75);
    if (t76 > 0)
        goto LAB56;

LAB57:    memcpy(t145, t81, 8);

LAB58:    t177 = (t145 + 4);
    t178 = *((unsigned int *)t177);
    t179 = (~(t178));
    t180 = *((unsigned int *)t145);
    t181 = (t180 & t179);
    t182 = (t181 != 0);
    if (t182 > 0)
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

LAB20:    t32 = (t0 + 2120U);
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

LAB30:    xsi_set_current_line(105, ng0);

LAB33:    xsi_set_current_line(106, ng0);
    t79 = ((char*)((ng4)));
    t80 = (t0 + 3160);
    xsi_vlogvar_assign_value(t80, t79, 0, 0, 1);
    xsi_set_current_line(107, ng0);
    t2 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng5, 1, t2);
    goto LAB32;

LAB34:    *((unsigned int *)t13) = 1;
    goto LAB37;

LAB38:    *((unsigned int *)t20) = 1;
    goto LAB41;

LAB40:    t19 = (t20 + 4);
    *((unsigned int *)t20) = 1;
    *((unsigned int *)t19) = 1;
    goto LAB41;

LAB42:    t27 = (t0 + 1800U);
    t28 = *((char **)t27);
    memset(t34, 0, 8);
    t27 = (t28 + 4);
    t25 = *((unsigned int *)t27);
    t26 = (~(t25));
    t29 = *((unsigned int *)t28);
    t30 = (t29 & t26);
    t31 = (t30 & 1U);
    if (t31 != 0)
        goto LAB45;

LAB46:    if (*((unsigned int *)t27) != 0)
        goto LAB47;

LAB48:    t35 = *((unsigned int *)t20);
    t36 = *((unsigned int *)t34);
    t37 = (t35 & t36);
    *((unsigned int *)t41) = t37;
    t33 = (t20 + 4);
    t40 = (t34 + 4);
    t45 = (t41 + 4);
    t38 = *((unsigned int *)t33);
    t39 = *((unsigned int *)t40);
    t42 = (t38 | t39);
    *((unsigned int *)t45) = t42;
    t43 = *((unsigned int *)t45);
    t44 = (t43 != 0);
    if (t44 == 1)
        goto LAB49;

LAB50:
LAB51:    goto LAB44;

LAB45:    *((unsigned int *)t34) = 1;
    goto LAB48;

LAB47:    t32 = (t34 + 4);
    *((unsigned int *)t34) = 1;
    *((unsigned int *)t32) = 1;
    goto LAB48;

LAB49:    t48 = *((unsigned int *)t41);
    t49 = *((unsigned int *)t45);
    *((unsigned int *)t41) = (t48 | t49);
    t46 = (t20 + 4);
    t47 = (t34 + 4);
    t50 = *((unsigned int *)t20);
    t51 = (~(t50));
    t52 = *((unsigned int *)t46);
    t53 = (~(t52));
    t54 = *((unsigned int *)t34);
    t57 = (~(t54));
    t58 = *((unsigned int *)t47);
    t59 = (~(t58));
    t65 = (t51 & t53);
    t66 = (t57 & t59);
    t60 = (~(t65));
    t61 = (~(t66));
    t62 = *((unsigned int *)t45);
    *((unsigned int *)t45) = (t62 & t60);
    t63 = *((unsigned int *)t45);
    *((unsigned int *)t45) = (t63 & t61);
    t64 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t64 & t60);
    t67 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t67 & t61);
    goto LAB51;

LAB52:    *((unsigned int *)t81) = 1;
    goto LAB55;

LAB54:    t56 = (t81 + 4);
    *((unsigned int *)t81) = 1;
    *((unsigned int *)t56) = 1;
    goto LAB55;

LAB56:    t79 = (t0 + 2120U);
    t80 = *((char **)t79);
    memset(t82, 0, 8);
    t79 = (t80 + 4);
    t77 = *((unsigned int *)t79);
    t78 = (~(t77));
    t83 = *((unsigned int *)t80);
    t84 = (t83 & t78);
    t85 = (t84 & 1U);
    if (t85 != 0)
        goto LAB62;

LAB60:    if (*((unsigned int *)t79) == 0)
        goto LAB59;

LAB61:    t86 = (t82 + 4);
    *((unsigned int *)t82) = 1;
    *((unsigned int *)t86) = 1;

LAB62:    memset(t87, 0, 8);
    t88 = (t82 + 4);
    t89 = *((unsigned int *)t88);
    t90 = (~(t89));
    t91 = *((unsigned int *)t82);
    t92 = (t91 & t90);
    t93 = (t92 & 1U);
    if (t93 != 0)
        goto LAB63;

LAB64:    if (*((unsigned int *)t88) != 0)
        goto LAB65;

LAB66:    t95 = (t87 + 4);
    t96 = *((unsigned int *)t87);
    t97 = (!(t96));
    t98 = *((unsigned int *)t95);
    t99 = (t97 || t98);
    if (t99 > 0)
        goto LAB67;

LAB68:    memcpy(t109, t87, 8);

LAB69:    memset(t137, 0, 8);
    t138 = (t109 + 4);
    t139 = *((unsigned int *)t138);
    t140 = (~(t139));
    t141 = *((unsigned int *)t109);
    t142 = (t141 & t140);
    t143 = (t142 & 1U);
    if (t143 != 0)
        goto LAB77;

LAB78:    if (*((unsigned int *)t138) != 0)
        goto LAB79;

LAB80:    t146 = *((unsigned int *)t81);
    t147 = *((unsigned int *)t137);
    t148 = (t146 & t147);
    *((unsigned int *)t145) = t148;
    t149 = (t81 + 4);
    t150 = (t137 + 4);
    t151 = (t145 + 4);
    t152 = *((unsigned int *)t149);
    t153 = *((unsigned int *)t150);
    t154 = (t152 | t153);
    *((unsigned int *)t151) = t154;
    t155 = *((unsigned int *)t151);
    t156 = (t155 != 0);
    if (t156 == 1)
        goto LAB81;

LAB82:
LAB83:    goto LAB58;

LAB59:    *((unsigned int *)t82) = 1;
    goto LAB62;

LAB63:    *((unsigned int *)t87) = 1;
    goto LAB66;

LAB65:    t94 = (t87 + 4);
    *((unsigned int *)t87) = 1;
    *((unsigned int *)t94) = 1;
    goto LAB66;

LAB67:    t100 = ((char*)((ng2)));
    memset(t101, 0, 8);
    t102 = (t100 + 4);
    t103 = *((unsigned int *)t102);
    t104 = (~(t103));
    t105 = *((unsigned int *)t100);
    t106 = (t105 & t104);
    t107 = (t106 & 4294967295U);
    if (t107 != 0)
        goto LAB70;

LAB71:    if (*((unsigned int *)t102) != 0)
        goto LAB72;

LAB73:    t110 = *((unsigned int *)t87);
    t111 = *((unsigned int *)t101);
    t112 = (t110 | t111);
    *((unsigned int *)t109) = t112;
    t113 = (t87 + 4);
    t114 = (t101 + 4);
    t115 = (t109 + 4);
    t116 = *((unsigned int *)t113);
    t117 = *((unsigned int *)t114);
    t118 = (t116 | t117);
    *((unsigned int *)t115) = t118;
    t119 = *((unsigned int *)t115);
    t120 = (t119 != 0);
    if (t120 == 1)
        goto LAB74;

LAB75:
LAB76:    goto LAB69;

LAB70:    *((unsigned int *)t101) = 1;
    goto LAB73;

LAB72:    t108 = (t101 + 4);
    *((unsigned int *)t101) = 1;
    *((unsigned int *)t108) = 1;
    goto LAB73;

LAB74:    t121 = *((unsigned int *)t109);
    t122 = *((unsigned int *)t115);
    *((unsigned int *)t109) = (t121 | t122);
    t123 = (t87 + 4);
    t124 = (t101 + 4);
    t125 = *((unsigned int *)t123);
    t126 = (~(t125));
    t127 = *((unsigned int *)t87);
    t128 = (t127 & t126);
    t129 = *((unsigned int *)t124);
    t130 = (~(t129));
    t131 = *((unsigned int *)t101);
    t132 = (t131 & t130);
    t133 = (~(t128));
    t134 = (~(t132));
    t135 = *((unsigned int *)t115);
    *((unsigned int *)t115) = (t135 & t133);
    t136 = *((unsigned int *)t115);
    *((unsigned int *)t115) = (t136 & t134);
    goto LAB76;

LAB77:    *((unsigned int *)t137) = 1;
    goto LAB80;

LAB79:    t144 = (t137 + 4);
    *((unsigned int *)t137) = 1;
    *((unsigned int *)t144) = 1;
    goto LAB80;

LAB81:    t157 = *((unsigned int *)t145);
    t158 = *((unsigned int *)t151);
    *((unsigned int *)t145) = (t157 | t158);
    t159 = (t81 + 4);
    t160 = (t137 + 4);
    t161 = *((unsigned int *)t81);
    t162 = (~(t161));
    t163 = *((unsigned int *)t159);
    t164 = (~(t163));
    t165 = *((unsigned int *)t137);
    t166 = (~(t165));
    t167 = *((unsigned int *)t160);
    t168 = (~(t167));
    t169 = (t162 & t164);
    t170 = (t166 & t168);
    t171 = (~(t169));
    t172 = (~(t170));
    t173 = *((unsigned int *)t151);
    *((unsigned int *)t151) = (t173 & t171);
    t174 = *((unsigned int *)t151);
    *((unsigned int *)t151) = (t174 & t172);
    t175 = *((unsigned int *)t145);
    *((unsigned int *)t145) = (t175 & t171);
    t176 = *((unsigned int *)t145);
    *((unsigned int *)t145) = (t176 & t172);
    goto LAB83;

LAB84:    xsi_set_current_line(110, ng0);

LAB87:    xsi_set_current_line(111, ng0);
    t183 = ((char*)((ng4)));
    t184 = (t0 + 3320);
    xsi_vlogvar_assign_value(t184, t183, 0, 0, 1);
    xsi_set_current_line(112, ng0);
    t2 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng6, 1, t2);
    goto LAB86;

}


extern void worx_mktb2_m_04895579222862187059_1338225140_init()
{
	static char *pe[] = {(void *)Cont_54_0,(void *)Cont_55_1,(void *)Initial_60_2,(void *)Always_68_3,(void *)Always_96_4};
	xsi_register_didat("worx_mktb2_m_04895579222862187059_1338225140", "isim/runsim.isim.sim/worx_mkTB2/m_04895579222862187059_1338225140.didat");
	xsi_register_executes(pe);
}
