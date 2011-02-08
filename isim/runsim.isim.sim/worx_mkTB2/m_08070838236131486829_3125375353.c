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
static const char *ng0 = "/opt/Bluespec/Bluespec-2010.10.beta1/lib/Verilog/FIFO2.v";
static unsigned int ng1[] = {2863311530U, 0U, 2U, 0U};
static unsigned int ng2[] = {0U, 0U};
static unsigned int ng3[] = {1U, 0U};
static unsigned int ng4[] = {34U, 0U};
static int ng5[] = {0, 0};
static int ng6[] = {1, 0};
static const char *ng7 = "Warning: FIFO2: %m -- Dequeuing from empty fifo";
static const char *ng8 = "Warning: FIFO2: %m -- Enqueuing to a full fifo";



static void Cont_62_0(char *t0)
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

LAB0:    t1 = (t0 + 5648U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(62, ng0);
    t2 = (t0 + 3936);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8672);
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
    t18 = (t0 + 8448);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Cont_63_1(char *t0)
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

LAB0:    t1 = (t0 + 5896U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(63, ng0);
    t2 = (t0 + 4096);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8736);
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
    t18 = (t0 + 8464);
    *((int *)t18) = 1;

LAB1:    return;
}

static void Cont_64_2(char *t0)
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
    char *t10;

LAB0:    t1 = (t0 + 6144U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(64, ng0);
    t2 = (t0 + 4256);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t0 + 8800);
    t6 = (t5 + 56U);
    t7 = *((char **)t6);
    t8 = (t7 + 56U);
    t9 = *((char **)t8);
    xsi_vlog_bit_copy(t9, 0, t4, 0, 34);
    xsi_driver_vfirst_trans(t5, 0, 33);
    t10 = (t0 + 8480);
    *((int *)t10) = 1;

LAB1:    return;
}

static void NetDecl_68_3(char *t0)
{
    char t4[8];
    char t15[8];
    char t26[8];
    char t34[8];
    char t66[8];
    char t81[8];
    char t94[8];
    char t101[8];
    char t133[8];
    char t148[8];
    char t156[8];
    char t188[8];
    char t196[8];
    char *t1;
    char *t2;
    char *t3;
    unsigned int t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    char *t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    char *t25;
    char *t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    char *t38;
    char *t39;
    char *t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    unsigned int t45;
    unsigned int t46;
    unsigned int t47;
    char *t48;
    char *t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    unsigned int t54;
    unsigned int t55;
    unsigned int t56;
    unsigned int t57;
    int t58;
    int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    unsigned int t64;
    unsigned int t65;
    char *t67;
    unsigned int t68;
    unsigned int t69;
    unsigned int t70;
    unsigned int t71;
    unsigned int t72;
    char *t73;
    char *t74;
    unsigned int t75;
    unsigned int t76;
    unsigned int t77;
    unsigned int t78;
    char *t79;
    char *t80;
    unsigned int t82;
    unsigned int t83;
    unsigned int t84;
    unsigned int t85;
    unsigned int t86;
    char *t87;
    char *t88;
    unsigned int t89;
    unsigned int t90;
    unsigned int t91;
    char *t92;
    char *t93;
    unsigned int t95;
    unsigned int t96;
    unsigned int t97;
    unsigned int t98;
    unsigned int t99;
    char *t100;
    unsigned int t102;
    unsigned int t103;
    unsigned int t104;
    char *t105;
    char *t106;
    char *t107;
    unsigned int t108;
    unsigned int t109;
    unsigned int t110;
    unsigned int t111;
    unsigned int t112;
    unsigned int t113;
    unsigned int t114;
    char *t115;
    char *t116;
    unsigned int t117;
    unsigned int t118;
    unsigned int t119;
    unsigned int t120;
    unsigned int t121;
    unsigned int t122;
    unsigned int t123;
    unsigned int t124;
    int t125;
    int t126;
    unsigned int t127;
    unsigned int t128;
    unsigned int t129;
    unsigned int t130;
    unsigned int t131;
    unsigned int t132;
    char *t134;
    unsigned int t135;
    unsigned int t136;
    unsigned int t137;
    unsigned int t138;
    unsigned int t139;
    char *t140;
    char *t141;
    unsigned int t142;
    unsigned int t143;
    unsigned int t144;
    char *t145;
    char *t146;
    char *t147;
    char *t149;
    unsigned int t150;
    unsigned int t151;
    unsigned int t152;
    unsigned int t153;
    unsigned int t154;
    char *t155;
    unsigned int t157;
    unsigned int t158;
    unsigned int t159;
    char *t160;
    char *t161;
    char *t162;
    unsigned int t163;
    unsigned int t164;
    unsigned int t165;
    unsigned int t166;
    unsigned int t167;
    unsigned int t168;
    unsigned int t169;
    char *t170;
    char *t171;
    unsigned int t172;
    unsigned int t173;
    unsigned int t174;
    unsigned int t175;
    unsigned int t176;
    unsigned int t177;
    unsigned int t178;
    unsigned int t179;
    int t180;
    int t181;
    unsigned int t182;
    unsigned int t183;
    unsigned int t184;
    unsigned int t185;
    unsigned int t186;
    unsigned int t187;
    char *t189;
    unsigned int t190;
    unsigned int t191;
    unsigned int t192;
    unsigned int t193;
    unsigned int t194;
    char *t195;
    unsigned int t197;
    unsigned int t198;
    unsigned int t199;
    char *t200;
    char *t201;
    char *t202;
    unsigned int t203;
    unsigned int t204;
    unsigned int t205;
    unsigned int t206;
    unsigned int t207;
    unsigned int t208;
    unsigned int t209;
    char *t210;
    char *t211;
    unsigned int t212;
    unsigned int t213;
    unsigned int t214;
    int t215;
    unsigned int t216;
    unsigned int t217;
    unsigned int t218;
    int t219;
    unsigned int t220;
    unsigned int t221;
    unsigned int t222;
    unsigned int t223;
    char *t224;
    char *t225;
    char *t226;
    char *t227;
    char *t228;
    unsigned int t229;
    unsigned int t230;
    char *t231;
    unsigned int t232;
    unsigned int t233;
    char *t234;
    unsigned int t235;
    unsigned int t236;
    char *t237;

LAB0:    t1 = (t0 + 6392U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(68, ng0);
    t2 = (t0 + 2096U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t5 = *((unsigned int *)t2);
    t6 = (~(t5));
    t7 = *((unsigned int *)t3);
    t8 = (t7 & t6);
    t9 = (t8 & 1U);
    if (t9 != 0)
        goto LAB4;

LAB5:    if (*((unsigned int *)t2) != 0)
        goto LAB6;

LAB7:    t11 = (t4 + 4);
    t12 = *((unsigned int *)t4);
    t13 = *((unsigned int *)t11);
    t14 = (t12 || t13);
    if (t14 > 0)
        goto LAB8;

LAB9:    memcpy(t34, t4, 8);

LAB10:    memset(t66, 0, 8);
    t67 = (t34 + 4);
    t68 = *((unsigned int *)t67);
    t69 = (~(t68));
    t70 = *((unsigned int *)t34);
    t71 = (t70 & t69);
    t72 = (t71 & 1U);
    if (t72 != 0)
        goto LAB22;

LAB23:    if (*((unsigned int *)t67) != 0)
        goto LAB24;

LAB25:    t74 = (t66 + 4);
    t75 = *((unsigned int *)t66);
    t76 = (!(t75));
    t77 = *((unsigned int *)t74);
    t78 = (t76 || t77);
    if (t78 > 0)
        goto LAB26;

LAB27:    memcpy(t196, t66, 8);

LAB28:    t224 = (t0 + 8864);
    t225 = (t224 + 56U);
    t226 = *((char **)t225);
    t227 = (t226 + 56U);
    t228 = *((char **)t227);
    memset(t228, 0, 8);
    t229 = 1U;
    t230 = t229;
    t231 = (t196 + 4);
    t232 = *((unsigned int *)t196);
    t229 = (t229 & t232);
    t233 = *((unsigned int *)t231);
    t230 = (t230 & t233);
    t234 = (t228 + 4);
    t235 = *((unsigned int *)t228);
    *((unsigned int *)t228) = (t235 | t229);
    t236 = *((unsigned int *)t234);
    *((unsigned int *)t234) = (t236 | t230);
    xsi_driver_vfirst_trans(t224, 0, 0U);
    t237 = (t0 + 8496);
    *((int *)t237) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t4) = 1;
    goto LAB7;

LAB6:    t10 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t10) = 1;
    goto LAB7;

LAB8:    t16 = (t0 + 4096);
    t17 = (t16 + 56U);
    t18 = *((char **)t17);
    memset(t15, 0, 8);
    t19 = (t18 + 4);
    t20 = *((unsigned int *)t19);
    t21 = (~(t20));
    t22 = *((unsigned int *)t18);
    t23 = (t22 & t21);
    t24 = (t23 & 1U);
    if (t24 != 0)
        goto LAB14;

LAB12:    if (*((unsigned int *)t19) == 0)
        goto LAB11;

LAB13:    t25 = (t15 + 4);
    *((unsigned int *)t15) = 1;
    *((unsigned int *)t25) = 1;

LAB14:    memset(t26, 0, 8);
    t27 = (t15 + 4);
    t28 = *((unsigned int *)t27);
    t29 = (~(t28));
    t30 = *((unsigned int *)t15);
    t31 = (t30 & t29);
    t32 = (t31 & 1U);
    if (t32 != 0)
        goto LAB15;

LAB16:    if (*((unsigned int *)t27) != 0)
        goto LAB17;

LAB18:    t35 = *((unsigned int *)t4);
    t36 = *((unsigned int *)t26);
    t37 = (t35 & t36);
    *((unsigned int *)t34) = t37;
    t38 = (t4 + 4);
    t39 = (t26 + 4);
    t40 = (t34 + 4);
    t41 = *((unsigned int *)t38);
    t42 = *((unsigned int *)t39);
    t43 = (t41 | t42);
    *((unsigned int *)t40) = t43;
    t44 = *((unsigned int *)t40);
    t45 = (t44 != 0);
    if (t45 == 1)
        goto LAB19;

LAB20:
LAB21:    goto LAB10;

LAB11:    *((unsigned int *)t15) = 1;
    goto LAB14;

LAB15:    *((unsigned int *)t26) = 1;
    goto LAB18;

LAB17:    t33 = (t26 + 4);
    *((unsigned int *)t26) = 1;
    *((unsigned int *)t33) = 1;
    goto LAB18;

LAB19:    t46 = *((unsigned int *)t34);
    t47 = *((unsigned int *)t40);
    *((unsigned int *)t34) = (t46 | t47);
    t48 = (t4 + 4);
    t49 = (t26 + 4);
    t50 = *((unsigned int *)t4);
    t51 = (~(t50));
    t52 = *((unsigned int *)t48);
    t53 = (~(t52));
    t54 = *((unsigned int *)t26);
    t55 = (~(t54));
    t56 = *((unsigned int *)t49);
    t57 = (~(t56));
    t58 = (t51 & t53);
    t59 = (t55 & t57);
    t60 = (~(t58));
    t61 = (~(t59));
    t62 = *((unsigned int *)t40);
    *((unsigned int *)t40) = (t62 & t60);
    t63 = *((unsigned int *)t40);
    *((unsigned int *)t40) = (t63 & t61);
    t64 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t64 & t60);
    t65 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t65 & t61);
    goto LAB21;

