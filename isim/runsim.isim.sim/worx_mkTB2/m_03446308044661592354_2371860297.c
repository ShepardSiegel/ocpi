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
static const char *ng0 = "/opt/Bluespec/Bluespec-2010.10.beta1/lib/Verilog/SyncFIFO.v";
static int ng1[] = {0, 0};
static int ng2[] = {1, 0};
static unsigned int ng3[] = {1U, 0U};
static int ng4[] = {2, 0};
static unsigned int ng5[] = {0U, 0U};
static unsigned int ng6[] = {2U, 0U};
static unsigned int ng7[] = {2863311530U, 0U, 2863311530U, 0U};
static const char *ng8 = "ERROR SyncFiFO.v: index size and depth do not match;";
static const char *ng9 = "\tdepth must equal 2 ** index size. expected %0d";



static int sp_incrGray(char *t1, char *t2)
{
    char t5[8];
    char t17[8];
    char t29[8];
    char t30[8];
    char t52[8];
    char t80[8];
    char t113[8];
    int t0;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    char *t15;
    char *t16;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    unsigned int t23;
    int t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    unsigned int t34;
    unsigned int t35;
    char *t36;
    unsigned int t37;
    unsigned int t38;
    unsigned int t39;
    unsigned int t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    int t45;
    unsigned int t46;
    unsigned int t47;
    unsigned int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    char *t53;
    char *t54;
    char *t55;
    char *t56;
    unsigned int t57;
    unsigned int t58;
    unsigned int t59;
    unsigned int t60;
    unsigned int t61;
    char *t62;
    char *t63;
    unsigned int t64;
    unsigned int t65;
    unsigned int t66;
    unsigned int t67;
    unsigned int t68;
    char *t69;
    char *t70;
    char *t71;
    unsigned int t72;
    unsigned int t73;
    unsigned int t74;
    unsigned int t75;
    unsigned int t76;
    unsigned int t77;
    unsigned int t78;
    unsigned int t79;
    unsigned int t81;
    unsigned int t82;
    unsigned int t83;
    char *t84;
    char *t85;
    char *t86;
    unsigned int t87;
    unsigned int t88;
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
    unsigned int t100;
    unsigned int t101;
    unsigned int t102;
    unsigned int t103;
    int t104;
    int t105;
    unsigned int t106;
    unsigned int t107;
    unsigned int t108;
    unsigned int t109;
    unsigned int t110;
    unsigned int t111;
    char *t112;
    char *t114;
    char *t115;
    char *t116;
    char *t117;
    char *t118;
    char *t119;
    char *t120;
    unsigned int t121;
    int t122;

LAB0:    t0 = 1;
    t3 = (t2 + 48U);
    t4 = *((char **)t3);
    if (t4 == 0)
        goto LAB2;

LAB3:    goto *t4;

LAB2:    xsi_set_current_line(281, ng0);

LAB4:    t4 = (t1 + 872);
    xsi_vlog_namedbase_setdisablestate(t4, &&LAB5);
    xsi_vlog_namedbase_pushprocess(t4, t2);

LAB6:    xsi_set_current_line(286, ng0);
    t6 = (t1 + 9368);
    t7 = (t6 + 56U);
    t8 = *((char **)t7);
    memset(t5, 0, 8);
    t9 = (t8 + 4);
    t10 = *((unsigned int *)t9);
    t11 = (~(t10));
    t12 = *((unsigned int *)t8);
    t13 = (t12 & t11);
    t14 = (t13 & 1U);
    if (t14 != 0)
        goto LAB10;

LAB8:    if (*((unsigned int *)t9) == 0)
        goto LAB7;

LAB9:    t15 = (t5 + 4);
    *((unsigned int *)t5) = 1;
    *((unsigned int *)t15) = 1;

LAB10:    t16 = (t1 + 9848);
    t18 = (t1 + 9848);
    t19 = (t18 + 72U);
    t20 = *((char **)t19);
    t21 = ((char*)((ng1)));
    xsi_vlog_generic_convert_bit_index(t17, t20, 2, t21, 32, 1);
    t22 = (t17 + 4);
    t23 = *((unsigned int *)t22);
    t24 = (!(t23));
    if (t24 == 1)
        goto LAB11;

LAB12:    xsi_set_current_line(287, ng0);
    xsi_set_current_line(287, ng0);
    t4 = ((char*)((ng2)));
    t6 = (t1 + 9528);
    xsi_vlogvar_assign_value(t6, t4, 0, 0, 32);

LAB13:    t4 = (t1 + 9528);
    t6 = (t4 + 56U);
    t7 = *((char **)t6);
    t8 = ((char*)((ng3)));
    memset(t5, 0, 8);
    t9 = (t7 + 4);
    if (*((unsigned int *)t9) != 0)
        goto LAB15;

LAB14:    t15 = (t8 + 4);
    if (*((unsigned int *)t15) != 0)
        goto LAB15;

LAB18:    if (*((unsigned int *)t7) < *((unsigned int *)t8))
        goto LAB16;

LAB17:    t18 = (t5 + 4);
    t10 = *((unsigned int *)t18);
    t11 = (~(t10));
    t12 = *((unsigned int *)t5);
    t13 = (t12 & t11);
    t14 = (t13 != 0);
    if (t14 > 0)
        goto LAB19;

LAB20:    xsi_set_current_line(292, ng0);
    t4 = (t1 + 9208);
    t6 = (t4 + 56U);
    t7 = *((char **)t6);
    t8 = ((char*)((ng4)));
    memset(t5, 0, 8);
    xsi_vlog_unsigned_lshift(t5, 2, t7, 2, t8, 32);
    t9 = (t1 + 9688);
    xsi_vlogvar_assign_value(t9, t5, 0, 0, 2);
    xsi_set_current_line(293, ng0);
    t4 = (t1 + 9368);
    t6 = (t4 + 56U);
    t7 = *((char **)t6);
    t8 = (t1 + 9688);
    t9 = (t8 + 56U);
    t15 = *((char **)t9);
    memset(t17, 0, 8);
    t16 = (t15 + 4);
    t10 = *((unsigned int *)t16);
    t11 = (~(t10));
    t12 = *((unsigned int *)t15);
    t13 = (t12 & t11);
    t14 = (t13 & 3U);
    if (t14 != 0)
        goto LAB40;

LAB41:    if (*((unsigned int *)t16) != 0)
        goto LAB42;

LAB43:    memset(t5, 0, 8);
    t19 = (t17 + 4);
    t23 = *((unsigned int *)t19);
    t32 = (~(t23));
    t33 = *((unsigned int *)t17);
    t34 = (t33 & t32);
    t35 = (t34 & 1U);
    if (t35 != 0)
        goto LAB47;

LAB45:    if (*((unsigned int *)t19) == 0)
        goto LAB44;

LAB46:    t20 = (t5 + 4);
    *((unsigned int *)t5) = 1;
    *((unsigned int *)t20) = 1;

LAB47:    t21 = (t5 + 4);
    t22 = (t17 + 4);
    t37 = *((unsigned int *)t17);
    t38 = (~(t37));
    *((unsigned int *)t5) = t38;
    *((unsigned int *)t21) = 0;
    if (*((unsigned int *)t22) != 0)
        goto LAB49;

LAB48:    t43 = *((unsigned int *)t5);
    *((unsigned int *)t5) = (t43 & 1U);
    t44 = *((unsigned int *)t21);
    *((unsigned int *)t21) = (t44 & 1U);
    t46 = *((unsigned int *)t7);
    t47 = *((unsigned int *)t5);
    t48 = (t46 & t47);
    *((unsigned int *)t29) = t48;
    t25 = (t7 + 4);
    t26 = (t5 + 4);
    t27 = (t29 + 4);
    t49 = *((unsigned int *)t25);
    t50 = *((unsigned int *)t26);
    t51 = (t49 | t50);
    *((unsigned int *)t27) = t51;
    t57 = *((unsigned int *)t27);
    t58 = (t57 != 0);
    if (t58 == 1)
        goto LAB50;

LAB51:
LAB52:    t36 = (t1 + 9848);
    t53 = (t1 + 9848);
    t54 = (t53 + 72U);
    t55 = *((char **)t54);
    t56 = ((char*)((ng3)));
    xsi_vlog_generic_convert_bit_index(t30, t55, 2, t56, 32, 2);
    t62 = (t30 + 4);
    t81 = *((unsigned int *)t62);
    t104 = (!(t81));
    if (t104 == 1)
        goto LAB53;

LAB54:    xsi_set_current_line(295, ng0);
    t4 = (t1 + 9848);
    t6 = (t4 + 56U);
    t7 = *((char **)t6);
    t8 = (t1 + 9208);
    t9 = (t8 + 56U);
    t15 = *((char **)t9);
    t10 = *((unsigned int *)t7);
    t11 = *((unsigned int *)t15);
    t12 = (t10 ^ t11);
    *((unsigned int *)t5) = t12;
    t16 = (t7 + 4);
    t18 = (t15 + 4);
    t19 = (t5 + 4);
    t13 = *((unsigned int *)t16);
    t14 = *((unsigned int *)t18);
    t23 = (t13 | t14);
    *((unsigned int *)t19) = t23;
    t32 = *((unsigned int *)t19);
    t33 = (t32 != 0);
    if (t33 == 1)
        goto LAB55;

LAB56:
LAB57:    t20 = (t1 + 9048);
    xsi_vlogvar_assign_value(t20, t5, 0, 0, 2);
    t4 = (t1 + 872);
    xsi_vlog_namedbase_popprocess(t4);

LAB5:    xsi_vlog_dispose_subprogram_invocation(t2);
    t4 = (t2 + 48U);
    *((char **)t4) = &&LAB2;
    t0 = 0;

LAB1:    return t0;
LAB7:    *((unsigned int *)t5) = 1;
    goto LAB10;

LAB11:    xsi_vlogvar_assign_value(t16, t5, 0, *((unsigned int *)t17), 1);
    goto LAB12;

LAB15:    t16 = (t5 + 4);
    *((unsigned int *)t5) = 1;
    *((unsigned int *)t16) = 1;
    goto LAB17;

LAB16:    *((unsigned int *)t5) = 1;
    goto LAB17;

LAB19:    xsi_set_current_line(288, ng0);

LAB21:    xsi_set_current_line(289, ng0);
    t19 = (t1 + 9208);
    t20 = (t19 + 56U);
    t21 = *((char **)t20);
    t22 = ((char*)((ng4)));
    t25 = ((char*)((ng3)));
    memset(t17, 0, 8);
    xsi_vlog_unsigned_add(t17, 32, t22, 32, t25, 32);
    t26 = (t1 + 9528);
    t27 = (t26 + 56U);
    t28 = *((char **)t27);
    memset(t29, 0, 8);
    xsi_vlog_unsigned_minus(t29, 32, t17, 32, t28, 32);
    memset(t30, 0, 8);
    xsi_vlog_unsigned_lshift(t30, 2, t21, 2, t29, 32);
    t31 = (t1 + 9688);
    xsi_vlogvar_assign_value(t31, t30, 0, 0, 2);
    xsi_set_current_line(290, ng0);
    t4 = (t1 + 9368);
    t6 = (t4 + 56U);
    t7 = *((char **)t6);
    t8 = (t1 + 9208);
    t9 = (t8 + 56U);
    t15 = *((char **)t9);
    t16 = (t1 + 9208);
    t18 = (t16 + 72U);
    t19 = *((char **)t18);
    t20 = (t1 + 9528);
    t21 = (t20 + 56U);
    t22 = *((char **)t21);
    t25 = ((char*)((ng2)));
    memset(t17, 0, 8);
    xsi_vlog_signed_minus(t17, 32, t22, 32, t25, 32);
    xsi_vlog_generic_get_index_select_value(t5, 1, t15, t19, 2, t17, 32, 1);
    t10 = *((unsigned int *)t7);
    t11 = *((unsigned int *)t5);
    t12 = (t10 & t11);
    *((unsigned int *)t29) = t12;
    t26 = (t7 + 4);
    t27 = (t5 + 4);
    t28 = (t29 + 4);
    t13 = *((unsigned int *)t26);
    t14 = *((unsigned int *)t27);
    t23 = (t13 | t14);
    *((unsigned int *)t28) = t23;
    t32 = *((unsigned int *)t28);
    t33 = (t32 != 0);
    if (t33 == 1)
        goto LAB22;

LAB23:
LAB24:    t53 = (t1 + 9688);
    t54 = (t53 + 56U);
    t55 = *((char **)t54);
    memset(t52, 0, 8);
    t56 = (t55 + 4);
    t57 = *((unsigned int *)t56);
    t58 = (~(t57));
    t59 = *((unsigned int *)t55);
    t60 = (t59 & t58);
    t61 = (t60 & 3U);
    if (t61 != 0)
        goto LAB25;

LAB26:    if (*((unsigned int *)t56) != 0)
        goto LAB27;

LAB28:    memset(t30, 0, 8);
    t63 = (t52 + 4);
    t64 = *((unsigned int *)t63);
    t65 = (~(t64));
    t66 = *((unsigned int *)t52);
    t67 = (t66 & t65);
    t68 = (t67 & 1U);
    if (t68 != 0)
        goto LAB32;

LAB30:    if (*((unsigned int *)t63) == 0)
        goto LAB29;

LAB31:    t69 = (t30 + 4);
    *((unsigned int *)t30) = 1;
    *((unsigned int *)t69) = 1;

LAB32:    t70 = (t30 + 4);
    t71 = (t52 + 4);
    t72 = *((unsigned int *)t52);
    t73 = (~(t72));
    *((unsigned int *)t30) = t73;
    *((unsigned int *)t70) = 0;
    if (*((unsigned int *)t71) != 0)
        goto LAB34;

LAB33:    t78 = *((unsigned int *)t30);
    *((unsigned int *)t30) = (t78 & 1U);
    t79 = *((unsigned int *)t70);
    *((unsigned int *)t70) = (t79 & 1U);
    t81 = *((unsigned int *)t29);
    t82 = *((unsigned int *)t30);
    t83 = (t81 & t82);
    *((unsigned int *)t80) = t83;
    t84 = (t29 + 4);
    t85 = (t30 + 4);
    t86 = (t80 + 4);
    t87 = *((unsigned int *)t84);
    t88 = *((unsigned int *)t85);
    t89 = (t87 | t88);
    *((unsigned int *)t86) = t89;
    t90 = *((unsigned int *)t86);
    t91 = (t90 != 0);
    if (t91 == 1)
        goto LAB35;

LAB36:
LAB37:    t112 = (t1 + 9848);
    t114 = (t1 + 9848);
    t115 = (t114 + 72U);
    t116 = *((char **)t115);
    t117 = (t1 + 9528);
    t118 = (t117 + 56U);
    t119 = *((char **)t118);
    xsi_vlog_generic_convert_bit_index(t113, t116, 2, t119, 32, 1);
    t120 = (t113 + 4);
    t121 = *((unsigned int *)t120);
    t122 = (!(t121));
    if (t122 == 1)
        goto LAB38;

LAB39:    xsi_set_current_line(287, ng0);
    t4 = (t1 + 9528);
    t6 = (t4 + 56U);
    t7 = *((char **)t6);
    t8 = ((char*)((ng2)));
    memset(t5, 0, 8);
    xsi_vlog_signed_add(t5, 32, t7, 32, t8, 32);
    t9 = (t1 + 9528);
    xsi_vlogvar_assign_value(t9, t5, 0, 0, 32);
    goto LAB13;

LAB22:    t34 = *((unsigned int *)t29);
    t35 = *((unsigned int *)t28);
    *((unsigned int *)t29) = (t34 | t35);
    t31 = (t7 + 4);
    t36 = (t5 + 4);
    t37 = *((unsigned int *)t7);
    t38 = (~(t37));
    t39 = *((unsigned int *)t31);
    t40 = (~(t39));
    t41 = *((unsigned int *)t5);
    t42 = (~(t41));
    t43 = *((unsigned int *)t36);
    t44 = (~(t43));
    t24 = (t38 & t40);
    t45 = (t42 & t44);
    t46 = (~(t24));
    t47 = (~(t45));
    t48 = *((unsigned int *)t28);
    *((unsigned int *)t28) = (t48 & t46);
    t49 = *((unsigned int *)t28);
    *((unsigned int *)t28) = (t49 & t47);
    t50 = *((unsigned int *)t29);
    *((unsigned int *)t29) = (t50 & t46);
    t51 = *((unsigned int *)t29);
    *((unsigned int *)t29) = (t51 & t47);
    goto LAB24;

LAB25:    *((unsigned int *)t52) = 1;
    goto LAB28;

LAB27:    t62 = (t52 + 4);
    *((unsigned int *)t52) = 1;
    *((unsigned int *)t62) = 1;
    goto LAB28;

LAB29:    *((unsigned int *)t30) = 1;
    goto LAB32;

LAB34:    t74 = *((unsigned int *)t30);
    t75 = *((unsigned int *)t71);
    *((unsigned int *)t30) = (t74 | t75);
    t76 = *((unsigned int *)t70);
    t77 = *((unsigned int *)t71);
    *((unsigned int *)t70) = (t76 | t77);
    goto LAB33;

LAB35:    t92 = *((unsigned int *)t80);
    t93 = *((unsigned int *)t86);
    *((unsigned int *)t80) = (t92 | t93);
    t94 = (t29 + 4);
    t95 = (t30 + 4);
    t96 = *((unsigned int *)t29);
    t97 = (~(t96));
    t98 = *((unsigned int *)t94);
    t99 = (~(t98));
    t100 = *((unsigned int *)t30);
    t101 = (~(t100));
    t102 = *((unsigned int *)t95);
    t103 = (~(t102));
    t104 = (t97 & t99);
    t105 = (t101 & t103);
    t106 = (~(t104));
    t107 = (~(t105));
    t108 = *((unsigned int *)t86);
    *((unsigned int *)t86) = (t108 & t106);
    t109 = *((unsigned int *)t86);
    *((unsigned int *)t86) = (t109 & t107);
    t110 = *((unsigned int *)t80);
    *((unsigned int *)t80) = (t110 & t106);
    t111 = *((unsigned int *)t80);
    *((unsigned int *)t80) = (t111 & t107);
    goto LAB37;

LAB38:    xsi_vlogvar_assign_value(t112, t80, 0, *((unsigned int *)t113), 1);
    goto LAB39;

LAB40:    *((unsigned int *)t17) = 1;
    goto LAB43;

LAB42:    t18 = (t17 + 4);
    *((unsigned int *)t17) = 1;
    *((unsigned int *)t18) = 1;
    goto LAB43;

LAB44:    *((unsigned int *)t5) = 1;
    goto LAB47;

LAB49:    t39 = *((unsigned int *)t5);
    t40 = *((unsigned int *)t22);
    *((unsigned int *)t5) = (t39 | t40);
    t41 = *((unsigned int *)t21);
    t42 = *((unsigned int *)t22);
    *((unsigned int *)t21) = (t41 | t42);
    goto LAB48;

LAB50:    t59 = *((unsigned int *)t29);
    t60 = *((unsigned int *)t27);
    *((unsigned int *)t29) = (t59 | t60);
    t28 = (t7 + 4);
    t31 = (t5 + 4);
    t61 = *((unsigned int *)t7);
    t64 = (~(t61));
    t65 = *((unsigned int *)t28);
    t66 = (~(t65));
    t67 = *((unsigned int *)t5);
    t68 = (~(t67));
    t72 = *((unsigned int *)t31);
    t73 = (~(t72));
    t24 = (t64 & t66);
    t45 = (t68 & t73);
    t74 = (~(t24));
    t75 = (~(t45));
    t76 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t76 & t74);
    t77 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t77 & t75);
    t78 = *((unsigned int *)t29);
    *((unsigned int *)t29) = (t78 & t74);
    t79 = *((unsigned int *)t29);
    *((unsigned int *)t29) = (t79 & t75);
    goto LAB52;