LAB22:    *((unsigned int *)t66) = 1;
    goto LAB25;

LAB24:    t73 = (t66 + 4);
    *((unsigned int *)t66) = 1;
    *((unsigned int *)t73) = 1;
    goto LAB25;

LAB26:    t79 = (t0 + 2096U);
    t80 = *((char **)t79);
    memset(t81, 0, 8);
    t79 = (t80 + 4);
    t82 = *((unsigned int *)t79);
    t83 = (~(t82));
    t84 = *((unsigned int *)t80);
    t85 = (t84 & t83);
    t86 = (t85 & 1U);
    if (t86 != 0)
        goto LAB29;

LAB30:    if (*((unsigned int *)t79) != 0)
        goto LAB31;

LAB32:    t88 = (t81 + 4);
    t89 = *((unsigned int *)t81);
    t90 = *((unsigned int *)t88);
    t91 = (t89 || t90);
    if (t91 > 0)
        goto LAB33;

LAB34:    memcpy(t101, t81, 8);

LAB35:    memset(t133, 0, 8);
    t134 = (t101 + 4);
    t135 = *((unsigned int *)t134);
    t136 = (~(t135));
    t137 = *((unsigned int *)t101);
    t138 = (t137 & t136);
    t139 = (t138 & 1U);
    if (t139 != 0)
        goto LAB43;

LAB44:    if (*((unsigned int *)t134) != 0)
        goto LAB45;

LAB46:    t141 = (t133 + 4);
    t142 = *((unsigned int *)t133);
    t143 = *((unsigned int *)t141);
    t144 = (t142 || t143);
    if (t144 > 0)
        goto LAB47;

LAB48:    memcpy(t156, t133, 8);

LAB49:    memset(t188, 0, 8);
    t189 = (t156 + 4);
    t190 = *((unsigned int *)t189);
    t191 = (~(t190));
    t192 = *((unsigned int *)t156);
    t193 = (t192 & t191);
    t194 = (t193 & 1U);
    if (t194 != 0)
        goto LAB57;

LAB58:    if (*((unsigned int *)t189) != 0)
        goto LAB59;

LAB60:    t197 = *((unsigned int *)t66);
    t198 = *((unsigned int *)t188);
    t199 = (t197 | t198);
    *((unsigned int *)t196) = t199;
    t200 = (t66 + 4);
    t201 = (t188 + 4);
    t202 = (t196 + 4);
    t203 = *((unsigned int *)t200);
    t204 = *((unsigned int *)t201);
    t205 = (t203 | t204);
    *((unsigned int *)t202) = t205;
    t206 = *((unsigned int *)t202);
    t207 = (t206 != 0);
    if (t207 == 1)
        goto LAB61;

LAB62:
LAB63:    goto LAB28;

LAB29:    *((unsigned int *)t81) = 1;
    goto LAB32;

LAB31:    t87 = (t81 + 4);
    *((unsigned int *)t81) = 1;
    *((unsigned int *)t87) = 1;
    goto LAB32;

LAB33:    t92 = (t0 + 2256U);
    t93 = *((char **)t92);
    memset(t94, 0, 8);
    t92 = (t93 + 4);
    t95 = *((unsigned int *)t92);
    t96 = (~(t95));
    t97 = *((unsigned int *)t93);
    t98 = (t97 & t96);
    t99 = (t98 & 1U);
    if (t99 != 0)
        goto LAB36;

LAB37:    if (*((unsigned int *)t92) != 0)
        goto LAB38;

LAB39:    t102 = *((unsigned int *)t81);
    t103 = *((unsigned int *)t94);
    t104 = (t102 & t103);
    *((unsigned int *)t101) = t104;
    t105 = (t81 + 4);
    t106 = (t94 + 4);
    t107 = (t101 + 4);
    t108 = *((unsigned int *)t105);
    t109 = *((unsigned int *)t106);
    t110 = (t108 | t109);
    *((unsigned int *)t107) = t110;
    t111 = *((unsigned int *)t107);
    t112 = (t111 != 0);
    if (t112 == 1)
        goto LAB40;

LAB41:
LAB42:    goto LAB35;

LAB36:    *((unsigned int *)t94) = 1;
    goto LAB39;

LAB38:    t100 = (t94 + 4);
    *((unsigned int *)t94) = 1;
    *((unsigned int *)t100) = 1;
    goto LAB39;

LAB40:    t113 = *((unsigned int *)t101);
    t114 = *((unsigned int *)t107);
    *((unsigned int *)t101) = (t113 | t114);
    t115 = (t81 + 4);
    t116 = (t94 + 4);
    t117 = *((unsigned int *)t81);
    t118 = (~(t117));
    t119 = *((unsigned int *)t115);
    t120 = (~(t119));
    t121 = *((unsigned int *)t94);
    t122 = (~(t121));
    t123 = *((unsigned int *)t116);
    t124 = (~(t123));
    t125 = (t118 & t120);
    t126 = (t122 & t124);
    t127 = (~(t125));
    t128 = (~(t126));
    t129 = *((unsigned int *)t107);
    *((unsigned int *)t107) = (t129 & t127);
    t130 = *((unsigned int *)t107);
    *((unsigned int *)t107) = (t130 & t128);
    t131 = *((unsigned int *)t101);
    *((unsigned int *)t101) = (t131 & t127);
    t132 = *((unsigned int *)t101);
    *((unsigned int *)t101) = (t132 & t128);
    goto LAB42;

LAB43:    *((unsigned int *)t133) = 1;
    goto LAB46;

LAB45:    t140 = (t133 + 4);
    *((unsigned int *)t133) = 1;
    *((unsigned int *)t140) = 1;
    goto LAB46;

LAB47:    t145 = (t0 + 3936);
    t146 = (t145 + 56U);
    t147 = *((char **)t146);
    memset(t148, 0, 8);
    t149 = (t147 + 4);
    t150 = *((unsigned int *)t149);
    t151 = (~(t150));
    t152 = *((unsigned int *)t147);
    t153 = (t152 & t151);
    t154 = (t153 & 1U);
    if (t154 != 0)
        goto LAB50;

LAB51:    if (*((unsigned int *)t149) != 0)
        goto LAB52;

LAB53:    t157 = *((unsigned int *)t133);
    t158 = *((unsigned int *)t148);
    t159 = (t157 & t158);
    *((unsigned int *)t156) = t159;
    t160 = (t133 + 4);
    t161 = (t148 + 4);
    t162 = (t156 + 4);
    t163 = *((unsigned int *)t160);
    t164 = *((unsigned int *)t161);
    t165 = (t163 | t164);
    *((unsigned int *)t162) = t165;
    t166 = *((unsigned int *)t162);
    t167 = (t166 != 0);
    if (t167 == 1)
        goto LAB54;

LAB55:
LAB56:    goto LAB49;

LAB50:    *((unsigned int *)t148) = 1;
    goto LAB53;

LAB52:    t155 = (t148 + 4);
    *((unsigned int *)t148) = 1;
    *((unsigned int *)t155) = 1;
    goto LAB53;

LAB54:    t168 = *((unsigned int *)t156);
    t169 = *((unsigned int *)t162);
    *((unsigned int *)t156) = (t168 | t169);
    t170 = (t133 + 4);
    t171 = (t148 + 4);
    t172 = *((unsigned int *)t133);
    t173 = (~(t172));
    t174 = *((unsigned int *)t170);
    t175 = (~(t174));
    t176 = *((unsigned int *)t148);
    t177 = (~(t176));
    t178 = *((unsigned int *)t171);
    t179 = (~(t178));
    t180 = (t173 & t175);
    t181 = (t177 & t179);
    t182 = (~(t180));
    t183 = (~(t181));
    t184 = *((unsigned int *)t162);
    *((unsigned int *)t162) = (t184 & t182);
    t185 = *((unsigned int *)t162);
    *((unsigned int *)t162) = (t185 & t183);
    t186 = *((unsigned int *)t156);
    *((unsigned int *)t156) = (t186 & t182);
    t187 = *((unsigned int *)t156);
    *((unsigned int *)t156) = (t187 & t183);
    goto LAB56;

LAB57:    *((unsigned int *)t188) = 1;
    goto LAB60;

LAB59:    t195 = (t188 + 4);
    *((unsigned int *)t188) = 1;
    *((unsigned int *)t195) = 1;
    goto LAB60;

LAB61:    t208 = *((unsigned int *)t196);
    t209 = *((unsigned int *)t202);
    *((unsigned int *)t196) = (t208 | t209);
    t210 = (t66 + 4);
    t211 = (t188 + 4);
    t212 = *((unsigned int *)t210);
    t213 = (~(t212));
    t214 = *((unsigned int *)t66);
    t215 = (t214 & t213);
    t216 = *((unsigned int *)t211);
    t217 = (~(t216));
    t218 = *((unsigned int *)t188);
    t219 = (t218 & t217);
    t220 = (~(t215));
    t221 = (~(t219));
    t222 = *((unsigned int *)t202);
    *((unsigned int *)t202) = (t222 & t220);
    t223 = *((unsigned int *)t202);
    *((unsigned int *)t202) = (t223 & t221);
    goto LAB63;

}

static void NetDecl_69_4(char *t0)
{
    char t4[8];
    char t15[8];
    char t26[8];
    char t34[8];
    char *t1;
    char *t2;
    char *t3;
    unsigned int t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    char *t11;
    unsigned int t12;
    unsigned int t13;
    unsigned int t14;
    char *t16;
    char *t17;
    char *t18;
    char *t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    unsigned int t24;
    char *t25;
    char *t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    char *t38;
    char *t39;
    char *t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    unsigned int t45;
    unsigned int t46;
    unsigned int t47;
    char *t48;
    char *t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    unsigned int t54;
    unsigned int t55;
    unsigned int t56;
    unsigned int t57;
    int t58;
    int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    unsigned int t64;
    unsigned int t65;
    char *t66;
    char *t67;
    char *t68;
    char *t69;
    char *t70;
    unsigned int t71;
    unsigned int t72;
    char *t73;
    unsigned int t74;
    unsigned int t75;
    char *t76;
    unsigned int t77;
    unsigned int t78;
    char *t79;

LAB0:    t1 = (t0 + 6640U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(69, ng0);
    t2 = (t0 + 2256U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t5 = *((unsigned int *)t2);
    t6 = (~(t5));
    t7 = *((unsigned int *)t3);
    t8 = (t7 & t6);
    t9 = (t8 & 1U);
    if (t9 != 0)
        goto LAB4;

LAB5:    if (*((unsigned int *)t2) != 0)
        goto LAB6;

LAB7:    t11 = (t4 + 4);
    t12 = *((unsigned int *)t4);
    t13 = *((unsigned int *)t11);
    t14 = (t12 || t13);
    if (t14 > 0)
        goto LAB8;

LAB9:    memcpy(t34, t4, 8);

LAB10:    t66 = (t0 + 8928);
    t67 = (t66 + 56U);
    t68 = *((char **)t67);
    t69 = (t68 + 56U);
    t70 = *((char **)t69);
    memset(t70, 0, 8);
    t71 = 1U;
    t72 = t71;
    t73 = (t34 + 4);
    t74 = *((unsigned int *)t34);
    t71 = (t71 & t74);
    t75 = *((unsigned int *)t73);
    t72 = (t72 & t75);
    t76 = (t70 + 4);
    t77 = *((unsigned int *)t70);
    *((unsigned int *)t70) = (t77 | t71);
    t78 = *((unsigned int *)t76);
    *((unsigned int *)t76) = (t78 | t72);
    xsi_driver_vfirst_trans(t66, 0, 0U);
    t79 = (t0 + 8512);
    *((int *)t79) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t4) = 1;
    goto LAB7;

LAB6:    t10 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t10) = 1;
    goto LAB7;

LAB8:    t16 = (t0 + 3936);
    t17 = (t16 + 56U);
    t18 = *((char **)t17);
    memset(t15, 0, 8);
    t19 = (t18 + 4);
    t20 = *((unsigned int *)t19);
    t21 = (~(t20));
    t22 = *((unsigned int *)t18);
    t23 = (t22 & t21);
    t24 = (t23 & 1U);
    if (t24 != 0)
        goto LAB14;

LAB12:    if (*((unsigned int *)t19) == 0)
        goto LAB11;

LAB13:    t25 = (t15 + 4);
    *((unsigned int *)t15) = 1;
    *((unsigned int *)t25) = 1;

LAB14:    memset(t26, 0, 8);
    t27 = (t15 + 4);
    t28 = *((unsigned int *)t27);
    t29 = (~(t28));
    t30 = *((unsigned int *)t15);
    t31 = (t30 & t29);
    t32 = (t31 & 1U);
    if (t32 != 0)
        goto LAB15;

LAB16:    if (*((unsigned int *)t27) != 0)
        goto LAB17;

LAB18:    t35 = *((unsigned int *)t4);
    t36 = *((unsigned int *)t26);
    t37 = (t35 & t36);
    *((unsigned int *)t34) = t37;
    t38 = (t4 + 4);
    t39 = (t26 + 4);
    t40 = (t34 + 4);
    t41 = *((unsigned int *)t38);
    t42 = *((unsigned int *)t39);
    t43 = (t41 | t42);
    *((unsigned int *)t40) = t43;
    t44 = *((unsigned int *)t40);
    t45 = (t44 != 0);
    if (t45 == 1)
        goto LAB19;

LAB20:
LAB21:    goto LAB10;

LAB11:    *((unsigned int *)t15) = 1;
    goto LAB14;

LAB15:    *((unsigned int *)t26) = 1;
    goto LAB18;

LAB17:    t33 = (t26 + 4);
    *((unsigned int *)t26) = 1;
    *((unsigned int *)t33) = 1;
    goto LAB18;

LAB19:    t46 = *((unsigned int *)t34);
    t47 = *((unsigned int *)t40);
    *((unsigned int *)t34) = (t46 | t47);
    t48 = (t4 + 4);
    t49 = (t26 + 4);
    t50 = *((unsigned int *)t4);
    t51 = (~(t50));
    t52 = *((unsigned int *)t48);
    t53 = (~(t52));
    t54 = *((unsigned int *)t26);
    t55 = (~(t54));
    t56 = *((unsigned int *)t49);
    t57 = (~(t56));
    t58 = (t51 & t53);
    t59 = (t55 & t57);
    t60 = (~(t58));
    t61 = (~(t59));
    t62 = *((unsigned int *)t40);
    *((unsigned int *)t40) = (t62 & t60);
    t63 = *((unsigned int *)t40);
    *((unsigned int *)t40) = (t63 & t61);
    t64 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t64 & t60);
    t65 = *((unsigned int *)t34);
    *((unsigned int *)t34) = (t65 & t61);
    goto LAB21;

}