LAB53:    xsi_vlogvar_assign_value(t36, t29, 0, *((unsigned int *)t30), 1);
    goto LAB54;

LAB55:    t34 = *((unsigned int *)t5);
    t35 = *((unsigned int *)t19);
    *((unsigned int *)t5) = (t34 | t35);
    goto LAB57;

}

static void NetDecl_72_0(char *t0)
{
    char t4[8];
    char *t1;
    char *t2;
    char *t3;
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

LAB0:    t1 = (t0 + 10760U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(72, ng0);
    t2 = ((char*)((ng3)));
    t3 = ((char*)((ng3)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_lshift(t4, 32, t2, 32, t3, 32);
    t5 = (t0 + 16112);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    memset(t9, 0, 8);
    t10 = 3U;
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
    xsi_driver_vfirst_trans(t5, 0, 1U);

LAB1:    return;
}

static void NetDecl_73_1(char *t0)
{
    char t5[8];
    char t6[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    unsigned int t15;
    unsigned int t16;
    char *t17;
    unsigned int t18;
    unsigned int t19;

LAB0:    t1 = (t0 + 11008U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(73, ng0);
    t2 = ((char*)((ng3)));
    t3 = ((char*)((ng3)));
    t4 = ((char*)((ng2)));
    memset(t5, 0, 8);
    xsi_vlog_unsigned_minus(t5, 32, t3, 32, t4, 32);
    memset(t6, 0, 8);
    xsi_vlog_unsigned_lshift(t6, 32, t2, 32, t5, 32);
    t7 = (t0 + 16176);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    t10 = (t9 + 56U);
    t11 = *((char **)t10);
    memset(t11, 0, 8);
    t12 = 1U;
    t13 = t12;
    t14 = (t6 + 4);
    t15 = *((unsigned int *)t6);
    t12 = (t12 & t15);
    t16 = *((unsigned int *)t14);
    t13 = (t13 & t16);
    t17 = (t11 + 4);
    t18 = *((unsigned int *)t11);
    *((unsigned int *)t11) = (t18 | t12);
    t19 = *((unsigned int *)t17);
    *((unsigned int *)t17) = (t19 | t13);
    xsi_driver_vfirst_trans(t7, 0, 0U);

LAB1:    return;
}

static void NetDecl_74_2(char *t0)
{
    char t4[8];
    char t6[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    char *t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    char *t20;
    char *t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    int t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    char *t35;
    char *t36;
    char *t37;
    char *t38;
    unsigned int t39;
    unsigned int t40;
    char *t41;
    unsigned int t42;
    unsigned int t43;
    char *t44;
    unsigned int t45;
    unsigned int t46;
    char *t47;

LAB0:    t1 = (t0 + 11256U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(74, ng0);
    t2 = (t0 + 4488U);
    t3 = *((char **)t2);
    t2 = (t0 + 4648U);
    t5 = *((char **)t2);
    t2 = ((char*)((ng5)));
    xsi_vlogtype_concat(t4, 2, 2, 2U, t2, 1, t5, 1);
    t7 = *((unsigned int *)t3);
    t8 = *((unsigned int *)t4);
    t9 = (t7 | t8);
    *((unsigned int *)t6) = t9;
    t10 = (t3 + 4);
    t11 = (t4 + 4);
    t12 = (t6 + 4);
    t13 = *((unsigned int *)t10);
    t14 = *((unsigned int *)t11);
    t15 = (t13 | t14);
    *((unsigned int *)t12) = t15;
    t16 = *((unsigned int *)t12);
    t17 = (t16 != 0);
    if (t17 == 1)
        goto LAB4;

LAB5:
LAB6:    t34 = (t0 + 16240);
    t35 = (t34 + 56U);
    t36 = *((char **)t35);
    t37 = (t36 + 56U);
    t38 = *((char **)t37);
    memset(t38, 0, 8);
    t39 = 3U;
    t40 = t39;
    t41 = (t6 + 4);
    t42 = *((unsigned int *)t6);
    t39 = (t39 & t42);
    t43 = *((unsigned int *)t41);
    t40 = (t40 & t43);
    t44 = (t38 + 4);
    t45 = *((unsigned int *)t38);
    *((unsigned int *)t38) = (t45 | t39);
    t46 = *((unsigned int *)t44);
    *((unsigned int *)t44) = (t46 | t40);
    xsi_driver_vfirst_trans(t34, 0, 1U);
    t47 = (t0 + 15792);
    *((int *)t47) = 1;

LAB1:    return;
LAB4:    t18 = *((unsigned int *)t6);
    t19 = *((unsigned int *)t12);
    *((unsigned int *)t6) = (t18 | t19);
    t20 = (t3 + 4);
    t21 = (t4 + 4);
    t22 = *((unsigned int *)t20);
    t23 = (~(t22));
    t24 = *((unsigned int *)t3);
    t25 = (t24 & t23);
    t26 = *((unsigned int *)t21);
    t27 = (~(t26));
    t28 = *((unsigned int *)t4);
    t29 = (t28 & t27);
    t30 = (~(t25));
    t31 = (~(t29));
    t32 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t32 & t30);
    t33 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t33 & t31);
    goto LAB6;

}

static void Cont_102_3(char *t0)
{
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;

LAB0:    t1 = (t0 + 11504U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(102, ng0);
    t2 = (t0 + 3208U);
    t3 = *((char **)t2);
    t2 = (t0 + 16304);
    t4 = (t2 + 56U);
    t5 = *((char **)t4);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t7, 0, 8);
    t8 = 1U;
    t9 = t8;
    t10 = (t3 + 4);
    t11 = *((unsigned int *)t3);
    t8 = (t8 & t11);
    t12 = *((unsigned int *)t10);
    t9 = (t9 & t12);
    t13 = (t7 + 4);
    t14 = *((unsigned int *)t7);
    *((unsigned int *)t7) = (t14 | t8);
    t15 = *((unsigned int *)t13);
    *((unsigned int *)t13) = (t15 | t9);
    xsi_driver_vfirst_trans(t2, 0, 0);
    t16 = (t0 + 15808);
    *((int *)t16) = 1;

LAB1:    return;
}

static void Cont_105_4(char *t0)
{
    char t5[16];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t11;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;

LAB0:    t1 = (t0 + 11752U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(105, ng0);
    t2 = (t0 + 6328);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t6 = (t0 + 6328);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = (t0 + 6328);
    t10 = (t9 + 64U);
    t11 = *((char **)t10);
    t12 = (t0 + 5928U);
    t13 = *((char **)t12);
    xsi_vlog_generic_get_array_select_value(t5, 64, t4, t8, t11, 2, 1, t13, 1, 2);
    t12 = (t0 + 16368);
    t14 = (t12 + 56U);
    t15 = *((char **)t14);
    t16 = (t15 + 56U);
    t17 = *((char **)t16);
    xsi_vlog_bit_copy(t17, 0, t5, 0, 64);
    xsi_driver_vfirst_trans(t12, 0, 63);
    t18 = (t0 + 15824);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Cont_106_5(char *t0)
{
    char t3[8];
    char t4[8];
    char *t1;
    char *t2;
    char *t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    char *t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    char *t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;

LAB0:    t1 = (t0 + 12000U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(106, ng0);
    t2 = ((char*)((ng3)));
    memset(t4, 0, 8);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t2);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB4;

LAB5:    if (*((unsigned int *)t5) != 0)
        goto LAB6;

LAB7:    t12 = (t4 + 4);
    t13 = *((unsigned int *)t4);
    t14 = *((unsigned int *)t12);
    t15 = (t13 || t14);
    if (t15 > 0)
        goto LAB8;

LAB9:    t19 = *((unsigned int *)t4);
    t20 = (~(t19));
    t21 = *((unsigned int *)t12);
    t22 = (t20 || t21);
    if (t22 > 0)
        goto LAB10;

LAB11:    if (*((unsigned int *)t12) > 0)
        goto LAB12;

LAB13:    if (*((unsigned int *)t4) > 0)
        goto LAB14;

LAB15:    memcpy(t3, t24, 8);

LAB16:    t23 = (t0 + 16432);
    t25 = (t23 + 56U);
    t26 = *((char **)t25);
    t27 = (t26 + 56U);
    t28 = *((char **)t27);
    memset(t28, 0, 8);
    t29 = 1U;
    t30 = t29;
    t31 = (t3 + 4);
    t32 = *((unsigned int *)t3);
    t29 = (t29 & t32);
    t33 = *((unsigned int *)t31);
    t30 = (t30 & t33);
    t34 = (t28 + 4);
    t35 = *((unsigned int *)t28);
    *((unsigned int *)t28) = (t35 | t29);
    t36 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t36 | t30);
    xsi_driver_vfirst_trans(t23, 0, 0);
    t37 = (t0 + 15840);
    *((int *)t37) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t4) = 1;
    goto LAB7;

LAB6:    t11 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB7;

LAB8:    t16 = (t0 + 7448);
    t17 = (t16 + 56U);
    t18 = *((char **)t17);
    goto LAB9;

LAB10:    t23 = (t0 + 5288U);
    t24 = *((char **)t23);
    goto LAB11;

LAB12:    xsi_vlog_unsigned_bit_combine(t3, 1, t18, 1, t24, 1);
    goto LAB16;

LAB14:    memcpy(t3, t18, 8);
    goto LAB16;

}

static void Cont_107_6(char *t0)
{
    char t3[8];
    char t4[8];
    char *t1;
    char *t2;
    char *t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    char *t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    char *t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;

LAB0:    t1 = (t0 + 12248U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(107, ng0);
    t2 = ((char*)((ng3)));
    memset(t4, 0, 8);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t2);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB4;

LAB5:    if (*((unsigned int *)t5) != 0)
        goto LAB6;

LAB7:    t12 = (t4 + 4);
    t13 = *((unsigned int *)t4);
    t14 = *((unsigned int *)t12);
    t15 = (t13 || t14);
    if (t15 > 0)
        goto LAB8;

LAB9:    t19 = *((unsigned int *)t4);
    t20 = (~(t19));
    t21 = *((unsigned int *)t12);
    t22 = (t20 || t21);
    if (t22 > 0)
        goto LAB10;

LAB11:    if (*((unsigned int *)t12) > 0)
        goto LAB12;

LAB13:    if (*((unsigned int *)t4) > 0)
        goto LAB14;

LAB15:    memcpy(t3, t24, 8);

LAB16:    t23 = (t0 + 16496);
    t25 = (t23 + 56U);
    t26 = *((char **)t25);
    t27 = (t26 + 56U);
    t28 = *((char **)t27);
    memset(t28, 0, 8);
    t29 = 1U;
    t30 = t29;
    t31 = (t3 + 4);
    t32 = *((unsigned int *)t3);
    t29 = (t29 & t32);
    t33 = *((unsigned int *)t31);
    t30 = (t30 & t33);
    t34 = (t28 + 4);
    t35 = *((unsigned int *)t28);
    *((unsigned int *)t28) = (t35 | t29);
    t36 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t36 | t30);
    xsi_driver_vfirst_trans(t23, 0, 0);
    t37 = (t0 + 15856);
    *((int *)t37) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t4) = 1;
    goto LAB7;

LAB6:    t11 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB7;

LAB8:    t16 = (t0 + 6808);
    t17 = (t16 + 56U);
    t18 = *((char **)t17);
    goto LAB9;

LAB10:    t23 = (t0 + 4968U);
    t24 = *((char **)t23);
    goto LAB11;

LAB12:    xsi_vlog_unsigned_bit_combine(t3, 1, t18, 1, t24, 1);
    goto LAB16;

LAB14:    memcpy(t3, t18, 8);
    goto LAB16;

}

static void Cont_111_7(char *t0)
{
    char t3[8];
    char t11[8];
    char t22[8];
    char t53[8];
    char *t1;
    char *t2;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    char *t26;
    char *t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;
    unsigned int t34;
    char *t35;
    char *t36;
    unsigned int t37;
    unsigned int t38;
    unsigned int t39;
    unsigned int t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    int t45;
    int t46;
    unsigned int t47;
    unsigned int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t54;
    unsigned int t55;
    unsigned int t56;
    char *t57;
    char *t58;
    char *t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    unsigned int t64;
    unsigned int t65;
    unsigned int t66;
    char *t67;
    char *t68;
    char *t69;
    char *t70;
    char *t71;
    unsigned int t72;
    unsigned int t73;
    char *t74;
    unsigned int t75;
    unsigned int t76;
    char *t77;
    unsigned int t78;
    unsigned int t79;
    char *t80;

LAB0:    t1 = (t0 + 12496U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(111, ng0);
    t2 = (t0 + 6488);
    t4 = (t2 + 56U);
    t5 = *((char **)t4);
    t6 = (t0 + 6488);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = ((char*)((ng5)));
    t10 = ((char*)((ng1)));
    xsi_vlog_generic_get_part_select_value(t3, 1, t5, t8, 2, t9, 32U, 2, t10, 32U, 1);
    t12 = (t0 + 6488);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    t15 = (t0 + 6488);
    t16 = (t15 + 72U);
    t17 = *((char **)t16);
    t18 = ((char*)((ng3)));
    t19 = ((char*)((ng2)));
    xsi_vlog_generic_get_part_select_value(t11, 1, t14, t17, 2, t18, 32U, 2, t19, 32U, 1);
    t20 = (t0 + 4648U);
    t21 = *((char **)t20);
    t23 = *((unsigned int *)t11);
    t24 = *((unsigned int *)t21);
    t25 = (t23 & t24);
    *((unsigned int *)t22) = t25;
    t20 = (t11 + 4);
    t26 = (t21 + 4);
    t27 = (t22 + 4);
    t28 = *((unsigned int *)t20);
    t29 = *((unsigned int *)t26);
    t30 = (t28 | t29);
    *((unsigned int *)t27) = t30;
    t31 = *((unsigned int *)t27);
    t32 = (t31 != 0);
    if (t32 == 1)
        goto LAB4;

LAB5:
LAB6:    t54 = *((unsigned int *)t3);
    t55 = *((unsigned int *)t22);
    t56 = (t54 ^ t55);
    *((unsigned int *)t53) = t56;
    t57 = (t3 + 4);
    t58 = (t22 + 4);
    t59 = (t53 + 4);
    t60 = *((unsigned int *)t57);
    t61 = *((unsigned int *)t58);
    t62 = (t60 | t61);
    *((unsigned int *)t59) = t62;
    t63 = *((unsigned int *)t59);
    t64 = (t63 != 0);
    if (t64 == 1)
        goto LAB7;

LAB8:
LAB9:    t67 = (t0 + 16560);
    t68 = (t67 + 56U);
    t69 = *((char **)t68);
    t70 = (t69 + 56U);
    t71 = *((char **)t70);
    memset(t71, 0, 8);
    t72 = 1U;
    t73 = t72;
    t74 = (t53 + 4);
    t75 = *((unsigned int *)t53);
    t72 = (t72 & t75);
    t76 = *((unsigned int *)t74);
    t73 = (t73 & t76);
    t77 = (t71 + 4);
    t78 = *((unsigned int *)t71);
    *((unsigned int *)t71) = (t78 | t72);
    t79 = *((unsigned int *)t77);
    *((unsigned int *)t77) = (t79 | t73);
    xsi_driver_vfirst_trans(t67, 0, 0);
    t80 = (t0 + 15872);
    *((int *)t80) = 1;

LAB1:    return;
LAB4:    t33 = *((unsigned int *)t22);
    t34 = *((unsigned int *)t27);
    *((unsigned int *)t22) = (t33 | t34);
    t35 = (t11 + 4);
    t36 = (t21 + 4);
    t37 = *((unsigned int *)t11);
    t38 = (~(t37));
    t39 = *((unsigned int *)t35);
    t40 = (~(t39));
    t41 = *((unsigned int *)t21);
    t42 = (~(t41));
    t43 = *((unsigned int *)t36);
    t44 = (~(t43));
    t45 = (t38 & t40);
    t46 = (t42 & t44);
    t47 = (~(t45));
    t48 = (~(t46));
    t49 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t49 & t47);
    t50 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t50 & t48);
    t51 = *((unsigned int *)t22);
    *((unsigned int *)t22) = (t51 & t47);
    t52 = *((unsigned int *)t22);
    *((unsigned int *)t22) = (t52 & t48);
    goto LAB6;

LAB7:    t65 = *((unsigned int *)t53);
    t66 = *((unsigned int *)t59);
    *((unsigned int *)t53) = (t65 | t66);
    goto LAB9;

}

static void Cont_112_8(char *t0)
{
    char t3[8];
    char t11[8];
    char t22[8];
    char t53[8];
    char *t1;
    char *t2;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    char *t26;
    char *t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;
    unsigned int t34;
    char *t35;
    char *t36;
    unsigned int t37;
    unsigned int t38;
    unsigned int t39;
    unsigned int t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    int t45;
    int t46;
    unsigned int t47;
    unsigned int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t54;
    unsigned int t55;
    unsigned int t56;
    char *t57;
    char *t58;
    char *t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    unsigned int t64;
    unsigned int t65;
    unsigned int t66;
    char *t67;
    char *t68;
    char *t69;
    char *t70;
    char *t71;
    unsigned int t72;
    unsigned int t73;
    char *t74;
    unsigned int t75;
    unsigned int t76;
    char *t77;
    unsigned int t78;
    unsigned int t79;
    char *t80;

LAB0:    t1 = (t0 + 12744U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(112, ng0);
    t2 = (t0 + 7128);
    t4 = (t2 + 56U);
    t5 = *((char **)t4);
    t6 = (t0 + 7128);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = ((char*)((ng5)));
    t10 = ((char*)((ng1)));
    xsi_vlog_generic_get_part_select_value(t3, 1, t5, t8, 2, t9, 32U, 2, t10, 32U, 1);
    t12 = (t0 + 7128);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    t15 = (t0 + 7128);
    t16 = (t15 + 72U);
    t17 = *((char **)t16);
    t18 = ((char*)((ng3)));
    t19 = ((char*)((ng2)));
    xsi_vlog_generic_get_part_select_value(t11, 1, t14, t17, 2, t18, 32U, 2, t19, 32U, 1);
    t20 = (t0 + 4648U);
    t21 = *((char **)t20);
    t23 = *((unsigned int *)t11);
    t24 = *((unsigned int *)t21);
    t25 = (t23 & t24);
    *((unsigned int *)t22) = t25;
    t20 = (t11 + 4);
    t26 = (t21 + 4);
    t27 = (t22 + 4);
    t28 = *((unsigned int *)t20);
    t29 = *((unsigned int *)t26);
    t30 = (t28 | t29);
    *((unsigned int *)t27) = t30;
    t31 = *((unsigned int *)t27);
    t32 = (t31 != 0);
    if (t32 == 1)
        goto LAB4;

LAB5:
LAB6:    t54 = *((unsigned int *)t3);
    t55 = *((unsigned int *)t22);
    t56 = (t54 ^ t55);
    *((unsigned int *)t53) = t56;
    t57 = (t3 + 4);
    t58 = (t22 + 4);
    t59 = (t53 + 4);
    t60 = *((unsigned int *)t57);
    t61 = *((unsigned int *)t58);
    t62 = (t60 | t61);
    *((unsigned int *)t59) = t62;
    t63 = *((unsigned int *)t59);
    t64 = (t63 != 0);
    if (t64 == 1)
        goto LAB7;

LAB8:
LAB9:    t67 = (t0 + 16624);
    t68 = (t67 + 56U);
    t69 = *((char **)t68);
    t70 = (t69 + 56U);
    t71 = *((char **)t70);
    memset(t71, 0, 8);
    t72 = 1U;
    t73 = t72;
    t74 = (t53 + 4);
    t75 = *((unsigned int *)t53);
    t72 = (t72 & t75);
    t76 = *((unsigned int *)t74);
    t73 = (t73 & t76);
    t77 = (t71 + 4);
    t78 = *((unsigned int *)t71);
    *((unsigned int *)t71) = (t78 | t72);
    t79 = *((unsigned int *)t77);
    *((unsigned int *)t77) = (t79 | t73);
    xsi_driver_vfirst_trans(t67, 0, 0);
    t80 = (t0 + 15888);
    *((int *)t80) = 1;

LAB1:    return;
LAB4:    t33 = *((unsigned int *)t22);
    t34 = *((unsigned int *)t27);
    *((unsigned int *)t22) = (t33 | t34);
    t35 = (t11 + 4);
    t36 = (t21 + 4);
    t37 = *((unsigned int *)t11);
    t38 = (~(t37));
    t39 = *((unsigned int *)t35);
    t40 = (~(t39));
    t41 = *((unsigned int *)t21);
    t42 = (~(t41));
    t43 = *((unsigned int *)t36);
    t44 = (~(t43));
    t45 = (t38 & t40);
    t46 = (t42 & t44);
    t47 = (~(t45));
    t48 = (~(t46));
    t49 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t49 & t47);
    t50 = *((unsigned int *)t27);
    *((unsigned int *)t27) = (t50 & t48);
    t51 = *((unsigned int *)t22);
    *((unsigned int *)t22) = (t51 & t47);
    t52 = *((unsigned int *)t22);
    *((unsigned int *)t22) = (t52 & t48);
    goto LAB6;

LAB7:    t65 = *((unsigned int *)t53);
    t66 = *((unsigned int *)t59);
    *((unsigned int *)t53) = (t65 | t66);
    goto LAB9;

}

static void Always_115_9(char *t0)
{
    char t13[8];
    char t14[8];
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
    char *t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;
    unsigned int t23;
    int t24;
    char *t25;
    unsigned int t26;
    int t27;
    int t28;
    unsigned int t29;
    unsigned int t30;
    int t31;
    int t32;

LAB0:    t1 = (t0 + 12992U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(115, ng0);
    t2 = (t0 + 15904);
    *((int *)t2) = 1;
    t3 = (t0 + 13024);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(116, ng0);

LAB5:    xsi_set_current_line(117, ng0);
    t4 = (t0 + 3368U);
    t5 = *((char **)t4);
    t4 = (t5 + 4);
    t6 = *((unsigned int *)t4);
    t7 = (~(t6));
    t8 = *((unsigned int *)t5);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB6;

LAB7:
LAB8:    goto LAB2;

LAB6:    xsi_set_current_line(118, ng0);
    t11 = (t0 + 3528U);
    t12 = *((char **)t11);
    t11 = (t0 + 6328);
    t15 = (t0 + 6328);
    t16 = (t15 + 72U);
    t17 = *((char **)t16);
    t18 = (t0 + 6328);
    t19 = (t18 + 64U);
    t20 = *((char **)t19);
    t21 = (t0 + 5768U);
    t22 = *((char **)t21);
    xsi_vlog_generic_convert_array_indices(t13, t14, t17, t20, 2, 1, t22, 1, 2);
    t21 = (t13 + 4);
    t23 = *((unsigned int *)t21);
    t24 = (!(t23));
    t25 = (t14 + 4);
    t26 = *((unsigned int *)t25);
    t27 = (!(t26));
    t28 = (t24 && t27);
    if (t28 == 1)
        goto LAB9;

LAB10:    goto LAB8;

LAB9:    t29 = *((unsigned int *)t13);
    t30 = *((unsigned int *)t14);
    t31 = (t29 - t30);
    t32 = (t31 + 1);
    xsi_vlogvar_wait_assign_value(t11, t12, 0, *((unsigned int *)t14), t32, 0LL);
    goto LAB10;

}

static void Cont_123_10(char *t0)
{
    char t7[8];
    char t23[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    char *t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;
    unsigned int t34;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    char *t38;
    char *t39;
    char *t40;
    char *t41;
    char *t42;
    char *t43;
    unsigned int t44;
    unsigned int t45;
    char *t46;
    unsigned int t47;
    unsigned int t48;
    char *t49;
    unsigned int t50;
    unsigned int t51;
    char *t52;

LAB0:    t1 = (t0 + 13240U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(123, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 4808U);
    t6 = *((char **)t5);
    t8 = *((unsigned int *)t4);
    t9 = *((unsigned int *)t6);
    t10 = (t8 ^ t9);
    *((unsigned int *)t7) = t10;
    t5 = (t4 + 4);
    t11 = (t6 + 4);
    t12 = (t7 + 4);
    t13 = *((unsigned int *)t5);
    t14 = *((unsigned int *)t11);
    t15 = (t13 | t14);
    *((unsigned int *)t12) = t15;
    t16 = *((unsigned int *)t12);
    t17 = (t16 != 0);
    if (t17 == 1)
        goto LAB4;

LAB5:
LAB6:    t20 = (t0 + 8248);
    t21 = (t20 + 56U);
    t22 = *((char **)t21);
    memset(t23, 0, 8);
    t24 = (t7 + 4);
    t25 = (t22 + 4);
    t26 = *((unsigned int *)t7);
    t27 = *((unsigned int *)t22);
    t28 = (t26 ^ t27);
    t29 = *((unsigned int *)t24);
    t30 = *((unsigned int *)t25);
    t31 = (t29 ^ t30);
    t32 = (t28 | t31);
    t33 = *((unsigned int *)t24);
    t34 = *((unsigned int *)t25);
    t35 = (t33 | t34);
    t36 = (~(t35));
    t37 = (t32 & t36);
    if (t37 != 0)
        goto LAB8;

LAB7:    if (t35 != 0)
        goto LAB9;

LAB10:    t39 = (t0 + 16688);
    t40 = (t39 + 56U);
    t41 = *((char **)t40);
    t42 = (t41 + 56U);
    t43 = *((char **)t42);
    memset(t43, 0, 8);
    t44 = 1U;
    t45 = t44;
    t46 = (t23 + 4);
    t47 = *((unsigned int *)t23);
    t44 = (t44 & t47);
    t48 = *((unsigned int *)t46);
    t45 = (t45 & t48);
    t49 = (t43 + 4);
    t50 = *((unsigned int *)t43);
    *((unsigned int *)t43) = (t50 | t44);
    t51 = *((unsigned int *)t49);
    *((unsigned int *)t49) = (t51 | t45);
    xsi_driver_vfirst_trans(t39, 0, 0);
    t52 = (t0 + 15920);
    *((int *)t52) = 1;

LAB1:    return;
LAB4:    t18 = *((unsigned int *)t7);
    t19 = *((unsigned int *)t12);
    *((unsigned int *)t7) = (t18 | t19);
    goto LAB6;

LAB8:    *((unsigned int *)t23) = 1;
    goto LAB10;

LAB9:    t38 = (t23 + 4);
    *((unsigned int *)t23) = 1;
    *((unsigned int *)t38) = 1;
    goto LAB10;

}

static void Cont_124_11(char *t0)
{
    char t7[8];
    char t23[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    char *t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    char *t20;
    char *t21;
    char *t22;
    char *t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;
    unsigned int t34;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    char *t38;
    char *t39;
    char *t40;
    char *t41;
    char *t42;
    char *t43;
    unsigned int t44;
    unsigned int t45;
    char *t46;
    unsigned int t47;
    unsigned int t48;
    char *t49;
    unsigned int t50;
    unsigned int t51;
    char *t52;

LAB0:    t1 = (t0 + 13488U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(124, ng0);
    t2 = (t0 + 6648);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 4808U);
    t6 = *((char **)t5);
    t8 = *((unsigned int *)t4);
    t9 = *((unsigned int *)t6);
    t10 = (t8 ^ t9);
    *((unsigned int *)t7) = t10;
    t5 = (t4 + 4);
    t11 = (t6 + 4);
    t12 = (t7 + 4);
    t13 = *((unsigned int *)t5);
    t14 = *((unsigned int *)t11);
    t15 = (t13 | t14);
    *((unsigned int *)t12) = t15;
    t16 = *((unsigned int *)t12);
    t17 = (t16 != 0);
    if (t17 == 1)
        goto LAB4;

LAB5:
LAB6:    t20 = (t0 + 8248);
    t21 = (t20 + 56U);
    t22 = *((char **)t21);
    memset(t23, 0, 8);
    t24 = (t7 + 4);
    t25 = (t22 + 4);
    t26 = *((unsigned int *)t7);
    t27 = *((unsigned int *)t22);
    t28 = (t26 ^ t27);
    t29 = *((unsigned int *)t24);
    t30 = *((unsigned int *)t25);
    t31 = (t29 ^ t30);
    t32 = (t28 | t31);
    t33 = *((unsigned int *)t24);
    t34 = *((unsigned int *)t25);
    t35 = (t33 | t34);
    t36 = (~(t35));
    t37 = (t32 & t36);
    if (t37 != 0)
        goto LAB8;

LAB7:    if (t35 != 0)
        goto LAB9;

LAB10:    t39 = (t0 + 16752);
    t40 = (t39 + 56U);
    t41 = *((char **)t40);
    t42 = (t41 + 56U);
    t43 = *((char **)t42);
    memset(t43, 0, 8);
    t44 = 1U;
    t45 = t44;
    t46 = (t23 + 4);
    t47 = *((unsigned int *)t23);
    t44 = (t44 & t47);
    t48 = *((unsigned int *)t46);
    t45 = (t45 & t48);
    t49 = (t43 + 4);
    t50 = *((unsigned int *)t43);
    *((unsigned int *)t43) = (t50 | t44);
    t51 = *((unsigned int *)t49);
    *((unsigned int *)t49) = (t51 | t45);
    xsi_driver_vfirst_trans(t39, 0, 0);
    t52 = (t0 + 15936);
    *((int *)t52) = 1;

LAB1:    return;
LAB4:    t18 = *((unsigned int *)t7);
    t19 = *((unsigned int *)t12);
    *((unsigned int *)t7) = (t18 | t19);
    goto LAB6;

LAB8:    *((unsigned int *)t23) = 1;
    goto LAB10;

LAB9:    t38 = (t23 + 4);
    *((unsigned int *)t23) = 1;
    *((unsigned int *)t38) = 1;
    goto LAB10;

}

static void Always_126_12(char *t0)
{
    char t6[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    char *t21;
    char *t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;
    char *t37;
    char *t38;
    char *t39;
    char *t40;
    int t41;
    char *t42;
    char *t43;
    char *t44;
    char *t45;
    char *t46;
    char *t47;
    char *t48;

LAB0:    t1 = (t0 + 13736U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(126, ng0);
    t2 = (t0 + 15952);
    *((int *)t2) = 1;
    t3 = (t0 + 13768);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(127, ng0);

LAB5:    xsi_set_current_line(128, ng0);
    t4 = (t0 + 3208U);
    t5 = *((char **)t4);
    t4 = ((char*)((ng1)));
    memset(t6, 0, 8);
    t7 = (t5 + 4);
    t8 = (t4 + 4);
    t9 = *((unsigned int *)t5);
    t10 = *((unsigned int *)t4);
    t11 = (t9 ^ t10);
    t12 = *((unsigned int *)t7);
    t13 = *((unsigned int *)t8);
    t14 = (t12 ^ t13);
    t15 = (t11 | t14);
    t16 = *((unsigned int *)t7);
    t17 = *((unsigned int *)t8);
    t18 = (t16 | t17);
    t19 = (~(t18));
    t20 = (t15 & t19);
    if (t20 != 0)
        goto LAB9;

LAB6:    if (t18 != 0)
        goto LAB8;

LAB7:    *((unsigned int *)t6) = 1;

LAB9:    t22 = (t6 + 4);
    t23 = *((unsigned int *)t22);
    t24 = (~(t23));
    t25 = *((unsigned int *)t6);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(136, ng0);

LAB14:    xsi_set_current_line(137, ng0);
    t2 = (t0 + 3368U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t9 = *((unsigned int *)t2);
    t10 = (~(t9));
    t11 = *((unsigned int *)t3);
    t12 = (t11 & t10);
    t13 = (t12 != 0);
    if (t13 > 0)
        goto LAB15;

LAB16:    xsi_set_current_line(145, ng0);

LAB28:    xsi_set_current_line(146, ng0);
    t2 = (t0 + 4968U);
    t3 = *((char **)t2);
    t2 = (t0 + 6808);
    xsi_vlogvar_wait_assign_value(t2, t3, 0, 0, 1, 0LL);

LAB17:
LAB12:    goto LAB2;

LAB8:    t21 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t21) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(129, ng0);

LAB13:    xsi_set_current_line(130, ng0);
    t28 = ((char*)((ng5)));
    t29 = (t0 + 6488);
    xsi_vlogvar_wait_assign_value(t29, t28, 0, 0, 2, 0LL);
    xsi_set_current_line(131, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 6648);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 2, 0LL);
    xsi_set_current_line(132, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 6968);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(133, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 6808);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB12;

LAB15:    xsi_set_current_line(138, ng0);

LAB18:    xsi_set_current_line(139, ng0);
    t4 = (t0 + 6648);
    t5 = (t4 + 56U);
    t7 = *((char **)t5);
    t8 = (t0 + 6968);
    t21 = (t8 + 56U);
    t22 = *((char **)t21);
    t28 = (t0 + 13544);
    t29 = (t0 + 2416);
    t30 = xsi_create_subprogram_invocation(t28, 0, t0, t29, 0, 0);
    t31 = (t0 + 9208);
    xsi_vlogvar_assign_value(t31, t7, 0, 0, 2);
    t32 = (t0 + 9368);
    xsi_vlogvar_assign_value(t32, t22, 0, 0, 1);

LAB19:    t33 = (t0 + 13640);
    t34 = *((char **)t33);
    t35 = (t34 + 80U);
    t36 = *((char **)t35);
    t37 = (t36 + 272U);
    t38 = *((char **)t37);
    t39 = (t38 + 0U);
    t40 = *((char **)t39);
    t41 = ((int  (*)(char *, char *))t40)(t0, t34);
    if (t41 != 0)
        goto LAB21;

LAB20:    t34 = (t0 + 13640);
    t42 = *((char **)t34);
    t34 = (t0 + 9048);
    t43 = (t34 + 56U);
    t44 = *((char **)t43);
    memcpy(t6, t44, 8);
    t45 = (t0 + 2416);
    t46 = (t0 + 13544);
    t47 = 0;
    xsi_delete_subprogram_invocation(t45, t42, t0, t46, t47);
    t48 = (t0 + 6648);
    xsi_vlogvar_wait_assign_value(t48, t6, 0, 0, 2, 0LL);
    xsi_set_current_line(140, ng0);
    t2 = (t0 + 6648);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 6488);
    xsi_vlogvar_wait_assign_value(t5, t4, 0, 0, 2, 0LL);
    xsi_set_current_line(141, ng0);
    t2 = (t0 + 6968);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t6, 0, 8);
    t5 = (t4 + 4);
    t9 = *((unsigned int *)t5);
    t10 = (~(t9));
    t11 = *((unsigned int *)t4);
    t12 = (t11 & t10);
    t13 = (t12 & 1U);
    if (t13 != 0)
        goto LAB25;

LAB23:    if (*((unsigned int *)t5) == 0)
        goto LAB22;

LAB24:    t7 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t7) = 1;

LAB25:    t8 = (t6 + 4);
    t21 = (t4 + 4);
    t14 = *((unsigned int *)t4);
    t15 = (~(t14));
    *((unsigned int *)t6) = t15;
    *((unsigned int *)t8) = 0;
    if (*((unsigned int *)t21) != 0)
        goto LAB27;

LAB26:    t20 = *((unsigned int *)t6);
    *((unsigned int *)t6) = (t20 & 1U);
    t23 = *((unsigned int *)t8);
    *((unsigned int *)t8) = (t23 & 1U);
    t22 = (t0 + 6968);
    xsi_vlogvar_wait_assign_value(t22, t6, 0, 0, 1, 0LL);
    xsi_set_current_line(142, ng0);
    t2 = (t0 + 5128U);
    t3 = *((char **)t2);
    t2 = (t0 + 6808);
    xsi_vlogvar_wait_assign_value(t2, t3, 0, 0, 1, 0LL);
    goto LAB17;

LAB21:    t33 = (t0 + 13736U);
    *((char **)t33) = &&LAB19;
    goto LAB1;

LAB22:    *((unsigned int *)t6) = 1;
    goto LAB25;

LAB27:    t16 = *((unsigned int *)t6);
    t17 = *((unsigned int *)t21);
    *((unsigned int *)t6) = (t16 | t17);
    t18 = *((unsigned int *)t8);
    t19 = *((unsigned int *)t21);
    *((unsigned int *)t8) = (t18 | t19);
    goto LAB26;

}

static void Always_153_13(char *t0)
{
    char t6[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    char *t21;
    char *t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    char *t28;
    char *t29;

LAB0:    t1 = (t0 + 13984U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(153, ng0);
    t2 = (t0 + 15968);
    *((int *)t2) = 1;
    t3 = (t0 + 14016);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(154, ng0);

LAB5:    xsi_set_current_line(155, ng0);
    t4 = (t0 + 5608U);
    t5 = *((char **)t4);
    t4 = ((char*)((ng1)));
    memset(t6, 0, 8);
    t7 = (t5 + 4);
    t8 = (t4 + 4);
    t9 = *((unsigned int *)t5);
    t10 = *((unsigned int *)t4);
    t11 = (t9 ^ t10);
    t12 = *((unsigned int *)t7);
    t13 = *((unsigned int *)t8);
    t14 = (t12 ^ t13);
    t15 = (t11 | t14);
    t16 = *((unsigned int *)t7);
    t17 = *((unsigned int *)t8);
    t18 = (t16 | t17);
    t19 = (~(t18));
    t20 = (t15 & t19);
    if (t20 != 0)
        goto LAB9;

LAB6:    if (t18 != 0)
        goto LAB8;

LAB7:    *((unsigned int *)t6) = 1;

LAB9:    t22 = (t6 + 4);
    t23 = *((unsigned int *)t22);
    t24 = (~(t23));
    t25 = *((unsigned int *)t6);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(161, ng0);

LAB14:    xsi_set_current_line(162, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7768);
    xsi_vlogvar_wait_assign_value(t5, t4, 0, 0, 2, 0LL);
    xsi_set_current_line(163, ng0);
    t2 = (t0 + 7768);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7928);
    xsi_vlogvar_wait_assign_value(t5, t4, 0, 0, 2, 0LL);

LAB12:    goto LAB2;

LAB8:    t21 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t21) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(156, ng0);

LAB13:    xsi_set_current_line(157, ng0);
    t28 = ((char*)((ng5)));
    t29 = (t0 + 7768);
    xsi_vlogvar_wait_assign_value(t29, t28, 0, 0, 2, 0LL);
    xsi_set_current_line(158, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 7928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 2, 0LL);
    goto LAB12;

}

static void Cont_171_14(char *t0)
{
    char t8[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t9;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;

LAB0:    t1 = (t0 + 14232U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(171, ng0);
    t2 = (t0 + 7288);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7928);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t8, 0, 8);
    t9 = (t4 + 4);
    t10 = (t7 + 4);
    t11 = *((unsigned int *)t4);
    t12 = *((unsigned int *)t7);
    t13 = (t11 ^ t12);
    t14 = *((unsigned int *)t9);
    t15 = *((unsigned int *)t10);
    t16 = (t14 ^ t15);
    t17 = (t13 | t16);
    t18 = *((unsigned int *)t9);
    t19 = *((unsigned int *)t10);
    t20 = (t18 | t19);
    t21 = (~(t20));
    t22 = (t17 & t21);
    if (t22 != 0)
        goto LAB5;

LAB4:    if (t20 != 0)
        goto LAB6;

LAB7:    t24 = (t0 + 16816);
    t25 = (t24 + 56U);
    t26 = *((char **)t25);
    t27 = (t26 + 56U);
    t28 = *((char **)t27);
    memset(t28, 0, 8);
    t29 = 1U;
    t30 = t29;
    t31 = (t8 + 4);
    t32 = *((unsigned int *)t8);
    t29 = (t29 & t32);
    t33 = *((unsigned int *)t31);
    t30 = (t30 & t33);
    t34 = (t28 + 4);
    t35 = *((unsigned int *)t28);
    *((unsigned int *)t28) = (t35 | t29);
    t36 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t36 | t30);
    xsi_driver_vfirst_trans(t24, 0, 0);
    t37 = (t0 + 15984);
    *((int *)t37) = 1;

LAB1:    return;
LAB5:    *((unsigned int *)t8) = 1;
    goto LAB7;

LAB6:    t23 = (t8 + 4);
    *((unsigned int *)t8) = 1;
    *((unsigned int *)t23) = 1;
    goto LAB7;

}

static void Cont_172_15(char *t0)
{
    char t8[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    char *t9;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t35;
    unsigned int t36;
    char *t37;

LAB0:    t1 = (t0 + 14480U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(172, ng0);
    t2 = (t0 + 7128);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7928);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    memset(t8, 0, 8);
    t9 = (t4 + 4);
    t10 = (t7 + 4);
    t11 = *((unsigned int *)t4);
    t12 = *((unsigned int *)t7);
    t13 = (t11 ^ t12);
    t14 = *((unsigned int *)t9);
    t15 = *((unsigned int *)t10);
    t16 = (t14 ^ t15);
    t17 = (t13 | t16);
    t18 = *((unsigned int *)t9);
    t19 = *((unsigned int *)t10);
    t20 = (t18 | t19);
    t21 = (~(t20));
    t22 = (t17 & t21);
    if (t22 != 0)
        goto LAB5;

LAB4:    if (t20 != 0)
        goto LAB6;

LAB7:    t24 = (t0 + 16880);
    t25 = (t24 + 56U);
    t26 = *((char **)t25);
    t27 = (t26 + 56U);
    t28 = *((char **)t27);
    memset(t28, 0, 8);
    t29 = 1U;
    t30 = t29;
    t31 = (t8 + 4);
    t32 = *((unsigned int *)t8);
    t29 = (t29 & t32);
    t33 = *((unsigned int *)t31);
    t30 = (t30 & t33);
    t34 = (t28 + 4);
    t35 = *((unsigned int *)t28);
    *((unsigned int *)t28) = (t35 | t29);
    t36 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t36 | t30);
    xsi_driver_vfirst_trans(t24, 0, 0);
    t37 = (t0 + 16000);
    *((int *)t37) = 1;

LAB1:    return;
LAB5:    *((unsigned int *)t8) = 1;
    goto LAB7;

LAB6:    t23 = (t8 + 4);
    *((unsigned int *)t8) = 1;
    *((unsigned int *)t23) = 1;
    goto LAB7;

}

static void Always_174_16(char *t0)
{
    char t6[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    char *t21;
    char *t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    char *t28;
    char *t29;
    char *t30;
    char *t31;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;
    char *t37;
    char *t38;
    int t39;
    char *t40;
    char *t41;
    char *t42;
    char *t43;
    char *t44;
    char *t45;
    char *t46;

LAB0:    t1 = (t0 + 14728U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(174, ng0);
    t2 = (t0 + 16016);
    *((int *)t2) = 1;
    t3 = (t0 + 14760);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(175, ng0);

LAB5:    xsi_set_current_line(176, ng0);
    t4 = (t0 + 5608U);
    t5 = *((char **)t4);
    t4 = ((char*)((ng1)));
    memset(t6, 0, 8);
    t7 = (t5 + 4);
    t8 = (t4 + 4);
    t9 = *((unsigned int *)t5);
    t10 = *((unsigned int *)t4);
    t11 = (t9 ^ t10);
    t12 = *((unsigned int *)t7);
    t13 = *((unsigned int *)t8);
    t14 = (t12 ^ t13);
    t15 = (t11 | t14);
    t16 = *((unsigned int *)t7);
    t17 = *((unsigned int *)t8);
    t18 = (t16 | t17);
    t19 = (~(t18));
    t20 = (t15 & t19);
    if (t20 != 0)
        goto LAB9;

LAB6:    if (t18 != 0)
        goto LAB8;

LAB7:    *((unsigned int *)t6) = 1;

LAB9:    t22 = (t6 + 4);
    t23 = *((unsigned int *)t22);
    t24 = (~(t23));
    t25 = *((unsigned int *)t6);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(184, ng0);

LAB14:    xsi_set_current_line(185, ng0);
    t2 = (t0 + 4008U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t9 = *((unsigned int *)t2);
    t10 = (~(t9));
    t11 = *((unsigned int *)t3);
    t12 = (t11 & t10);
    t13 = (t12 != 0);
    if (t13 > 0)
        goto LAB15;

LAB16:    xsi_set_current_line(193, ng0);

LAB28:    xsi_set_current_line(194, ng0);
    t2 = (t0 + 5288U);
    t3 = *((char **)t2);
    t2 = (t0 + 7448);
    xsi_vlogvar_wait_assign_value(t2, t3, 0, 0, 1, 0LL);

LAB17:
LAB12:    goto LAB2;

LAB8:    t21 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t21) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(177, ng0);

LAB13:    xsi_set_current_line(178, ng0);
    t28 = ((char*)((ng5)));
    t29 = (t0 + 7128);
    xsi_vlogvar_wait_assign_value(t29, t28, 0, 0, 2, 0LL);
    xsi_set_current_line(179, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 7288);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 2, 0LL);
    xsi_set_current_line(180, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 7608);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(181, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 7448);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB12;

LAB15:    xsi_set_current_line(186, ng0);

LAB18:    xsi_set_current_line(187, ng0);
    t4 = (t0 + 7288);
    t5 = (t4 + 56U);
    t7 = *((char **)t5);
    t8 = (t0 + 7128);
    xsi_vlogvar_wait_assign_value(t8, t7, 0, 0, 2, 0LL);
    xsi_set_current_line(188, ng0);
    t2 = (t0 + 7288);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7608);
    t7 = (t5 + 56U);
    t8 = *((char **)t7);
    t21 = (t0 + 14536);
    t22 = (t0 + 2416);
    t28 = xsi_create_subprogram_invocation(t21, 0, t0, t22, 0, 0);
    t29 = (t0 + 9208);
    xsi_vlogvar_assign_value(t29, t4, 0, 0, 2);
    t30 = (t0 + 9368);
    xsi_vlogvar_assign_value(t30, t8, 0, 0, 1);

LAB19:    t31 = (t0 + 14632);
    t32 = *((char **)t31);
    t33 = (t32 + 80U);
    t34 = *((char **)t33);
    t35 = (t34 + 272U);
    t36 = *((char **)t35);
    t37 = (t36 + 0U);
    t38 = *((char **)t37);
    t39 = ((int  (*)(char *, char *))t38)(t0, t32);
    if (t39 != 0)
        goto LAB21;

LAB20:    t32 = (t0 + 14632);
    t40 = *((char **)t32);
    t32 = (t0 + 9048);
    t41 = (t32 + 56U);
    t42 = *((char **)t41);
    memcpy(t6, t42, 8);
    t43 = (t0 + 2416);
    t44 = (t0 + 14536);
    t45 = 0;
    xsi_delete_subprogram_invocation(t43, t40, t0, t44, t45);
    t46 = (t0 + 7288);
    xsi_vlogvar_wait_assign_value(t46, t6, 0, 0, 2, 0LL);
    xsi_set_current_line(189, ng0);
    t2 = (t0 + 7608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t6, 0, 8);
    t5 = (t4 + 4);
    t9 = *((unsigned int *)t5);
    t10 = (~(t9));
    t11 = *((unsigned int *)t4);
    t12 = (t11 & t10);
    t13 = (t12 & 1U);
    if (t13 != 0)
        goto LAB25;

LAB23:    if (*((unsigned int *)t5) == 0)
        goto LAB22;

LAB24:    t7 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t7) = 1;

LAB25:    t8 = (t6 + 4);
    t21 = (t4 + 4);
    t14 = *((unsigned int *)t4);
    t15 = (~(t14));
    *((unsigned int *)t6) = t15;
    *((unsigned int *)t8) = 0;
    if (*((unsigned int *)t21) != 0)
        goto LAB27;

LAB26:    t20 = *((unsigned int *)t6);
    *((unsigned int *)t6) = (t20 & 1U);
    t23 = *((unsigned int *)t8);
    *((unsigned int *)t8) = (t23 & 1U);
    t22 = (t0 + 7608);
    xsi_vlogvar_wait_assign_value(t22, t6, 0, 0, 1, 0LL);
    xsi_set_current_line(190, ng0);
    t2 = (t0 + 5448U);
    t3 = *((char **)t2);
    t2 = (t0 + 7448);
    xsi_vlogvar_wait_assign_value(t2, t3, 0, 0, 1, 0LL);
    goto LAB17;

LAB21:    t31 = (t0 + 14728U);
    *((char **)t31) = &&LAB19;
    goto LAB1;

LAB22:    *((unsigned int *)t6) = 1;
    goto LAB25;

LAB27:    t16 = *((unsigned int *)t6);
    t17 = *((unsigned int *)t21);
    *((unsigned int *)t6) = (t16 | t17);
    t18 = *((unsigned int *)t8);
    t19 = *((unsigned int *)t21);
    *((unsigned int *)t8) = (t18 | t19);
    goto LAB26;

}

static void Always_200_17(char *t0)
{
    char t6[8];
    char t30[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t7;
    char *t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    char *t21;
    char *t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    char *t28;
    char *t29;

LAB0:    t1 = (t0 + 14976U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(200, ng0);
    t2 = (t0 + 16032);
    *((int *)t2) = 1;
    t3 = (t0 + 15008);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(201, ng0);

LAB5:    xsi_set_current_line(202, ng0);
    t4 = (t0 + 3208U);
    t5 = *((char **)t4);
    t4 = ((char*)((ng1)));
    memset(t6, 0, 8);
    t7 = (t5 + 4);
    t8 = (t4 + 4);
    t9 = *((unsigned int *)t5);
    t10 = *((unsigned int *)t4);
    t11 = (t9 ^ t10);
    t12 = *((unsigned int *)t7);
    t13 = *((unsigned int *)t8);
    t14 = (t12 ^ t13);
    t15 = (t11 | t14);
    t16 = *((unsigned int *)t7);
    t17 = *((unsigned int *)t8);
    t18 = (t16 | t17);
    t19 = (~(t18));
    t20 = (t15 & t19);
    if (t20 != 0)
        goto LAB9;

LAB6:    if (t18 != 0)
        goto LAB8;

LAB7:    *((unsigned int *)t6) = 1;

LAB9:    t22 = (t6 + 4);
    t23 = *((unsigned int *)t22);
    t24 = (~(t23));
    t25 = *((unsigned int *)t6);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB10;

LAB11:    xsi_set_current_line(208, ng0);

LAB27:    xsi_set_current_line(209, ng0);
    t2 = (t0 + 7128);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8088);
    xsi_vlogvar_wait_assign_value(t5, t4, 0, 0, 2, 0LL);
    xsi_set_current_line(210, ng0);
    t2 = (t0 + 8088);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8248);
    xsi_vlogvar_wait_assign_value(t5, t4, 0, 0, 2, 0LL);

LAB12:    goto LAB2;

LAB8:    t21 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t21) = 1;
    goto LAB9;

LAB10:    xsi_set_current_line(203, ng0);

LAB13:    xsi_set_current_line(204, ng0);
    t28 = ((char*)((ng5)));
    t29 = (t0 + 8088);
    xsi_vlogvar_wait_assign_value(t29, t28, 0, 0, 2, 0LL);
    xsi_set_current_line(205, ng0);
    t2 = ((char*)((ng3)));
    memset(t30, 0, 8);
    t3 = (t2 + 4);
    t9 = *((unsigned int *)t3);
    t10 = (~(t9));
    t11 = *((unsigned int *)t2);
    t12 = (t11 & t10);
    t13 = (t12 & 1U);
    if (t13 != 0)
        goto LAB14;

LAB15:    if (*((unsigned int *)t3) != 0)
        goto LAB16;

LAB17:    t5 = (t30 + 4);
    t14 = *((unsigned int *)t30);
    t15 = *((unsigned int *)t5);
    t16 = (t14 || t15);
    if (t16 > 0)
        goto LAB18;

LAB19:    t17 = *((unsigned int *)t30);
    t18 = (~(t17));
    t19 = *((unsigned int *)t5);
    t20 = (t18 || t19);
    if (t20 > 0)
        goto LAB20;

LAB21:    if (*((unsigned int *)t5) > 0)
        goto LAB22;

LAB23:    if (*((unsigned int *)t30) > 0)
        goto LAB24;

LAB25:    memcpy(t6, t21, 8);

LAB26:    t8 = (t0 + 8248);
    xsi_vlogvar_wait_assign_value(t8, t6, 0, 0, 2, 0LL);
    goto LAB12;

LAB14:    *((unsigned int *)t30) = 1;
    goto LAB17;

LAB16:    t4 = (t30 + 4);
    *((unsigned int *)t30) = 1;
    *((unsigned int *)t4) = 1;
    goto LAB17;

LAB18:    t7 = ((char*)((ng5)));
    goto LAB19;

LAB20:    t8 = (t0 + 4808U);
    t21 = *((char **)t8);
    goto LAB21;

LAB22:    xsi_vlog_unsigned_bit_combine(t6, 2, t7, 2, t21, 2);
    goto LAB26;

LAB24:    memcpy(t6, t7, 8);
    goto LAB26;

}

static void Initial_218_18(char *t0)
{
    char t6[8];
    char t18[8];
    char t19[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    char *t20;
    char *t21;
    char *t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;
    char *t28;
    char *t29;
    unsigned int t30;
    int t31;
    char *t32;
    unsigned int t33;
    int t34;
    int t35;
    unsigned int t36;
    unsigned int t37;
    int t38;
    int t39;

LAB0:    t1 = (t0 + 15224U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(219, ng0);

LAB4:    t2 = (t0 + 280);
    xsi_vlog_namedbase_setdisablestate(t2, &&LAB5);
    t3 = (t0 + 15032);
    xsi_vlog_namedbase_pushprocess(t2, t3);

LAB6:    xsi_set_current_line(223, ng0);
    xsi_set_current_line(223, ng0);
    t4 = ((char*)((ng1)));
    t5 = (t0 + 8408);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 32);

LAB7:    t2 = (t0 + 8408);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng6)));
    memset(t6, 0, 8);
    t7 = (t4 + 4);
    if (*((unsigned int *)t7) != 0)
        goto LAB9;

LAB8:    t8 = (t5 + 4);
    if (*((unsigned int *)t8) != 0)
        goto LAB9;

LAB12:    if (*((unsigned int *)t4) < *((unsigned int *)t5))
        goto LAB10;

LAB11:    t10 = (t6 + 4);
    t11 = *((unsigned int *)t10);
    t12 = (~(t11));
    t13 = *((unsigned int *)t6);
    t14 = (t13 & t12);
    t15 = (t14 != 0);
    if (t15 > 0)
        goto LAB13;

LAB14:    xsi_set_current_line(229, ng0);
    t2 = ((char*)((ng6)));
    t3 = (t0 + 6488);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 2);
    xsi_set_current_line(230, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 6648);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    xsi_set_current_line(231, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 6808);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(233, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7128);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    xsi_set_current_line(234, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7288);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    xsi_set_current_line(235, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 7448);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(239, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8088);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    xsi_set_current_line(240, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8248);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    xsi_set_current_line(241, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7768);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    xsi_set_current_line(242, ng0);
    t2 = (t0 + 6488);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 7928);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 2);
    t2 = (t0 + 280);
    xsi_vlog_namedbase_popprocess(t2);

LAB5:    t3 = (t0 + 15032);
    xsi_vlog_dispose_process_subprogram_invocation(t3);