static void NetDecl_70_5(char *t0)
{
    char t3[8];
    char t11[8];
    char t23[8];
    char t32[8];
    char t40[8];
    char t72[8];
    char t85[8];
    char t94[8];
    char t109[8];
    char t117[8];
    char t149[8];
    char t157[8];
    char t185[8];
    char t198[8];
    char t207[8];
    char t222[8];
    char t230[8];
    char t262[8];
    char t270[8];
    char *t1;
    char *t2;
    char *t4;
    unsigned int t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    char *t18;
    char *t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t24;
    char *t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    char *t31;
    char *t33;
    unsigned int t34;
    unsigned int t35;
    unsigned int t36;
    unsigned int t37;
    unsigned int t38;
    char *t39;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    char *t44;
    char *t45;
    char *t46;
    unsigned int t47;
    unsigned int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    char *t54;
    char *t55;
    unsigned int t56;
    unsigned int t57;
    unsigned int t58;
    unsigned int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    unsigned int t63;
    int t64;
    int t65;
    unsigned int t66;
    unsigned int t67;
    unsigned int t68;
    unsigned int t69;
    unsigned int t70;
    unsigned int t71;
    char *t73;
    unsigned int t74;
    unsigned int t75;
    unsigned int t76;
    unsigned int t77;
    unsigned int t78;
    char *t79;
    char *t80;
    unsigned int t81;
    unsigned int t82;
    unsigned int t83;
    unsigned int t84;
    char *t86;
    char *t87;
    unsigned int t88;
    unsigned int t89;
    unsigned int t90;
    unsigned int t91;
    unsigned int t92;
    char *t93;
    char *t95;
    unsigned int t96;
    unsigned int t97;
    unsigned int t98;
    unsigned int t99;
    unsigned int t100;
    char *t101;
    char *t102;
    unsigned int t103;
    unsigned int t104;
    unsigned int t105;
    char *t106;
    char *t107;
    char *t108;
    char *t110;
    unsigned int t111;
    unsigned int t112;
    unsigned int t113;
    unsigned int t114;
    unsigned int t115;
    char *t116;
    unsigned int t118;
    unsigned int t119;
    unsigned int t120;
    char *t121;
    char *t122;
    char *t123;
    unsigned int t124;
    unsigned int t125;
    unsigned int t126;
    unsigned int t127;
    unsigned int t128;
    unsigned int t129;
    unsigned int t130;
    char *t131;
    char *t132;
    unsigned int t133;
    unsigned int t134;
    unsigned int t135;
    unsigned int t136;
    unsigned int t137;
    unsigned int t138;
    unsigned int t139;
    unsigned int t140;
    int t141;
    int t142;
    unsigned int t143;
    unsigned int t144;
    unsigned int t145;
    unsigned int t146;
    unsigned int t147;
    unsigned int t148;
    char *t150;
    unsigned int t151;
    unsigned int t152;
    unsigned int t153;
    unsigned int t154;
    unsigned int t155;
    char *t156;
    unsigned int t158;
    unsigned int t159;
    unsigned int t160;
    char *t161;
    char *t162;
    char *t163;
    unsigned int t164;
    unsigned int t165;
    unsigned int t166;
    unsigned int t167;
    unsigned int t168;
    unsigned int t169;
    unsigned int t170;
    char *t171;
    char *t172;
    unsigned int t173;
    unsigned int t174;
    unsigned int t175;
    int t176;
    unsigned int t177;
    unsigned int t178;
    unsigned int t179;
    int t180;
    unsigned int t181;
    unsigned int t182;
    unsigned int t183;
    unsigned int t184;
    char *t186;
    unsigned int t187;
    unsigned int t188;
    unsigned int t189;
    unsigned int t190;
    unsigned int t191;
    char *t192;
    char *t193;
    unsigned int t194;
    unsigned int t195;
    unsigned int t196;
    unsigned int t197;
    char *t199;
    char *t200;
    unsigned int t201;
    unsigned int t202;
    unsigned int t203;
    unsigned int t204;
    unsigned int t205;
    char *t206;
    char *t208;
    unsigned int t209;
    unsigned int t210;
    unsigned int t211;
    unsigned int t212;
    unsigned int t213;
    char *t214;
    char *t215;
    unsigned int t216;
    unsigned int t217;
    unsigned int t218;
    char *t219;
    char *t220;
    char *t221;
    char *t223;
    unsigned int t224;
    unsigned int t225;
    unsigned int t226;
    unsigned int t227;
    unsigned int t228;
    char *t229;
    unsigned int t231;
    unsigned int t232;
    unsigned int t233;
    char *t234;
    char *t235;
    char *t236;
    unsigned int t237;
    unsigned int t238;
    unsigned int t239;
    unsigned int t240;
    unsigned int t241;
    unsigned int t242;
    unsigned int t243;
    char *t244;
    char *t245;
    unsigned int t246;
    unsigned int t247;
    unsigned int t248;
    unsigned int t249;
    unsigned int t250;
    unsigned int t251;
    unsigned int t252;
    unsigned int t253;
    int t254;
    int t255;
    unsigned int t256;
    unsigned int t257;
    unsigned int t258;
    unsigned int t259;
    unsigned int t260;
    unsigned int t261;
    char *t263;
    unsigned int t264;
    unsigned int t265;
    unsigned int t266;
    unsigned int t267;
    unsigned int t268;
    char *t269;
    unsigned int t271;
    unsigned int t272;
    unsigned int t273;
    char *t274;
    char *t275;
    char *t276;
    unsigned int t277;
    unsigned int t278;
    unsigned int t279;
    unsigned int t280;
    unsigned int t281;
    unsigned int t282;
    unsigned int t283;
    char *t284;
    char *t285;
    unsigned int t286;
    unsigned int t287;
    unsigned int t288;
    int t289;
    unsigned int t290;
    unsigned int t291;
    unsigned int t292;
    int t293;
    unsigned int t294;
    unsigned int t295;
    unsigned int t296;
    unsigned int t297;
    char *t298;
    char *t299;
    char *t300;
    char *t301;
    char *t302;
    unsigned int t303;
    unsigned int t304;
    char *t305;
    unsigned int t306;
    unsigned int t307;
    char *t308;
    unsigned int t309;
    unsigned int t310;
    char *t311;

LAB0:    t1 = (t0 + 6888U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(70, ng0);
    t2 = (t0 + 2256U);
    t4 = *((char **)t2);
    memset(t3, 0, 8);
    t2 = (t4 + 4);
    t5 = *((unsigned int *)t2);
    t6 = (~(t5));
    t7 = *((unsigned int *)t4);
    t8 = (t7 & t6);
    t9 = (t8 & 1U);
    if (t9 != 0)
        goto LAB7;

LAB5:    if (*((unsigned int *)t2) == 0)
        goto LAB4;

LAB6:    t10 = (t3 + 4);
    *((unsigned int *)t3) = 1;
    *((unsigned int *)t10) = 1;

LAB7:    memset(t11, 0, 8);
    t12 = (t3 + 4);
    t13 = *((unsigned int *)t12);
    t14 = (~(t13));
    t15 = *((unsigned int *)t3);
    t16 = (t15 & t14);
    t17 = (t16 & 1U);
    if (t17 != 0)
        goto LAB8;

LAB9:    if (*((unsigned int *)t12) != 0)
        goto LAB10;

LAB11:    t19 = (t11 + 4);
    t20 = *((unsigned int *)t11);
    t21 = *((unsigned int *)t19);
    t22 = (t20 || t21);
    if (t22 > 0)
        goto LAB12;

LAB13:    memcpy(t40, t11, 8);

LAB14:    memset(t72, 0, 8);
    t73 = (t40 + 4);
    t74 = *((unsigned int *)t73);
    t75 = (~(t74));
    t76 = *((unsigned int *)t40);
    t77 = (t76 & t75);
    t78 = (t77 & 1U);
    if (t78 != 0)
        goto LAB26;

LAB27:    if (*((unsigned int *)t73) != 0)
        goto LAB28;

LAB29:    t80 = (t72 + 4);
    t81 = *((unsigned int *)t72);
    t82 = (!(t81));
    t83 = *((unsigned int *)t80);
    t84 = (t82 || t83);
    if (t84 > 0)
        goto LAB30;

LAB31:    memcpy(t157, t72, 8);

LAB32:    memset(t185, 0, 8);
    t186 = (t157 + 4);
    t187 = *((unsigned int *)t186);
    t188 = (~(t187));
    t189 = *((unsigned int *)t157);
    t190 = (t189 & t188);
    t191 = (t190 & 1U);
    if (t191 != 0)
        goto LAB58;

LAB59:    if (*((unsigned int *)t186) != 0)
        goto LAB60;

LAB61:    t193 = (t185 + 4);
    t194 = *((unsigned int *)t185);
    t195 = (!(t194));
    t196 = *((unsigned int *)t193);
    t197 = (t195 || t196);
    if (t197 > 0)
        goto LAB62;

LAB63:    memcpy(t270, t185, 8);

LAB64:    t298 = (t0 + 8992);
    t299 = (t298 + 56U);
    t300 = *((char **)t299);
    t301 = (t300 + 56U);
    t302 = *((char **)t301);
    memset(t302, 0, 8);
    t303 = 1U;
    t304 = t303;
    t305 = (t270 + 4);
    t306 = *((unsigned int *)t270);
    t303 = (t303 & t306);
    t307 = *((unsigned int *)t305);
    t304 = (t304 & t307);
    t308 = (t302 + 4);
    t309 = *((unsigned int *)t302);
    *((unsigned int *)t302) = (t309 | t303);
    t310 = *((unsigned int *)t308);
    *((unsigned int *)t308) = (t310 | t304);
    xsi_driver_vfirst_trans(t298, 0, 0U);
    t311 = (t0 + 8528);
    *((int *)t311) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t3) = 1;
    goto LAB7;

LAB8:    *((unsigned int *)t11) = 1;
    goto LAB11;

LAB10:    t18 = (t11 + 4);
    *((unsigned int *)t11) = 1;
    *((unsigned int *)t18) = 1;
    goto LAB11;

LAB12:    t24 = (t0 + 2096U);
    t25 = *((char **)t24);
    memset(t23, 0, 8);
    t24 = (t25 + 4);
    t26 = *((unsigned int *)t24);
    t27 = (~(t26));
    t28 = *((unsigned int *)t25);
    t29 = (t28 & t27);
    t30 = (t29 & 1U);
    if (t30 != 0)
        goto LAB18;

LAB16:    if (*((unsigned int *)t24) == 0)
        goto LAB15;

LAB17:    t31 = (t23 + 4);
    *((unsigned int *)t23) = 1;
    *((unsigned int *)t31) = 1;

LAB18:    memset(t32, 0, 8);
    t33 = (t23 + 4);
    t34 = *((unsigned int *)t33);
    t35 = (~(t34));
    t36 = *((unsigned int *)t23);
    t37 = (t36 & t35);
    t38 = (t37 & 1U);
    if (t38 != 0)
        goto LAB19;

LAB20:    if (*((unsigned int *)t33) != 0)
        goto LAB21;

LAB22:    t41 = *((unsigned int *)t11);
    t42 = *((unsigned int *)t32);
    t43 = (t41 & t42);
    *((unsigned int *)t40) = t43;
    t44 = (t11 + 4);
    t45 = (t32 + 4);
    t46 = (t40 + 4);
    t47 = *((unsigned int *)t44);
    t48 = *((unsigned int *)t45);
    t49 = (t47 | t48);
    *((unsigned int *)t46) = t49;
    t50 = *((unsigned int *)t46);
    t51 = (t50 != 0);
    if (t51 == 1)
        goto LAB23;

LAB24:
LAB25:    goto LAB14;

LAB15:    *((unsigned int *)t23) = 1;
    goto LAB18;

LAB19:    *((unsigned int *)t32) = 1;
    goto LAB22;

LAB21:    t39 = (t32 + 4);
    *((unsigned int *)t32) = 1;
    *((unsigned int *)t39) = 1;
    goto LAB22;

LAB23:    t52 = *((unsigned int *)t40);
    t53 = *((unsigned int *)t46);
    *((unsigned int *)t40) = (t52 | t53);
    t54 = (t11 + 4);
    t55 = (t32 + 4);
    t56 = *((unsigned int *)t11);
    t57 = (~(t56));
    t58 = *((unsigned int *)t54);
    t59 = (~(t58));
    t60 = *((unsigned int *)t32);
    t61 = (~(t60));
    t62 = *((unsigned int *)t55);
    t63 = (~(t62));
    t64 = (t57 & t59);
    t65 = (t61 & t63);
    t66 = (~(t64));
    t67 = (~(t65));
    t68 = *((unsigned int *)t46);
    *((unsigned int *)t46) = (t68 & t66);
    t69 = *((unsigned int *)t46);
    *((unsigned int *)t46) = (t69 & t67);
    t70 = *((unsigned int *)t40);
    *((unsigned int *)t40) = (t70 & t66);
    t71 = *((unsigned int *)t40);
    *((unsigned int *)t40) = (t71 & t67);
    goto LAB25;

LAB26:    *((unsigned int *)t72) = 1;
    goto LAB29;

LAB28:    t79 = (t72 + 4);
    *((unsigned int *)t72) = 1;
    *((unsigned int *)t79) = 1;
    goto LAB29;

LAB30:    t86 = (t0 + 2256U);
    t87 = *((char **)t86);
    memset(t85, 0, 8);
    t86 = (t87 + 4);
    t88 = *((unsigned int *)t86);
    t89 = (~(t88));
    t90 = *((unsigned int *)t87);
    t91 = (t90 & t89);
    t92 = (t91 & 1U);
    if (t92 != 0)
        goto LAB36;

LAB34:    if (*((unsigned int *)t86) == 0)
        goto LAB33;

LAB35:    t93 = (t85 + 4);
    *((unsigned int *)t85) = 1;
    *((unsigned int *)t93) = 1;

LAB36:    memset(t94, 0, 8);
    t95 = (t85 + 4);
    t96 = *((unsigned int *)t95);
    t97 = (~(t96));
    t98 = *((unsigned int *)t85);
    t99 = (t98 & t97);
    t100 = (t99 & 1U);
    if (t100 != 0)
        goto LAB37;

LAB38:    if (*((unsigned int *)t95) != 0)
        goto LAB39;

LAB40:    t102 = (t94 + 4);
    t103 = *((unsigned int *)t94);
    t104 = *((unsigned int *)t102);
    t105 = (t103 || t104);
    if (t105 > 0)
        goto LAB41;

LAB42:    memcpy(t117, t94, 8);

LAB43:    memset(t149, 0, 8);
    t150 = (t117 + 4);
    t151 = *((unsigned int *)t150);
    t152 = (~(t151));
    t153 = *((unsigned int *)t117);
    t154 = (t153 & t152);
    t155 = (t154 & 1U);
    if (t155 != 0)
        goto LAB51;

LAB52:    if (*((unsigned int *)t150) != 0)
        goto LAB53;

LAB54:    t158 = *((unsigned int *)t72);
    t159 = *((unsigned int *)t149);
    t160 = (t158 | t159);
    *((unsigned int *)t157) = t160;
    t161 = (t72 + 4);
    t162 = (t149 + 4);
    t163 = (t157 + 4);
    t164 = *((unsigned int *)t161);
    t165 = *((unsigned int *)t162);
    t166 = (t164 | t165);
    *((unsigned int *)t163) = t166;
    t167 = *((unsigned int *)t163);
    t168 = (t167 != 0);
    if (t168 == 1)
        goto LAB55;

LAB56:
LAB57:    goto LAB32;

LAB33:    *((unsigned int *)t85) = 1;
    goto LAB36;

LAB37:    *((unsigned int *)t94) = 1;
    goto LAB40;

LAB39:    t101 = (t94 + 4);
    *((unsigned int *)t94) = 1;
    *((unsigned int *)t101) = 1;
    goto LAB40;

LAB41:    t106 = (t0 + 4096);
    t107 = (t106 + 56U);
    t108 = *((char **)t107);
    memset(t109, 0, 8);
    t110 = (t108 + 4);
    t111 = *((unsigned int *)t110);
    t112 = (~(t111));
    t113 = *((unsigned int *)t108);
    t114 = (t113 & t112);
    t115 = (t114 & 1U);
    if (t115 != 0)
        goto LAB44;

LAB45:    if (*((unsigned int *)t110) != 0)
        goto LAB46;

LAB47:    t118 = *((unsigned int *)t94);
    t119 = *((unsigned int *)t109);
    t120 = (t118 & t119);
    *((unsigned int *)t117) = t120;
    t121 = (t94 + 4);
    t122 = (t109 + 4);
    t123 = (t117 + 4);
    t124 = *((unsigned int *)t121);
    t125 = *((unsigned int *)t122);
    t126 = (t124 | t125);
    *((unsigned int *)t123) = t126;
    t127 = *((unsigned int *)t123);
    t128 = (t127 != 0);
    if (t128 == 1)
        goto LAB48;

LAB49:
LAB50:    goto LAB43;

LAB44:    *((unsigned int *)t109) = 1;
    goto LAB47;

LAB46:    t116 = (t109 + 4);
    *((unsigned int *)t109) = 1;
    *((unsigned int *)t116) = 1;
    goto LAB47;

LAB48:    t129 = *((unsigned int *)t117);
    t130 = *((unsigned int *)t123);
    *((unsigned int *)t117) = (t129 | t130);
    t131 = (t94 + 4);
    t132 = (t109 + 4);
    t133 = *((unsigned int *)t94);
    t134 = (~(t133));
    t135 = *((unsigned int *)t131);
    t136 = (~(t135));
    t137 = *((unsigned int *)t109);
    t138 = (~(t137));
    t139 = *((unsigned int *)t132);
    t140 = (~(t139));
    t141 = (t134 & t136);
    t142 = (t138 & t140);
    t143 = (~(t141));
    t144 = (~(t142));
    t145 = *((unsigned int *)t123);
    *((unsigned int *)t123) = (t145 & t143);
    t146 = *((unsigned int *)t123);
    *((unsigned int *)t123) = (t146 & t144);
    t147 = *((unsigned int *)t117);
    *((unsigned int *)t117) = (t147 & t143);
    t148 = *((unsigned int *)t117);
    *((unsigned int *)t117) = (t148 & t144);
    goto LAB50;

LAB51:    *((unsigned int *)t149) = 1;
    goto LAB54;

LAB53:    t156 = (t149 + 4);
    *((unsigned int *)t149) = 1;
    *((unsigned int *)t156) = 1;
    goto LAB54;

LAB55:    t169 = *((unsigned int *)t157);
    t170 = *((unsigned int *)t163);
    *((unsigned int *)t157) = (t169 | t170);
    t171 = (t72 + 4);
    t172 = (t149 + 4);
    t173 = *((unsigned int *)t171);
    t174 = (~(t173));
    t175 = *((unsigned int *)t72);
    t176 = (t175 & t174);
    t177 = *((unsigned int *)t172);
    t178 = (~(t177));
    t179 = *((unsigned int *)t149);
    t180 = (t179 & t178);
    t181 = (~(t176));
    t182 = (~(t180));
    t183 = *((unsigned int *)t163);
    *((unsigned int *)t163) = (t183 & t181);
    t184 = *((unsigned int *)t163);
    *((unsigned int *)t163) = (t184 & t182);
    goto LAB57;

LAB58:    *((unsigned int *)t185) = 1;
    goto LAB61;

LAB60:    t192 = (t185 + 4);
    *((unsigned int *)t185) = 1;
    *((unsigned int *)t192) = 1;
    goto LAB61;

LAB62:    t199 = (t0 + 2096U);
    t200 = *((char **)t199);
    memset(t198, 0, 8);
    t199 = (t200 + 4);
    t201 = *((unsigned int *)t199);
    t202 = (~(t201));
    t203 = *((unsigned int *)t200);
    t204 = (t203 & t202);
    t205 = (t204 & 1U);
    if (t205 != 0)
        goto LAB68;

LAB66:    if (*((unsigned int *)t199) == 0)
        goto LAB65;

LAB67:    t206 = (t198 + 4);
    *((unsigned int *)t198) = 1;
    *((unsigned int *)t206) = 1;

LAB68:    memset(t207, 0, 8);
    t208 = (t198 + 4);
    t209 = *((unsigned int *)t208);
    t210 = (~(t209));
    t211 = *((unsigned int *)t198);
    t212 = (t211 & t210);
    t213 = (t212 & 1U);
    if (t213 != 0)
        goto LAB69;

LAB70:    if (*((unsigned int *)t208) != 0)
        goto LAB71;

LAB72:    t215 = (t207 + 4);
    t216 = *((unsigned int *)t207);
    t217 = *((unsigned int *)t215);
    t218 = (t216 || t217);
    if (t218 > 0)
        goto LAB73;

LAB74:    memcpy(t230, t207, 8);

LAB75:    memset(t262, 0, 8);
    t263 = (t230 + 4);
    t264 = *((unsigned int *)t263);
    t265 = (~(t264));
    t266 = *((unsigned int *)t230);
    t267 = (t266 & t265);
    t268 = (t267 & 1U);
    if (t268 != 0)
        goto LAB83;

LAB84:    if (*((unsigned int *)t263) != 0)
        goto LAB85;

LAB86:    t271 = *((unsigned int *)t185);
    t272 = *((unsigned int *)t262);
    t273 = (t271 | t272);
    *((unsigned int *)t270) = t273;
    t274 = (t185 + 4);
    t275 = (t262 + 4);
    t276 = (t270 + 4);
    t277 = *((unsigned int *)t274);
    t278 = *((unsigned int *)t275);
    t279 = (t277 | t278);
    *((unsigned int *)t276) = t279;
    t280 = *((unsigned int *)t276);
    t281 = (t280 != 0);
    if (t281 == 1)
        goto LAB87;

LAB88:
LAB89:    goto LAB64;

LAB65:    *((unsigned int *)t198) = 1;
    goto LAB68;

LAB69:    *((unsigned int *)t207) = 1;
    goto LAB72;

LAB71:    t214 = (t207 + 4);
    *((unsigned int *)t207) = 1;
    *((unsigned int *)t214) = 1;
    goto LAB72;

LAB73:    t219 = (t0 + 3936);
    t220 = (t219 + 56U);
    t221 = *((char **)t220);
    memset(t222, 0, 8);
    t223 = (t221 + 4);
    t224 = *((unsigned int *)t223);
    t225 = (~(t224));
    t226 = *((unsigned int *)t221);
    t227 = (t226 & t225);
    t228 = (t227 & 1U);
    if (t228 != 0)
        goto LAB76;

LAB77:    if (*((unsigned int *)t223) != 0)
        goto LAB78;

LAB79:    t231 = *((unsigned int *)t207);
    t232 = *((unsigned int *)t222);
    t233 = (t231 & t232);
    *((unsigned int *)t230) = t233;
    t234 = (t207 + 4);
    t235 = (t222 + 4);
    t236 = (t230 + 4);
    t237 = *((unsigned int *)t234);
    t238 = *((unsigned int *)t235);
    t239 = (t237 | t238);
    *((unsigned int *)t236) = t239;
    t240 = *((unsigned int *)t236);
    t241 = (t240 != 0);
    if (t241 == 1)
        goto LAB80;

LAB81:
LAB82:    goto LAB75;

LAB76:    *((unsigned int *)t222) = 1;
    goto LAB79;

LAB78:    t229 = (t222 + 4);
    *((unsigned int *)t222) = 1;
    *((unsigned int *)t229) = 1;
    goto LAB79;

LAB80:    t242 = *((unsigned int *)t230);
    t243 = *((unsigned int *)t236);
    *((unsigned int *)t230) = (t242 | t243);
    t244 = (t207 + 4);
    t245 = (t222 + 4);
    t246 = *((unsigned int *)t207);
    t247 = (~(t246));
    t248 = *((unsigned int *)t244);
    t249 = (~(t248));
    t250 = *((unsigned int *)t222);
    t251 = (~(t250));
    t252 = *((unsigned int *)t245);
    t253 = (~(t252));
    t254 = (t247 & t249);
    t255 = (t251 & t253);
    t256 = (~(t254));
    t257 = (~(t255));
    t258 = *((unsigned int *)t236);
    *((unsigned int *)t236) = (t258 & t256);
    t259 = *((unsigned int *)t236);
    *((unsigned int *)t236) = (t259 & t257);
    t260 = *((unsigned int *)t230);
    *((unsigned int *)t230) = (t260 & t256);
    t261 = *((unsigned int *)t230);
    *((unsigned int *)t230) = (t261 & t257);
    goto LAB82;

LAB83:    *((unsigned int *)t262) = 1;
    goto LAB86;

LAB85:    t269 = (t262 + 4);
    *((unsigned int *)t262) = 1;
    *((unsigned int *)t269) = 1;
    goto LAB86;

LAB87:    t282 = *((unsigned int *)t270);
    t283 = *((unsigned int *)t276);
    *((unsigned int *)t270) = (t282 | t283);
    t284 = (t185 + 4);
    t285 = (t262 + 4);
    t286 = *((unsigned int *)t284);
    t287 = (~(t286));
    t288 = *((unsigned int *)t185);
    t289 = (t288 & t287);
    t290 = *((unsigned int *)t285);
    t291 = (~(t290));
    t292 = *((unsigned int *)t262);
    t293 = (t292 & t291);
    t294 = (~(t289));
    t295 = (~(t293));
    t296 = *((unsigned int *)t276);
    *((unsigned int *)t276) = (t296 & t294);
    t297 = *((unsigned int *)t276);
    *((unsigned int *)t276) = (t297 & t295);
    goto LAB89;

}