LAB1:    return;
LAB9:    t9 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t9) = 1;
    goto LAB11;

LAB10:    *((unsigned int *)t6) = 1;
    goto LAB11;

LAB13:    xsi_set_current_line(224, ng0);

LAB15:    xsi_set_current_line(225, ng0);
    t16 = ((char*)((ng7)));
    t17 = (t0 + 6328);
    t20 = (t0 + 6328);
    t21 = (t20 + 72U);
    t22 = *((char **)t21);
    t23 = (t0 + 6328);
    t24 = (t23 + 64U);
    t25 = *((char **)t24);
    t26 = (t0 + 8408);
    t27 = (t26 + 56U);
    t28 = *((char **)t27);
    xsi_vlog_generic_convert_array_indices(t18, t19, t22, t25, 2, 1, t28, 32, 1);
    t29 = (t18 + 4);
    t30 = *((unsigned int *)t29);
    t31 = (!(t30));
    t32 = (t19 + 4);
    t33 = *((unsigned int *)t32);
    t34 = (!(t33));
    t35 = (t31 && t34);
    if (t35 == 1)
        goto LAB16;

LAB17:    xsi_set_current_line(223, ng0);
    t2 = (t0 + 8408);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng2)));
    memset(t6, 0, 8);
    xsi_vlog_signed_add(t6, 32, t4, 32, t5, 32);
    t7 = (t0 + 8408);
    xsi_vlogvar_assign_value(t7, t6, 0, 0, 32);
    goto LAB7;

LAB16:    t36 = *((unsigned int *)t18);
    t37 = *((unsigned int *)t19);
    t38 = (t36 - t37);
    t39 = (t38 + 1);
    xsi_vlogvar_assign_value(t17, t16, 0, *((unsigned int *)t19), t39);
    goto LAB17;

}

static void Initial_249_19(char *t0)
{
    char t6[8];
    char t20[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    char *t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;

LAB0:    t1 = (t0 + 15472U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(250, ng0);

LAB4:    t2 = (t0 + 576);
    xsi_vlog_namedbase_setdisablestate(t2, &&LAB5);
    t3 = (t0 + 15280);
    xsi_vlog_namedbase_pushprocess(t2, t3);

LAB6:    xsi_set_current_line(254, ng0);
    t4 = ((char*)((ng2)));
    t5 = (t0 + 8568);
    xsi_vlogvar_assign_value(t5, t4, 0, 0, 32);
    xsi_set_current_line(255, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 8888);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 32);
    xsi_set_current_line(258, ng0);
    xsi_set_current_line(258, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 8728);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 32);

LAB7:    t2 = (t0 + 8728);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng3)));
    memset(t6, 0, 8);
    t7 = (t4 + 4);
    if (*((unsigned int *)t7) != 0)
        goto LAB9;