static void NetDecl_71_6(char *t0)
{
    char t6[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
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
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    int t30;
    int t31;
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
    unsigned int t43;
    unsigned int t44;
    char *t45;
    unsigned int t46;
    unsigned int t47;
    char *t48;
    unsigned int t49;
    unsigned int t50;
    char *t51;

LAB0:    t1 = (t0 + 7136U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(71, ng0);
    t2 = (t0 + 2096U);
    t3 = *((char **)t2);
    t2 = (t0 + 4096);
    t4 = (t2 + 56U);
    t5 = *((char **)t4);
    t7 = *((unsigned int *)t3);
    t8 = *((unsigned int *)t5);
    t9 = (t7 & t8);
    *((unsigned int *)t6) = t9;
    t10 = (t3 + 4);
    t11 = (t5 + 4);
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
LAB6:    t38 = (t0 + 9056);
    t39 = (t38 + 56U);
    t40 = *((char **)t39);
    t41 = (t40 + 56U);
    t42 = *((char **)t41);
    memset(t42, 0, 8);
    t43 = 1U;
    t44 = t43;
    t45 = (t6 + 4);
    t46 = *((unsigned int *)t6);
    t43 = (t43 & t46);
    t47 = *((unsigned int *)t45);
    t44 = (t44 & t47);
    t48 = (t42 + 4);
    t49 = *((unsigned int *)t42);
    *((unsigned int *)t42) = (t49 | t43);
    t50 = *((unsigned int *)t48);
    *((unsigned int *)t48) = (t50 | t44);
    xsi_driver_vfirst_trans(t38, 0, 0U);
    t51 = (t0 + 8544);
    *((int *)t51) = 1;

LAB1:    return;
LAB4:    t18 = *((unsigned int *)t6);
    t19 = *((unsigned int *)t12);
    *((unsigned int *)t6) = (t18 | t19);
    t20 = (t3 + 4);
    t21 = (t5 + 4);
    t22 = *((unsigned int *)t3);
    t23 = (~(t22));
    t24 = *((unsigned int *)t20);
    t25 = (~(t24));
    t26 = *((unsigned int *)t5);
    t27 = (~(t26));
    t28 = *((unsigned int *)t21);
    t29 = (~(t28));
    t30 = (t23 & t25);
    t31 = (t27 & t29);
    t32 = (~(t30));
    t33 = (~(t31));
    t34 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t34 & t32);
    t35 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t35 & t33);
    t36 = *((unsigned int *)t6);
    *((unsigned int *)t6) = (t36 & t32);
    t37 = *((unsigned int *)t6);
    *((unsigned int *)t6) = (t37 & t33);
    goto LAB6;

}