LAB8:    t8 = (t5 + 4);
    if (*((unsigned int *)t8) != 0)
        goto LAB9;

LAB12:    if (*((unsigned int *)t4) < *((unsigned int *)t5))
        goto LAB10;

LAB11:    t10 = (t6 + 4);
    t11 = *((unsigned int *)t10);
    t12 = (~(t11));
    t13 = *((unsigned int *)t6);
    t14 = (t13 & t12);
    t15 = (t14 != 0);
    if (t15 > 0)
        goto LAB13;

LAB14:    xsi_set_current_line(263, ng0);
    t2 = (t0 + 8888);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng6)));
    memset(t6, 0, 8);
    t7 = (t4 + 4);
    t8 = (t5 + 4);
    t11 = *((unsigned int *)t4);
    t12 = *((unsigned int *)t5);
    t13 = (t11 ^ t12);
    t14 = *((unsigned int *)t7);
    t15 = *((unsigned int *)t8);
    t22 = (t14 ^ t15);
    t23 = (t13 | t22);
    t24 = *((unsigned int *)t7);
    t25 = *((unsigned int *)t8);
    t26 = (t24 | t25);
    t27 = (~(t26));
    t28 = (t23 & t27);
    if (t28 != 0)
        goto LAB17;

LAB16:    if (t26 != 0)
        goto LAB18;

LAB19:    t10 = (t6 + 4);
    t29 = *((unsigned int *)t10);
    t30 = (~(t29));
    t31 = *((unsigned int *)t6);
    t32 = (t31 & t30);
    t33 = (t32 != 0);
    if (t33 > 0)
        goto LAB20;

LAB21:
LAB22:    xsi_set_current_line(270, ng0);
    t2 = (t0 + 15280);
    xsi_process_wait(t2, 0LL);
    *((char **)t1) = &&LAB24;

LAB1:    return;
LAB5:    t3 = (t0 + 15280);
    xsi_vlog_dispose_process_subprogram_invocation(t3);
    goto LAB1;

LAB9:    t9 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t9) = 1;
    goto LAB11;

LAB10:    *((unsigned int *)t6) = 1;
    goto LAB11;

LAB13:    xsi_set_current_line(259, ng0);

LAB15:    xsi_set_current_line(260, ng0);
    t16 = (t0 + 8888);
    t17 = (t16 + 56U);
    t18 = *((char **)t17);
    t19 = ((char*)((ng4)));
    memset(t20, 0, 8);
    xsi_vlog_signed_multiply(t20, 32, t18, 32, t19, 32);
    t21 = (t0 + 8888);
    xsi_vlogvar_assign_value(t21, t20, 0, 0, 32);
    xsi_set_current_line(258, ng0);
    t2 = (t0 + 8728);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = ((char*)((ng2)));
    memset(t6, 0, 8);
    xsi_vlog_signed_add(t6, 32, t4, 32, t5, 32);
    t7 = (t0 + 8728);
    xsi_vlogvar_assign_value(t7, t6, 0, 0, 32);
    goto LAB7;