static void Initial_76_7(char *t0)
{
    char *t1;
    char *t2;

LAB0:    xsi_set_current_line(77, ng0);

LAB2:    xsi_set_current_line(78, ng0);
    t1 = ((char*)((ng1)));
    t2 = (t0 + 4256);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 34);
    xsi_set_current_line(79, ng0);
    t1 = ((char*)((ng1)));
    t2 = (t0 + 4416);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 34);
    xsi_set_current_line(80, ng0);
    t1 = ((char*)((ng2)));
    t2 = (t0 + 4096);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 1);
    xsi_set_current_line(81, ng0);
    t1 = ((char*)((ng3)));
    t2 = (t0 + 3936);
    xsi_vlogvar_assign_value(t2, t1, 0, 0, 1);

LAB1:    return;
}

static void Always_86_8(char *t0)
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

LAB0:    t1 = (t0 + 7632U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(86, ng0);
    t2 = (t0 + 8560);
    *((int *)t2) = 1;
    t3 = (t0 + 7664);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(87, ng0);

LAB5:    xsi_set_current_line(88, ng0);
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

LAB11:    xsi_set_current_line(94, ng0);

LAB14:    xsi_set_current_line(95, ng0);
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

LAB16:    xsi_set_current_line(100, ng0);
    t2 = (t0 + 2096U);
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

LAB38:    xsi_set_current_line(105, ng0);
    t2 = (t0 + 2256U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB45;

LAB46:    if (*((unsigned int *)t2) != 0)
        goto LAB47;

LAB48:    t6 = (t4 + 4);
    t14 = *((unsigned int *)t4);
    t15 = *((unsigned int *)t6);
    t16 = (t14 || t15);
    if (t16 > 0)
        goto LAB49;

LAB50:    memcpy(t32, t4, 8);

LAB51:    t64 = (t32 + 4);
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

LAB10:    xsi_set_current_line(89, ng0);

LAB13:    xsi_set_current_line(90, ng0);
    t19 = ((char*)((ng2)));
    t20 = (t0 + 4096);
    xsi_vlogvar_wait_assign_value(t20, t19, 0, 0, 1, 0LL);
    xsi_set_current_line(91, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 3936);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB12;

LAB15:    xsi_set_current_line(96, ng0);

LAB18:    xsi_set_current_line(97, ng0);
    t5 = ((char*)((ng2)));
    t6 = (t0 + 4096);
    xsi_vlogvar_wait_assign_value(t6, t5, 0, 0, 1, 0LL);
    xsi_set_current_line(98, ng0);
    t2 = ((char*)((ng3)));
    t3 = (t0 + 3936);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB17;

LAB19:    *((unsigned int *)t4) = 1;
    goto LAB22;

LAB21:    t5 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t5) = 1;
    goto LAB22;

LAB23:    t12 = (t0 + 2256U);
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

LAB37:    xsi_set_current_line(101, ng0);

LAB40:    xsi_set_current_line(102, ng0);
    t70 = ((char*)((ng3)));
    t71 = (t0 + 4096);
    xsi_vlogvar_wait_assign_value(t71, t70, 0, 0, 1, 0LL);
    xsi_set_current_line(103, ng0);
    t2 = (t0 + 4096);
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

LAB44:    t13 = (t0 + 3936);
    xsi_vlogvar_wait_assign_value(t13, t4, 0, 0, 1, 0LL);
    goto LAB39;

LAB41:    *((unsigned int *)t4) = 1;
    goto LAB44;

LAB45:    *((unsigned int *)t4) = 1;
    goto LAB48;

LAB47:    t5 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t5) = 1;
    goto LAB48;

LAB49:    t12 = (t0 + 2096U);
    t13 = *((char **)t12);
    memset(t21, 0, 8);
    t12 = (t13 + 4);
    t17 = *((unsigned int *)t12);
    t18 = (~(t17));
    t22 = *((unsigned int *)t13);
    t23 = (t22 & t18);
    t24 = (t23 & 1U);
    if (t24 != 0)
        goto LAB55;

LAB53:    if (*((unsigned int *)t12) == 0)
        goto LAB52;

LAB54:    t19 = (t21 + 4);
    *((unsigned int *)t21) = 1;
    *((unsigned int *)t19) = 1;

LAB55:    memset(t25, 0, 8);
    t20 = (t21 + 4);
    t26 = *((unsigned int *)t20);
    t27 = (~(t26));
    t28 = *((unsigned int *)t21);
    t29 = (t28 & t27);
    t30 = (t29 & 1U);
    if (t30 != 0)
        goto LAB56;

LAB57:    if (*((unsigned int *)t20) != 0)
        goto LAB58;

LAB59:    t33 = *((unsigned int *)t4);
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
        goto LAB60;

LAB61:
LAB62:    goto LAB51;

LAB52:    *((unsigned int *)t21) = 1;
    goto LAB55;

LAB56:    *((unsigned int *)t25) = 1;
    goto LAB59;

LAB58:    t31 = (t25 + 4);
    *((unsigned int *)t25) = 1;
    *((unsigned int *)t31) = 1;
    goto LAB59;

LAB60:    t44 = *((unsigned int *)t32);
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
    goto LAB62;

LAB63:    xsi_set_current_line(106, ng0);

LAB66:    xsi_set_current_line(107, ng0);
    t70 = ((char*)((ng3)));
    t71 = (t0 + 3936);
    xsi_vlogvar_wait_assign_value(t71, t70, 0, 0, 1, 0LL);
    xsi_set_current_line(108, ng0);
    t2 = (t0 + 3936);
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

LAB70:    t13 = (t0 + 4096);
    xsi_vlogvar_wait_assign_value(t13, t4, 0, 0, 1, 0LL);
    goto LAB65;

LAB67:    *((unsigned int *)t4) = 1;
    goto LAB70;

}