LAB17:    *((unsigned int *)t6) = 1;
    goto LAB19;

LAB18:    t9 = (t6 + 4);
    *((unsigned int *)t6) = 1;
    *((unsigned int *)t9) = 1;
    goto LAB19;

LAB20:    xsi_set_current_line(264, ng0);

LAB23:    xsi_set_current_line(265, ng0);
    t16 = ((char*)((ng1)));
    t17 = (t0 + 8568);
    xsi_vlogvar_assign_value(t17, t16, 0, 0, 32);
    xsi_set_current_line(266, ng0);
    t2 = (t0 + 576);
    xsi_vlogfile_write(1, 0, 0, ng8, 1, t2);
    xsi_set_current_line(267, ng0);
    t2 = (t0 + 8888);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 576);
    xsi_vlogfile_write(1, 0, 0, ng9, 2, t5, (char)119, t4, 32);
    goto LAB22;

LAB24:    xsi_set_current_line(271, ng0);
    t3 = (t0 + 8568);
    t4 = (t3 + 56U);
    t5 = *((char **)t4);
    t7 = ((char*)((ng1)));
    memset(t6, 0, 8);
    xsi_vlog_signed_equal(t6, 32, t5, 32, t7, 32);
    t8 = (t6 + 4);
    t11 = *((unsigned int *)t8);
    t12 = (~(t11));
    t13 = *((unsigned int *)t6);
    t14 = (t13 & t12);
    t15 = (t14 != 0);
    if (t15 > 0)
        goto LAB25;

LAB26:
LAB27:    t2 = (t0 + 576);
    xsi_vlog_namedbase_popprocess(t2);
    goto LAB5;

LAB25:    xsi_set_current_line(271, ng0);
    xsi_vlog_finish(1);
    goto LAB27;

}


extern void worx_mktb2_m_03446308044661592354_2371860297_init()
{
	static char *pe[] = {(void *)NetDecl_72_0,(void *)NetDecl_73_1,(void *)NetDecl_74_2,(void *)Cont_102_3,(void *)Cont_105_4,(void *)Cont_106_5,(void *)Cont_107_6,(void *)Cont_111_7,(void *)Cont_112_8,(void *)Always_115_9,(void *)Cont_123_10,(void *)Cont_124_11,(void *)Always_126_12,(void *)Always_153_13,(void *)Cont_171_14,(void *)Cont_172_15,(void *)Always_174_16,(void *)Always_200_17,(void *)Initial_218_18,(void *)Initial_249_19};
	static char *se[] = {(void *)sp_incrGray};
	xsi_register_didat("worx_mktb2_m_03446308044661592354_2371860297", "isim/runsim.isim.sim/worx_mkTB2/m_03446308044661592354_2371860297.didat");
	xsi_register_executes(pe);
	xsi_register_subprogram_executes(se);
}