static void Always_115_9(char *t0)
{
    char t4[16];
    char t9[16];
    char t55[16];
    char t61[16];
    char t108[16];
    char t151[16];
    char t157[16];
    char t204[16];
    char t248[8];
    char *t1;
    char *t2;
    char *t3;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    char *t20;
    unsigned int t21;
    char *t22;
    unsigned int t23;
    char *t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    char *t33;
    unsigned int t34;
    char *t35;
    char *t36;
    unsigned int t37;
    char *t38;
    unsigned int t39;
    unsigned int t40;
    unsigned int t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    unsigned int t45;
    unsigned int t46;
    int t47;
    int t48;
    unsigned int t49;
    unsigned int t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    unsigned int t54;
    char *t56;
    char *t57;
    char *t58;
    char *t59;
    char *t60;
    unsigned int t62;
    unsigned int t63;
    unsigned int t64;
    char *t65;
    char *t66;
    char *t67;
    unsigned int t68;
    unsigned int t69;
    unsigned int t70;
    unsigned int t71;
    unsigned int t72;
    char *t73;
    unsigned int t74;
    char *t75;
    unsigned int t76;
    char *t77;
    unsigned int t78;
    unsigned int t79;
    unsigned int t80;
    unsigned int t81;
    unsigned int t82;
    unsigned int t83;
    unsigned int t84;
    unsigned int t85;
    char *t86;
    unsigned int t87;
    char *t88;
    char *t89;
    unsigned int t90;
    char *t91;
    unsigned int t92;
    unsigned int t93;
    unsigned int t94;
    unsigned int t95;
    unsigned int t96;
    unsigned int t97;
    unsigned int t98;
    unsigned int t99;
    int t100;
    int t101;
    unsigned int t102;
    unsigned int t103;
    unsigned int t104;
    unsigned int t105;
    unsigned int t106;
    unsigned int t107;
    unsigned int t109;
    unsigned int t110;
    unsigned int t111;
    char *t112;
    char *t113;
    char *t114;
    unsigned int t115;
    unsigned int t116;
    unsigned int t117;
    unsigned int t118;
    unsigned int t119;
    char *t120;
    unsigned int t121;
    char *t122;
    unsigned int t123;
    char *t124;
    unsigned int t125;
    unsigned int t126;
    unsigned int t127;
    unsigned int t128;
    unsigned int t129;
    unsigned int t130;
    unsigned int t131;
    unsigned int t132;
    char *t133;
    unsigned int t134;
    char *t135;
    char *t136;
    unsigned int t137;
    char *t138;
    unsigned int t139;
    unsigned int t140;
    unsigned int t141;
    int t142;
    unsigned int t143;
    unsigned int t144;
    unsigned int t145;
    int t146;
    unsigned int t147;
    unsigned int t148;
    unsigned int t149;
    unsigned int t150;
    char *t152;
    char *t153;
    char *t154;
    char *t155;
    char *t156;
    unsigned int t158;
    unsigned int t159;
    unsigned int t160;
    char *t161;
    char *t162;
    char *t163;
    unsigned int t164;
    unsigned int t165;
    unsigned int t166;
    unsigned int t167;
    unsigned int t168;
    char *t169;
    unsigned int t170;
    char *t171;
    unsigned int t172;
    char *t173;
    unsigned int t174;
    unsigned int t175;
    unsigned int t176;
    unsigned int t177;
    unsigned int t178;
    unsigned int t179;
    unsigned int t180;
    unsigned int t181;
    char *t182;
    unsigned int t183;
    char *t184;
    char *t185;
    unsigned int t186;
    char *t187;
    unsigned int t188;
    unsigned int t189;
    unsigned int t190;
    unsigned int t191;
    unsigned int t192;
    unsigned int t193;
    unsigned int t194;
    unsigned int t195;
    int t196;
    int t197;
    unsigned int t198;
    unsigned int t199;
    unsigned int t200;
    unsigned int t201;
    unsigned int t202;
    unsigned int t203;
    unsigned int t205;
    unsigned int t206;
    unsigned int t207;
    char *t208;
    char *t209;
    char *t210;
    unsigned int t211;
    unsigned int t212;
    unsigned int t213;
    unsigned int t214;
    unsigned int t215;
    char *t216;
    unsigned int t217;
    char *t218;
    unsigned int t219;
    char *t220;
    unsigned int t221;
    unsigned int t222;
    unsigned int t223;
    unsigned int t224;
    unsigned int t225;
    unsigned int t226;
    unsigned int t227;
    unsigned int t228;
    char *t229;
    unsigned int t230;
    char *t231;
    char *t232;
    unsigned int t233;
    char *t234;
    unsigned int t235;
    unsigned int t236;
    unsigned int t237;
    int t238;
    unsigned int t239;
    unsigned int t240;
    unsigned int t241;
    int t242;
    unsigned int t243;
    unsigned int t244;
    unsigned int t245;
    unsigned int t246;
    char *t247;

LAB0:    t1 = (t0 + 7880U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(115, ng0);
    t2 = (t0 + 8576);
    *((int *)t2) = 1;
    t3 = (t0 + 7912);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(116, ng0);

LAB5:    xsi_set_current_line(128, ng0);

LAB6:    xsi_set_current_line(129, ng0);
    t5 = ((char*)((ng4)));
    t6 = (t0 + 3056U);
    t7 = *((char **)t6);
    xsi_vlog_mul_concat(t4, 34, 1, t5, 1U, t7, 1);
    t6 = (t0 + 1936U);
    t8 = *((char **)t6);
    t10 = 0;

LAB10:    t11 = (t10 < 2);
    if (t11 == 1)
        goto LAB11;

LAB12:    t56 = ((char*)((ng4)));
    t57 = (t0 + 3216U);
    t58 = *((char **)t57);
    xsi_vlog_mul_concat(t55, 34, 1, t56, 1U, t58, 1);
    t57 = (t0 + 4416);
    t59 = (t57 + 56U);
    t60 = *((char **)t59);
    t62 = 0;

LAB16:    t63 = (t62 < 2);
    if (t63 == 1)
        goto LAB17;

LAB18:    t109 = 0;

LAB22:    t110 = (t109 < 2);
    if (t110 == 1)
        goto LAB23;

LAB24:    t152 = ((char*)((ng4)));
    t153 = (t0 + 3376U);
    t154 = *((char **)t153);
    xsi_vlog_mul_concat(t151, 34, 1, t152, 1U, t154, 1);
    t153 = (t0 + 4256);
    t155 = (t153 + 56U);
    t156 = *((char **)t155);
    t158 = 0;

LAB28:    t159 = (t158 < 2);
    if (t159 == 1)
        goto LAB29;

LAB30:    t205 = 0;

LAB34:    t206 = (t205 < 2);
    if (t206 == 1)
        goto LAB35;

LAB36:    t247 = (t0 + 4256);
    xsi_vlogvar_wait_assign_value(t247, t204, 0, 0, 34, 0LL);
    xsi_set_current_line(131, ng0);
    t2 = (t0 + 3536U);
    t3 = *((char **)t2);
    memset(t248, 0, 8);
    t2 = (t3 + 4);
    t10 = *((unsigned int *)t2);
    t11 = (~(t10));
    t12 = *((unsigned int *)t3);
    t15 = (t12 & t11);
    t16 = (t15 & 1U);
    if (t16 != 0)
        goto LAB37;

LAB38:    if (*((unsigned int *)t2) != 0)
        goto LAB39;

LAB40:    t6 = (t248 + 4);
    t17 = *((unsigned int *)t248);
    t18 = *((unsigned int *)t6);
    t19 = (t17 || t18);
    if (t19 > 0)
        goto LAB41;

LAB42:    t21 = *((unsigned int *)t248);
    t23 = (~(t21));
    t25 = *((unsigned int *)t6);
    t26 = (t23 || t25);
    if (t26 > 0)
        goto LAB43;

LAB44:    if (*((unsigned int *)t6) > 0)
        goto LAB45;

LAB46:    if (*((unsigned int *)t248) > 0)
        goto LAB47;

LAB48:    memcpy(t4, t14, 16);

LAB49:    t20 = (t0 + 4416);
    xsi_vlogvar_wait_assign_value(t20, t4, 0, 0, 34, 0LL);
    goto LAB2;

LAB7:    t30 = (t10 * 8);
    t31 = *((unsigned int *)t14);
    t32 = *((unsigned int *)t24);
    *((unsigned int *)t14) = (t31 | t32);
    t33 = (t4 + t30);
    t34 = (t30 + 4);
    t35 = (t4 + t34);
    t36 = (t8 + t30);
    t37 = (t30 + 4);
    t38 = (t8 + t37);
    t39 = *((unsigned int *)t33);
    t40 = (~(t39));
    t41 = *((unsigned int *)t35);
    t42 = (~(t41));
    t43 = *((unsigned int *)t36);
    t44 = (~(t43));
    t45 = *((unsigned int *)t38);
    t46 = (~(t45));
    t47 = (t40 & t42);
    t48 = (t44 & t46);
    t49 = (~(t47));
    t50 = (~(t48));
    t51 = *((unsigned int *)t24);
    *((unsigned int *)t24) = (t51 & t49);
    t52 = *((unsigned int *)t24);
    *((unsigned int *)t24) = (t52 & t50);
    t53 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t53 & t49);
    t54 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t54 & t50);

LAB9:    t10 = (t10 + 1);
    goto LAB10;

LAB8:    goto LAB9;

LAB11:    t12 = (t10 * 8);
    t6 = (t4 + t12);
    t13 = (t8 + t12);
    t14 = (t9 + t12);
    t15 = *((unsigned int *)t6);
    t16 = *((unsigned int *)t13);
    t17 = (t15 & t16);
    *((unsigned int *)t14) = t17;
    t18 = (t10 * 8);
    t19 = (t18 + 4);
    t20 = (t4 + t19);
    t21 = (t18 + 4);
    t22 = (t8 + t21);
    t23 = (t18 + 4);
    t24 = (t9 + t23);
    t25 = *((unsigned int *)t20);
    t26 = *((unsigned int *)t22);
    t27 = (t25 | t26);
    *((unsigned int *)t24) = t27;
    t28 = *((unsigned int *)t24);
    t29 = (t28 != 0);
    if (t29 == 1)
        goto LAB7;
    else
        goto LAB8;

LAB13:    t83 = (t62 * 8);
    t84 = *((unsigned int *)t67);
    t85 = *((unsigned int *)t77);
    *((unsigned int *)t67) = (t84 | t85);
    t86 = (t55 + t83);
    t87 = (t83 + 4);
    t88 = (t55 + t87);
    t89 = (t60 + t83);
    t90 = (t83 + 4);
    t91 = (t60 + t90);
    t92 = *((unsigned int *)t86);
    t93 = (~(t92));
    t94 = *((unsigned int *)t88);
    t95 = (~(t94));
    t96 = *((unsigned int *)t89);
    t97 = (~(t96));
    t98 = *((unsigned int *)t91);
    t99 = (~(t98));
    t100 = (t93 & t95);
    t101 = (t97 & t99);
    t102 = (~(t100));
    t103 = (~(t101));
    t104 = *((unsigned int *)t77);
    *((unsigned int *)t77) = (t104 & t102);
    t105 = *((unsigned int *)t77);
    *((unsigned int *)t77) = (t105 & t103);
    t106 = *((unsigned int *)t67);
    *((unsigned int *)t67) = (t106 & t102);
    t107 = *((unsigned int *)t67);
    *((unsigned int *)t67) = (t107 & t103);

LAB15:    t62 = (t62 + 1);
    goto LAB16;

LAB14:    goto LAB15;

LAB17:    t64 = (t62 * 8);
    t65 = (t55 + t64);
    t66 = (t60 + t64);
    t67 = (t61 + t64);
    t68 = *((unsigned int *)t65);
    t69 = *((unsigned int *)t66);
    t70 = (t68 & t69);
    *((unsigned int *)t67) = t70;
    t71 = (t62 * 8);
    t72 = (t71 + 4);
    t73 = (t55 + t72);
    t74 = (t71 + 4);
    t75 = (t60 + t74);
    t76 = (t71 + 4);
    t77 = (t61 + t76);
    t78 = *((unsigned int *)t73);
    t79 = *((unsigned int *)t75);
    t80 = (t78 | t79);
    *((unsigned int *)t77) = t80;
    t81 = *((unsigned int *)t77);
    t82 = (t81 != 0);
    if (t82 == 1)
        goto LAB13;
    else
        goto LAB14;

LAB19:    t130 = (t109 * 8);
    t131 = *((unsigned int *)t114);
    t132 = *((unsigned int *)t124);
    *((unsigned int *)t114) = (t131 | t132);
    t133 = (t9 + t130);
    t134 = (t130 + 4);
    t135 = (t9 + t134);
    t136 = (t61 + t130);
    t137 = (t130 + 4);
    t138 = (t61 + t137);
    t139 = *((unsigned int *)t135);
    t140 = (~(t139));
    t141 = *((unsigned int *)t133);
    t142 = (t141 & t140);
    t143 = *((unsigned int *)t138);
    t144 = (~(t143));
    t145 = *((unsigned int *)t136);
    t146 = (t145 & t144);
    t147 = (~(t142));
    t148 = (~(t146));
    t149 = *((unsigned int *)t124);
    *((unsigned int *)t124) = (t149 & t147);
    t150 = *((unsigned int *)t124);
    *((unsigned int *)t124) = (t150 & t148);

LAB21:    t109 = (t109 + 1);
    goto LAB22;

LAB20:    goto LAB21;

LAB23:    t111 = (t109 * 8);
    t112 = (t9 + t111);
    t113 = (t61 + t111);
    t114 = (t108 + t111);
    t115 = *((unsigned int *)t112);
    t116 = *((unsigned int *)t113);
    t117 = (t115 | t116);
    *((unsigned int *)t114) = t117;
    t118 = (t109 * 8);
    t119 = (t118 + 4);
    t120 = (t9 + t119);
    t121 = (t118 + 4);
    t122 = (t61 + t121);
    t123 = (t118 + 4);
    t124 = (t108 + t123);
    t125 = *((unsigned int *)t120);
    t126 = *((unsigned int *)t122);
    t127 = (t125 | t126);
    *((unsigned int *)t124) = t127;
    t128 = *((unsigned int *)t124);
    t129 = (t128 != 0);
    if (t129 == 1)
        goto LAB19;
    else
        goto LAB20;

LAB25:    t179 = (t158 * 8);
    t180 = *((unsigned int *)t163);
    t181 = *((unsigned int *)t173);
    *((unsigned int *)t163) = (t180 | t181);
    t182 = (t151 + t179);
    t183 = (t179 + 4);
    t184 = (t151 + t183);
    t185 = (t156 + t179);
    t186 = (t179 + 4);
    t187 = (t156 + t186);
    t188 = *((unsigned int *)t182);
    t189 = (~(t188));
    t190 = *((unsigned int *)t184);
    t191 = (~(t190));
    t192 = *((unsigned int *)t185);
    t193 = (~(t192));
    t194 = *((unsigned int *)t187);
    t195 = (~(t194));
    t196 = (t189 & t191);
    t197 = (t193 & t195);
    t198 = (~(t196));
    t199 = (~(t197));
    t200 = *((unsigned int *)t173);
    *((unsigned int *)t173) = (t200 & t198);
    t201 = *((unsigned int *)t173);
    *((unsigned int *)t173) = (t201 & t199);
    t202 = *((unsigned int *)t163);
    *((unsigned int *)t163) = (t202 & t198);
    t203 = *((unsigned int *)t163);
    *((unsigned int *)t163) = (t203 & t199);

LAB27:    t158 = (t158 + 1);
    goto LAB28;

LAB26:    goto LAB27;

LAB29:    t160 = (t158 * 8);
    t161 = (t151 + t160);
    t162 = (t156 + t160);
    t163 = (t157 + t160);
    t164 = *((unsigned int *)t161);
    t165 = *((unsigned int *)t162);
    t166 = (t164 & t165);
    *((unsigned int *)t163) = t166;
    t167 = (t158 * 8);
    t168 = (t167 + 4);
    t169 = (t151 + t168);
    t170 = (t167 + 4);
    t171 = (t156 + t170);
    t172 = (t167 + 4);
    t173 = (t157 + t172);
    t174 = *((unsigned int *)t169);
    t175 = *((unsigned int *)t171);
    t176 = (t174 | t175);
    *((unsigned int *)t173) = t176;
    t177 = *((unsigned int *)t173);
    t178 = (t177 != 0);
    if (t178 == 1)
        goto LAB25;
    else
        goto LAB26;

LAB31:    t226 = (t205 * 8);
    t227 = *((unsigned int *)t210);
    t228 = *((unsigned int *)t220);
    *((unsigned int *)t210) = (t227 | t228);
    t229 = (t108 + t226);
    t230 = (t226 + 4);
    t231 = (t108 + t230);
    t232 = (t157 + t226);
    t233 = (t226 + 4);
    t234 = (t157 + t233);
    t235 = *((unsigned int *)t231);
    t236 = (~(t235));
    t237 = *((unsigned int *)t229);
    t238 = (t237 & t236);
    t239 = *((unsigned int *)t234);
    t240 = (~(t239));
    t241 = *((unsigned int *)t232);
    t242 = (t241 & t240);
    t243 = (~(t238));
    t244 = (~(t242));
    t245 = *((unsigned int *)t220);
    *((unsigned int *)t220) = (t245 & t243);
    t246 = *((unsigned int *)t220);
    *((unsigned int *)t220) = (t246 & t244);

LAB33:    t205 = (t205 + 1);
    goto LAB34;

LAB32:    goto LAB33;

LAB35:    t207 = (t205 * 8);
    t208 = (t108 + t207);
    t209 = (t157 + t207);
    t210 = (t204 + t207);
    t211 = *((unsigned int *)t208);
    t212 = *((unsigned int *)t209);
    t213 = (t211 | t212);
    *((unsigned int *)t210) = t213;
    t214 = (t205 * 8);
    t215 = (t214 + 4);
    t216 = (t108 + t215);
    t217 = (t214 + 4);
    t218 = (t157 + t217);
    t219 = (t214 + 4);
    t220 = (t204 + t219);
    t221 = *((unsigned int *)t216);
    t222 = *((unsigned int *)t218);
    t223 = (t221 | t222);
    *((unsigned int *)t220) = t223;
    t224 = *((unsigned int *)t220);
    t225 = (t224 != 0);
    if (t225 == 1)
        goto LAB31;
    else
        goto LAB32;

LAB37:    *((unsigned int *)t248) = 1;
    goto LAB40;

LAB39:    t5 = (t248 + 4);
    *((unsigned int *)t248) = 1;
    *((unsigned int *)t5) = 1;
    goto LAB40;

LAB41:    t7 = (t0 + 1936U);
    t8 = *((char **)t7);
    goto LAB42;

LAB43:    t7 = (t0 + 4416);
    t13 = (t7 + 56U);
    t14 = *((char **)t13);
    goto LAB44;

LAB45:    xsi_vlog_unsigned_bit_combine(t4, 34, t8, 34, t14, 34);
    goto LAB49;

LAB47:    memcpy(t4, t8, 16);
    goto LAB49;

}

static void Always_139_10(char *t0)
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

LAB0:    t1 = (t0 + 8128U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(139, ng0);
    t2 = (t0 + 8592);
    *((int *)t2) = 1;
    t3 = (t0 + 8160);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(140, ng0);

LAB5:    t4 = (t0 + 280);
    xsi_vlog_namedbase_setdisablestate(t4, &&LAB6);
    t5 = (t0 + 7936);
    xsi_vlog_namedbase_pushprocess(t4, t5);

LAB7:    xsi_set_current_line(143, ng0);
    t6 = ((char*)((ng5)));
    t7 = (t0 + 4576);
    xsi_vlogvar_assign_value(t7, t6, 0, 0, 1);
    xsi_set_current_line(144, ng0);
    t2 = ((char*)((ng5)));
    t3 = (t0 + 4736);
    xsi_vlogvar_assign_value(t3, t2, 0, 0, 1);
    xsi_set_current_line(145, ng0);
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

LAB6:    t3 = (t0 + 7936);
    xsi_vlog_dispose_process_subprogram_invocation(t3);
    goto LAB2;

LAB8:    xsi_set_current_line(146, ng0);

LAB11:    xsi_set_current_line(147, ng0);
    t4 = (t0 + 4096);
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
LAB32:    xsi_set_current_line(152, ng0);
    t2 = (t0 + 3936);
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

LAB30:    xsi_set_current_line(148, ng0);

LAB33:    xsi_set_current_line(149, ng0);
    t79 = ((char*)((ng6)));
    t80 = (t0 + 4576);
    xsi_vlogvar_assign_value(t80, t79, 0, 0, 1);
    xsi_set_current_line(150, ng0);
    t2 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng7, 1, t2);
    goto LAB32;

LAB34:    *((unsigned int *)t13) = 1;
    goto LAB37;

LAB38:    *((unsigned int *)t20) = 1;
    goto LAB41;

LAB40:    t19 = (t20 + 4);
    *((unsigned int *)t20) = 1;
    *((unsigned int *)t19) = 1;
    goto LAB41;

LAB42:    t27 = (t0 + 2096U);
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

LAB56:    t79 = (t0 + 2256U);
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

LAB67:    t100 = ((char*)((ng3)));
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

LAB84:    xsi_set_current_line(153, ng0);

LAB87:    xsi_set_current_line(154, ng0);
    t183 = ((char*)((ng6)));
    t184 = (t0 + 4736);
    xsi_vlogvar_assign_value(t184, t183, 0, 0, 1);
    xsi_set_current_line(155, ng0);
    t2 = (t0 + 280);
    xsi_vlogfile_write(1, 0, 0, ng8, 1, t2);
    goto LAB86;

}


extern void worx_mktb2_m_08070838236131486829_3125375353_init()
{
	static char *pe[] = {(void *)Cont_62_0,(void *)Cont_63_1,(void *)Cont_64_2,(void *)NetDecl_68_3,(void *)NetDecl_69_4,(void *)NetDecl_70_5,(void *)NetDecl_71_6,(void *)Initial_76_7,(void *)Always_86_8,(void *)Always_115_9,(void *)Always_139_10};
	xsi_register_didat("worx_mktb2_m_08070838236131486829_3125375353", "isim/runsim.isim.sim/worx_mkTB2/m_08070838236131486829_3125375353.didat");
	xsi_register_executes(pe);
}
