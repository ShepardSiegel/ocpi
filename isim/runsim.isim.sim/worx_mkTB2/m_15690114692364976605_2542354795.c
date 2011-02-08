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
static const char *ng0 = "/home/shep/projects/ocpi/libsrc/hdl/ocpi/arSRLFIFO.v";
static unsigned int ng1[] = {0U, 0U};
static unsigned int ng2[] = {1U, 0U};
static int ng3[] = {1, 0};
static unsigned int ng4[] = {16U, 0U};
static int ng5[] = {0, 0};
static int ng6[] = {2, 0};



static void Always_30_0(char *t0)
{
    char t4[8];
    char t13[8];
    char t28[8];
    char t35[8];
    char t74[8];
    char t76[40];
    char t97[8];
    char t107[8];
    char t120[8];
    char t134[8];
    char t145[8];
    char t154[8];
    char t162[8];
    char t192[8];
    char t200[8];
    char t231[8];
    char t239[8];
    char t268[8];
    char t269[8];
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
    char *t14;
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
    char *t26;
    char *t27;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    unsigned int t32;
    unsigned int t33;
    char *t34;
    unsigned int t36;
    unsigned int t37;
    unsigned int t38;
    char *t39;
    char *t40;
    char *t41;
    unsigned int t42;
    unsigned int t43;
    unsigned int t44;
    unsigned int t45;
    unsigned int t46;
    unsigned int t47;
    unsigned int t48;
    char *t49;
    char *t50;
    unsigned int t51;
    unsigned int t52;
    unsigned int t53;
    int t54;
    unsigned int t55;
    unsigned int t56;
    unsigned int t57;
    int t58;
    unsigned int t59;
    unsigned int t60;
    unsigned int t61;
    unsigned int t62;
    char *t63;
    unsigned int t64;
    unsigned int t65;
    unsigned int t66;
    unsigned int t67;
    unsigned int t68;
    char *t69;
    char *t70;
    unsigned int t71;
    unsigned int t72;
    unsigned int t73;
    char *t75;
    char *t77;
    char *t78;
    char *t79;
    char *t80;
    char *t81;
    char *t82;
    char *t83;
    char *t84;
    char *t85;
    char *t86;
    int t87;
    int t88;
    int t89;
    unsigned int t90;
    unsigned int t91;
    unsigned int t92;
    unsigned int t93;
    unsigned int t94;
    unsigned int t95;
    unsigned int t96;
    unsigned int t98;
    unsigned int t99;
    unsigned int t100;
    unsigned int t101;
    unsigned int t102;
    unsigned int t103;
    unsigned int t104;
    unsigned int t105;
    unsigned int t106;
    unsigned int t108;
    unsigned int t109;
    unsigned int t110;
    unsigned int t111;
    unsigned int t112;
    unsigned int t113;
    unsigned int t114;
    unsigned int t115;
    unsigned int t116;
    unsigned int t117;
    unsigned int t118;
    unsigned int t119;
    char *t121;
    unsigned int t122;
    unsigned int t123;
    unsigned int t124;
    unsigned int t125;
    unsigned int t126;
    char *t127;
    char *t128;
    unsigned int t129;
    unsigned int t130;
    unsigned int t131;
    char *t132;
    char *t133;
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
    char *t146;
    char *t147;
    unsigned int t148;
    unsigned int t149;
    unsigned int t150;
    unsigned int t151;
    unsigned int t152;
    char *t153;
    char *t155;
    unsigned int t156;
    unsigned int t157;
    unsigned int t158;
    unsigned int t159;
    unsigned int t160;
    char *t161;
    unsigned int t163;
    unsigned int t164;
    unsigned int t165;
    char *t166;
    char *t167;
    char *t168;
    unsigned int t169;
    unsigned int t170;
    unsigned int t171;
    unsigned int t172;
    unsigned int t173;
    unsigned int t174;
    unsigned int t175;
    char *t176;
    char *t177;
    unsigned int t178;
    unsigned int t179;
    unsigned int t180;
    unsigned int t181;
    unsigned int t182;
    unsigned int t183;
    unsigned int t184;
    unsigned int t185;
    unsigned int t186;
    unsigned int t187;
    unsigned int t188;
    unsigned int t189;
    unsigned int t190;
    unsigned int t191;
    char *t193;
    unsigned int t194;
    unsigned int t195;
    unsigned int t196;
    unsigned int t197;
    unsigned int t198;
    char *t199;
    unsigned int t201;
    unsigned int t202;
    unsigned int t203;
    char *t204;
    char *t205;
    char *t206;
    unsigned int t207;
    unsigned int t208;
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
    unsigned int t219;
    unsigned int t220;
    unsigned int t221;
    unsigned int t222;
    unsigned int t223;
    int t224;
    unsigned int t225;
    unsigned int t226;
    unsigned int t227;
    unsigned int t228;
    unsigned int t229;
    unsigned int t230;
    char *t232;
    unsigned int t233;
    unsigned int t234;
    unsigned int t235;
    unsigned int t236;
    unsigned int t237;
    char *t238;
    unsigned int t240;
    unsigned int t241;
    unsigned int t242;
    char *t243;
    char *t244;
    char *t245;
    unsigned int t246;
    unsigned int t247;
    unsigned int t248;
    unsigned int t249;
    unsigned int t250;
    unsigned int t251;
    unsigned int t252;
    char *t253;
    char *t254;
    unsigned int t255;
    unsigned int t256;
    unsigned int t257;
    int t258;
    unsigned int t259;
    unsigned int t260;
    unsigned int t261;
    int t262;
    unsigned int t263;
    unsigned int t264;
    unsigned int t265;
    unsigned int t266;
    char *t267;
    char *t270;
    char *t271;

LAB0:    t1 = (t0 + 4688U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(30, ng0);
    t2 = (t0 + 5752);
    *((int *)t2) = 1;
    t3 = (t0 + 4720);
    *((char **)t3) = t2;
    *((char **)t1) = &&LAB4;

LAB1:    return;
LAB4:    xsi_set_current_line(30, ng0);

LAB5:    xsi_set_current_line(31, ng0);
    t5 = (t0 + 1616U);
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

LAB9:    memset(t13, 0, 8);
    t14 = (t4 + 4);
    t15 = *((unsigned int *)t14);
    t16 = (~(t15));
    t17 = *((unsigned int *)t4);
    t18 = (t17 & t16);
    t19 = (t18 & 1U);
    if (t19 != 0)
        goto LAB10;

LAB11:    if (*((unsigned int *)t14) != 0)
        goto LAB12;

LAB13:    t21 = (t13 + 4);
    t22 = *((unsigned int *)t13);
    t23 = (!(t22));
    t24 = *((unsigned int *)t21);
    t25 = (t23 || t24);
    if (t25 > 0)
        goto LAB14;

LAB15:    memcpy(t35, t13, 8);

LAB16:    t63 = (t35 + 4);
    t64 = *((unsigned int *)t63);
    t65 = (~(t64));
    t66 = *((unsigned int *)t35);
    t67 = (t66 & t65);
    t68 = (t67 != 0);
    if (t68 > 0)
        goto LAB24;

LAB25:    xsi_set_current_line(35, ng0);

LAB28:    xsi_set_current_line(36, ng0);
    t2 = (t0 + 1936U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB32;

LAB30:    if (*((unsigned int *)t2) == 0)
        goto LAB29;

LAB31:    t5 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t5) = 1;

LAB32:    memset(t13, 0, 8);
    t6 = (t4 + 4);
    t15 = *((unsigned int *)t6);
    t16 = (~(t15));
    t17 = *((unsigned int *)t4);
    t18 = (t17 & t16);
    t19 = (t18 & 1U);
    if (t19 != 0)
        goto LAB33;

LAB34:    if (*((unsigned int *)t6) != 0)
        goto LAB35;

LAB36:    t14 = (t13 + 4);
    t22 = *((unsigned int *)t13);
    t23 = *((unsigned int *)t14);
    t24 = (t22 || t23);
    if (t24 > 0)
        goto LAB37;

LAB38:    memcpy(t35, t13, 8);

LAB39:    t49 = (t35 + 4);
    t67 = *((unsigned int *)t49);
    t68 = (~(t67));
    t71 = *((unsigned int *)t35);
    t72 = (t71 & t68);
    t73 = (t72 != 0);
    if (t73 > 0)
        goto LAB47;

LAB48:
LAB49:    xsi_set_current_line(37, ng0);
    t2 = (t0 + 1936U);
    t3 = *((char **)t2);
    memset(t4, 0, 8);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 & 1U);
    if (t11 != 0)
        goto LAB50;

LAB51:    if (*((unsigned int *)t2) != 0)
        goto LAB52;

LAB53:    t6 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = *((unsigned int *)t6);
    t17 = (t15 || t16);
    if (t17 > 0)
        goto LAB54;

LAB55:    memcpy(t35, t4, 8);

LAB56:    t49 = (t35 + 4);
    t67 = *((unsigned int *)t49);
    t68 = (~(t67));
    t71 = *((unsigned int *)t35);
    t72 = (t71 & t68);
    t73 = (t72 != 0);
    if (t73 > 0)
        goto LAB68;

LAB69:
LAB70:    xsi_set_current_line(38, ng0);
    t2 = (t0 + 1936U);
    t3 = *((char **)t2);
    t2 = (t3 + 4);
    t7 = *((unsigned int *)t2);
    t8 = (~(t7));
    t9 = *((unsigned int *)t3);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB71;

LAB72:
LAB73:    xsi_set_current_line(46, ng0);
    t2 = (t0 + 3136);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng5)));
    memset(t4, 0, 8);
    t12 = (t5 + 4);
    t14 = (t6 + 4);
    t7 = *((unsigned int *)t5);
    t8 = *((unsigned int *)t6);
    t9 = (t7 ^ t8);
    t10 = *((unsigned int *)t12);
    t11 = *((unsigned int *)t14);
    t15 = (t10 ^ t11);
    t16 = (t9 | t15);
    t17 = *((unsigned int *)t12);
    t18 = *((unsigned int *)t14);
    t19 = (t17 | t18);
    t22 = (~(t19));
    t23 = (t16 & t22);
    if (t23 != 0)
        goto LAB85;

LAB82:    if (t19 != 0)
        goto LAB84;

LAB83:    *((unsigned int *)t4) = 1;

LAB85:    memset(t13, 0, 8);
    t21 = (t4 + 4);
    t24 = *((unsigned int *)t21);
    t25 = (~(t24));
    t29 = *((unsigned int *)t4);
    t30 = (t29 & t25);
    t31 = (t30 & 1U);
    if (t31 != 0)
        goto LAB86;

LAB87:    if (*((unsigned int *)t21) != 0)
        goto LAB88;

LAB89:    t27 = (t13 + 4);
    t32 = *((unsigned int *)t13);
    t33 = *((unsigned int *)t27);
    t36 = (t32 || t33);
    if (t36 > 0)
        goto LAB90;

LAB91:    memcpy(t74, t13, 8);

LAB92:    memset(t97, 0, 8);
    t77 = (t74 + 4);
    t98 = *((unsigned int *)t77);
    t99 = (~(t98));
    t100 = *((unsigned int *)t74);
    t101 = (t100 & t99);
    t102 = (t101 & 1U);
    if (t102 != 0)
        goto LAB104;

LAB105:    if (*((unsigned int *)t77) != 0)
        goto LAB106;

LAB107:    t79 = (t97 + 4);
    t103 = *((unsigned int *)t97);
    t104 = (!(t103));
    t105 = *((unsigned int *)t79);
    t106 = (t104 || t105);
    if (t106 > 0)
        goto LAB108;

LAB109:    memcpy(t239, t97, 8);

LAB110:    t267 = (t0 + 3456);
    xsi_vlogvar_wait_assign_value(t267, t239, 0, 0, 1, 0LL);
    xsi_set_current_line(47, ng0);
    t2 = (t0 + 3136);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng4)));
    t12 = ((char*)((ng3)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_minus(t4, 32, t6, 32, t12, 32);
    memset(t13, 0, 8);
    t14 = (t5 + 4);
    t20 = (t4 + 4);
    t7 = *((unsigned int *)t5);
    t8 = *((unsigned int *)t4);
    t9 = (t7 ^ t8);
    t10 = *((unsigned int *)t14);
    t11 = *((unsigned int *)t20);
    t15 = (t10 ^ t11);
    t16 = (t9 | t15);
    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t20);
    t19 = (t17 | t18);
    t22 = (~(t19));
    t23 = (t16 & t22);
    if (t23 != 0)
        goto LAB157;

LAB154:    if (t19 != 0)
        goto LAB156;

LAB155:    *((unsigned int *)t13) = 1;

LAB157:    memset(t28, 0, 8);
    t26 = (t13 + 4);
    t24 = *((unsigned int *)t26);
    t25 = (~(t24));
    t29 = *((unsigned int *)t13);
    t30 = (t29 & t25);
    t31 = (t30 & 1U);
    if (t31 != 0)
        goto LAB158;

LAB159:    if (*((unsigned int *)t26) != 0)
        goto LAB160;

LAB161:    t34 = (t28 + 4);
    t32 = *((unsigned int *)t28);
    t33 = *((unsigned int *)t34);
    t36 = (t32 || t33);
    if (t36 > 0)
        goto LAB162;

LAB163:    memcpy(t97, t28, 8);

LAB164:    memset(t107, 0, 8);
    t78 = (t97 + 4);
    t98 = *((unsigned int *)t78);
    t99 = (~(t98));
    t100 = *((unsigned int *)t97);
    t101 = (t100 & t99);
    t102 = (t101 & 1U);
    if (t102 != 0)
        goto LAB176;

LAB177:    if (*((unsigned int *)t78) != 0)
        goto LAB178;

LAB179:    t80 = (t107 + 4);
    t103 = *((unsigned int *)t107);
    t104 = (!(t103));
    t105 = *((unsigned int *)t80);
    t106 = (t104 || t105);
    if (t106 > 0)
        goto LAB180;

LAB181:    memcpy(t269, t107, 8);

LAB182:    t271 = (t0 + 3616);
    xsi_vlogvar_wait_assign_value(t271, t269, 0, 0, 1, 0LL);

LAB26:    goto LAB2;

LAB6:    *((unsigned int *)t4) = 1;
    goto LAB9;

LAB10:    *((unsigned int *)t13) = 1;
    goto LAB13;

LAB12:    t20 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t20) = 1;
    goto LAB13;

LAB14:    t26 = (t0 + 1776U);
    t27 = *((char **)t26);
    memset(t28, 0, 8);
    t26 = (t27 + 4);
    t29 = *((unsigned int *)t26);
    t30 = (~(t29));
    t31 = *((unsigned int *)t27);
    t32 = (t31 & t30);
    t33 = (t32 & 1U);
    if (t33 != 0)
        goto LAB17;

LAB18:    if (*((unsigned int *)t26) != 0)
        goto LAB19;

LAB20:    t36 = *((unsigned int *)t13);
    t37 = *((unsigned int *)t28);
    t38 = (t36 | t37);
    *((unsigned int *)t35) = t38;
    t39 = (t13 + 4);
    t40 = (t28 + 4);
    t41 = (t35 + 4);
    t42 = *((unsigned int *)t39);
    t43 = *((unsigned int *)t40);
    t44 = (t42 | t43);
    *((unsigned int *)t41) = t44;
    t45 = *((unsigned int *)t41);
    t46 = (t45 != 0);
    if (t46 == 1)
        goto LAB21;

LAB22:
LAB23:    goto LAB16;

LAB17:    *((unsigned int *)t28) = 1;
    goto LAB20;

LAB19:    t34 = (t28 + 4);
    *((unsigned int *)t28) = 1;
    *((unsigned int *)t34) = 1;
    goto LAB20;

LAB21:    t47 = *((unsigned int *)t35);
    t48 = *((unsigned int *)t41);
    *((unsigned int *)t35) = (t47 | t48);
    t49 = (t13 + 4);
    t50 = (t28 + 4);
    t51 = *((unsigned int *)t49);
    t52 = (~(t51));
    t53 = *((unsigned int *)t13);
    t54 = (t53 & t52);
    t55 = *((unsigned int *)t50);
    t56 = (~(t55));
    t57 = *((unsigned int *)t28);
    t58 = (t57 & t56);
    t59 = (~(t54));
    t60 = (~(t58));
    t61 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t61 & t59);
    t62 = *((unsigned int *)t41);
    *((unsigned int *)t41) = (t62 & t60);
    goto LAB23;

LAB24:    xsi_set_current_line(31, ng0);

LAB27:    xsi_set_current_line(32, ng0);
    t69 = ((char*)((ng1)));
    t70 = (t0 + 3136);
    xsi_vlogvar_wait_assign_value(t70, t69, 0, 0, 4, 0LL);
    xsi_set_current_line(33, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 3456);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(34, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 3616);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    goto LAB26;

LAB29:    *((unsigned int *)t4) = 1;
    goto LAB32;

LAB33:    *((unsigned int *)t13) = 1;
    goto LAB36;

LAB35:    t12 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t12) = 1;
    goto LAB36;

LAB37:    t20 = (t0 + 2096U);
    t21 = *((char **)t20);
    memset(t28, 0, 8);
    t20 = (t21 + 4);
    t25 = *((unsigned int *)t20);
    t29 = (~(t25));
    t30 = *((unsigned int *)t21);
    t31 = (t30 & t29);
    t32 = (t31 & 1U);
    if (t32 != 0)
        goto LAB40;

LAB41:    if (*((unsigned int *)t20) != 0)
        goto LAB42;

LAB43:    t33 = *((unsigned int *)t13);
    t36 = *((unsigned int *)t28);
    t37 = (t33 & t36);
    *((unsigned int *)t35) = t37;
    t27 = (t13 + 4);
    t34 = (t28 + 4);
    t39 = (t35 + 4);
    t38 = *((unsigned int *)t27);
    t42 = *((unsigned int *)t34);
    t43 = (t38 | t42);
    *((unsigned int *)t39) = t43;
    t44 = *((unsigned int *)t39);
    t45 = (t44 != 0);
    if (t45 == 1)
        goto LAB44;

LAB45:
LAB46:    goto LAB39;

LAB40:    *((unsigned int *)t28) = 1;
    goto LAB43;

LAB42:    t26 = (t28 + 4);
    *((unsigned int *)t28) = 1;
    *((unsigned int *)t26) = 1;
    goto LAB43;

LAB44:    t46 = *((unsigned int *)t35);
    t47 = *((unsigned int *)t39);
    *((unsigned int *)t35) = (t46 | t47);
    t40 = (t13 + 4);
    t41 = (t28 + 4);
    t48 = *((unsigned int *)t13);
    t51 = (~(t48));
    t52 = *((unsigned int *)t40);
    t53 = (~(t52));
    t55 = *((unsigned int *)t28);
    t56 = (~(t55));
    t57 = *((unsigned int *)t41);
    t59 = (~(t57));
    t54 = (t51 & t53);
    t58 = (t56 & t59);
    t60 = (~(t54));
    t61 = (~(t58));
    t62 = *((unsigned int *)t39);
    *((unsigned int *)t39) = (t62 & t60);
    t64 = *((unsigned int *)t39);
    *((unsigned int *)t39) = (t64 & t61);
    t65 = *((unsigned int *)t35);
    *((unsigned int *)t35) = (t65 & t60);
    t66 = *((unsigned int *)t35);
    *((unsigned int *)t35) = (t66 & t61);
    goto LAB46;

LAB47:    xsi_set_current_line(36, ng0);
    t50 = (t0 + 3136);
    t63 = (t50 + 56U);
    t69 = *((char **)t63);
    t70 = ((char*)((ng3)));
    memset(t74, 0, 8);
    xsi_vlog_unsigned_minus(t74, 32, t69, 4, t70, 32);
    t75 = (t0 + 3136);
    xsi_vlogvar_wait_assign_value(t75, t74, 0, 0, 4, 0LL);
    goto LAB49;

LAB50:    *((unsigned int *)t4) = 1;
    goto LAB53;

LAB52:    t5 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t5) = 1;
    goto LAB53;

LAB54:    t12 = (t0 + 2096U);
    t14 = *((char **)t12);
    memset(t13, 0, 8);
    t12 = (t14 + 4);
    t18 = *((unsigned int *)t12);
    t19 = (~(t18));
    t22 = *((unsigned int *)t14);
    t23 = (t22 & t19);
    t24 = (t23 & 1U);
    if (t24 != 0)
        goto LAB60;

LAB58:    if (*((unsigned int *)t12) == 0)
        goto LAB57;

LAB59:    t20 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t20) = 1;

LAB60:    memset(t28, 0, 8);
    t21 = (t13 + 4);
    t25 = *((unsigned int *)t21);
    t29 = (~(t25));
    t30 = *((unsigned int *)t13);
    t31 = (t30 & t29);
    t32 = (t31 & 1U);
    if (t32 != 0)
        goto LAB61;

LAB62:    if (*((unsigned int *)t21) != 0)
        goto LAB63;

LAB64:    t33 = *((unsigned int *)t4);
    t36 = *((unsigned int *)t28);
    t37 = (t33 & t36);
    *((unsigned int *)t35) = t37;
    t27 = (t4 + 4);
    t34 = (t28 + 4);
    t39 = (t35 + 4);
    t38 = *((unsigned int *)t27);
    t42 = *((unsigned int *)t34);
    t43 = (t38 | t42);
    *((unsigned int *)t39) = t43;
    t44 = *((unsigned int *)t39);
    t45 = (t44 != 0);
    if (t45 == 1)
        goto LAB65;

LAB66:
LAB67:    goto LAB56;

LAB57:    *((unsigned int *)t13) = 1;
    goto LAB60;

LAB61:    *((unsigned int *)t28) = 1;
    goto LAB64;

LAB63:    t26 = (t28 + 4);
    *((unsigned int *)t28) = 1;
    *((unsigned int *)t26) = 1;
    goto LAB64;

LAB65:    t46 = *((unsigned int *)t35);
    t47 = *((unsigned int *)t39);
    *((unsigned int *)t35) = (t46 | t47);
    t40 = (t4 + 4);
    t41 = (t28 + 4);
    t48 = *((unsigned int *)t4);
    t51 = (~(t48));
    t52 = *((unsigned int *)t40);
    t53 = (~(t52));
    t55 = *((unsigned int *)t28);
    t56 = (~(t55));
    t57 = *((unsigned int *)t41);
    t59 = (~(t57));
    t54 = (t51 & t53);
    t58 = (t56 & t59);
    t60 = (~(t54));
    t61 = (~(t58));
    t62 = *((unsigned int *)t39);
    *((unsigned int *)t39) = (t62 & t60);
    t64 = *((unsigned int *)t39);
    *((unsigned int *)t39) = (t64 & t61);
    t65 = *((unsigned int *)t35);
    *((unsigned int *)t35) = (t65 & t60);
    t66 = *((unsigned int *)t35);
    *((unsigned int *)t35) = (t66 & t61);
    goto LAB67;

LAB68:    xsi_set_current_line(37, ng0);
    t50 = (t0 + 3136);
    t63 = (t50 + 56U);
    t69 = *((char **)t63);
    t70 = ((char*)((ng3)));
    memset(t74, 0, 8);
    xsi_vlog_unsigned_add(t74, 32, t69, 4, t70, 32);
    t75 = (t0 + 3136);
    xsi_vlogvar_wait_assign_value(t75, t74, 0, 0, 4, 0LL);
    goto LAB70;

LAB71:    xsi_set_current_line(38, ng0);

LAB74:    xsi_set_current_line(39, ng0);
    xsi_set_current_line(39, ng0);
    t5 = ((char*)((ng4)));
    t6 = ((char*)((ng3)));
    memset(t4, 0, 8);
    xsi_vlog_unsigned_minus(t4, 32, t5, 32, t6, 32);
    t12 = (t0 + 3776);
    xsi_vlogvar_assign_value(t12, t4, 0, 0, 32);

LAB75:    t2 = (t0 + 3776);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng5)));
    memset(t4, 0, 8);
    xsi_vlog_signed_greater(t4, 32, t5, 32, t6, 32);
    t12 = (t4 + 4);
    t7 = *((unsigned int *)t12);
    t8 = (~(t7));
    t9 = *((unsigned int *)t4);
    t10 = (t9 & t8);
    t11 = (t10 != 0);
    if (t11 > 0)
        goto LAB76;

LAB77:    xsi_set_current_line(40, ng0);
    t2 = (t0 + 2576U);
    t3 = *((char **)t2);
    t2 = (t0 + 3296);
    t5 = (t0 + 3296);
    t6 = (t5 + 72U);
    t12 = *((char **)t6);
    t14 = (t0 + 3296);
    t20 = (t14 + 64U);
    t21 = *((char **)t20);
    t26 = ((char*)((ng5)));
    xsi_vlog_generic_convert_array_indices(t4, t13, t12, t21, 2, 1, t26, 32, 1);
    t27 = (t4 + 4);
    t7 = *((unsigned int *)t27);
    t54 = (!(t7));
    t34 = (t13 + 4);
    t8 = *((unsigned int *)t34);
    t58 = (!(t8));
    t87 = (t54 && t58);
    if (t87 == 1)
        goto LAB80;

LAB81:    goto LAB73;

LAB76:    xsi_set_current_line(39, ng0);
    t14 = (t0 + 3296);
    t20 = (t14 + 56U);
    t21 = *((char **)t20);
    t26 = (t0 + 3296);
    t27 = (t26 + 72U);
    t34 = *((char **)t27);
    t39 = (t0 + 3296);
    t40 = (t39 + 64U);
    t41 = *((char **)t40);
    t49 = (t0 + 3776);
    t50 = (t49 + 56U);
    t63 = *((char **)t50);
    t69 = ((char*)((ng3)));
    memset(t13, 0, 8);
    xsi_vlog_signed_minus(t13, 32, t63, 32, t69, 32);
    xsi_vlog_generic_get_array_select_value(t76, 130, t21, t34, t41, 2, 1, t13, 32, 1);
    t70 = (t0 + 3296);
    t75 = (t0 + 3296);
    t77 = (t75 + 72U);
    t78 = *((char **)t77);
    t79 = (t0 + 3296);
    t80 = (t79 + 64U);
    t81 = *((char **)t80);
    t82 = (t0 + 3776);
    t83 = (t82 + 56U);
    t84 = *((char **)t83);
    xsi_vlog_generic_convert_array_indices(t28, t35, t78, t81, 2, 1, t84, 32, 1);
    t85 = (t28 + 4);
    t15 = *((unsigned int *)t85);
    t54 = (!(t15));
    t86 = (t35 + 4);
    t16 = *((unsigned int *)t86);
    t58 = (!(t16));
    t87 = (t54 && t58);
    if (t87 == 1)
        goto LAB78;

LAB79:    xsi_set_current_line(39, ng0);
    t2 = (t0 + 3776);
    t3 = (t2 + 56U);
    t5 = *((char **)t3);
    t6 = ((char*)((ng3)));
    memset(t4, 0, 8);
    xsi_vlog_signed_minus(t4, 32, t5, 32, t6, 32);
    t12 = (t0 + 3776);
    xsi_vlogvar_assign_value(t12, t4, 0, 0, 32);
    goto LAB75;

LAB78:    t17 = *((unsigned int *)t28);
    t18 = *((unsigned int *)t35);
    t88 = (t17 - t18);
    t89 = (t88 + 1);
    xsi_vlogvar_wait_assign_value(t70, t76, 0, *((unsigned int *)t35), t89, 0LL);
    goto LAB79;

LAB80:    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t13);
    t88 = (t9 - t10);
    t89 = (t88 + 1);
    xsi_vlogvar_wait_assign_value(t2, t3, 0, *((unsigned int *)t13), t89, 0LL);
    goto LAB81;

LAB84:    t20 = (t4 + 4);
    *((unsigned int *)t4) = 1;
    *((unsigned int *)t20) = 1;
    goto LAB85;

LAB86:    *((unsigned int *)t13) = 1;
    goto LAB89;

LAB88:    t26 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t26) = 1;
    goto LAB89;

LAB90:    t34 = (t0 + 1936U);
    t39 = *((char **)t34);
    memset(t28, 0, 8);
    t34 = (t39 + 4);
    t37 = *((unsigned int *)t34);
    t38 = (~(t37));
    t42 = *((unsigned int *)t39);
    t43 = (t42 & t38);
    t44 = (t43 & 1U);
    if (t44 != 0)
        goto LAB96;

LAB94:    if (*((unsigned int *)t34) == 0)
        goto LAB93;

LAB95:    t40 = (t28 + 4);
    *((unsigned int *)t28) = 1;
    *((unsigned int *)t40) = 1;

LAB96:    memset(t35, 0, 8);
    t41 = (t28 + 4);
    t45 = *((unsigned int *)t41);
    t46 = (~(t45));
    t47 = *((unsigned int *)t28);
    t48 = (t47 & t46);
    t51 = (t48 & 1U);
    if (t51 != 0)
        goto LAB97;

LAB98:    if (*((unsigned int *)t41) != 0)
        goto LAB99;

LAB100:    t52 = *((unsigned int *)t13);
    t53 = *((unsigned int *)t35);
    t55 = (t52 & t53);
    *((unsigned int *)t74) = t55;
    t50 = (t13 + 4);
    t63 = (t35 + 4);
    t69 = (t74 + 4);
    t56 = *((unsigned int *)t50);
    t57 = *((unsigned int *)t63);
    t59 = (t56 | t57);
    *((unsigned int *)t69) = t59;
    t60 = *((unsigned int *)t69);
    t61 = (t60 != 0);
    if (t61 == 1)
        goto LAB101;

LAB102:
LAB103:    goto LAB92;

LAB93:    *((unsigned int *)t28) = 1;
    goto LAB96;

LAB97:    *((unsigned int *)t35) = 1;
    goto LAB100;

LAB99:    t49 = (t35 + 4);
    *((unsigned int *)t35) = 1;
    *((unsigned int *)t49) = 1;
    goto LAB100;

LAB101:    t62 = *((unsigned int *)t74);
    t64 = *((unsigned int *)t69);
    *((unsigned int *)t74) = (t62 | t64);
    t70 = (t13 + 4);
    t75 = (t35 + 4);
    t65 = *((unsigned int *)t13);
    t66 = (~(t65));
    t67 = *((unsigned int *)t70);
    t68 = (~(t67));
    t71 = *((unsigned int *)t35);
    t72 = (~(t71));
    t73 = *((unsigned int *)t75);
    t90 = (~(t73));
    t54 = (t66 & t68);
    t58 = (t72 & t90);
    t91 = (~(t54));
    t92 = (~(t58));
    t93 = *((unsigned int *)t69);
    *((unsigned int *)t69) = (t93 & t91);
    t94 = *((unsigned int *)t69);
    *((unsigned int *)t69) = (t94 & t92);
    t95 = *((unsigned int *)t74);
    *((unsigned int *)t74) = (t95 & t91);
    t96 = *((unsigned int *)t74);
    *((unsigned int *)t74) = (t96 & t92);
    goto LAB103;

LAB104:    *((unsigned int *)t97) = 1;
    goto LAB107;

LAB106:    t78 = (t97 + 4);
    *((unsigned int *)t97) = 1;
    *((unsigned int *)t78) = 1;
    goto LAB107;

LAB108:    t80 = (t0 + 3136);
    t81 = (t80 + 56U);
    t82 = *((char **)t81);
    t83 = ((char*)((ng3)));
    memset(t107, 0, 8);
    t84 = (t82 + 4);
    t85 = (t83 + 4);
    t108 = *((unsigned int *)t82);
    t109 = *((unsigned int *)t83);
    t110 = (t108 ^ t109);
    t111 = *((unsigned int *)t84);
    t112 = *((unsigned int *)t85);
    t113 = (t111 ^ t112);
    t114 = (t110 | t113);
    t115 = *((unsigned int *)t84);
    t116 = *((unsigned int *)t85);
    t117 = (t115 | t116);
    t118 = (~(t117));
    t119 = (t114 & t118);
    if (t119 != 0)
        goto LAB114;

LAB111:    if (t117 != 0)
        goto LAB113;

LAB112:    *((unsigned int *)t107) = 1;

LAB114:    memset(t120, 0, 8);
    t121 = (t107 + 4);
    t122 = *((unsigned int *)t121);
    t123 = (~(t122));
    t124 = *((unsigned int *)t107);
    t125 = (t124 & t123);
    t126 = (t125 & 1U);
    if (t126 != 0)
        goto LAB115;

LAB116:    if (*((unsigned int *)t121) != 0)
        goto LAB117;

LAB118:    t128 = (t120 + 4);
    t129 = *((unsigned int *)t120);
    t130 = *((unsigned int *)t128);
    t131 = (t129 || t130);
    if (t131 > 0)
        goto LAB119;

LAB120:    memcpy(t200, t120, 8);

LAB121:    memset(t231, 0, 8);
    t232 = (t200 + 4);
    t233 = *((unsigned int *)t232);
    t234 = (~(t233));
    t235 = *((unsigned int *)t200);
    t236 = (t235 & t234);
    t237 = (t236 & 1U);
    if (t237 != 0)
        goto LAB147;

LAB148:    if (*((unsigned int *)t232) != 0)
        goto LAB149;

LAB150:    t240 = *((unsigned int *)t97);
    t241 = *((unsigned int *)t231);
    t242 = (t240 | t241);
    *((unsigned int *)t239) = t242;
    t243 = (t97 + 4);
    t244 = (t231 + 4);
    t245 = (t239 + 4);
    t246 = *((unsigned int *)t243);
    t247 = *((unsigned int *)t244);
    t248 = (t246 | t247);
    *((unsigned int *)t245) = t248;
    t249 = *((unsigned int *)t245);
    t250 = (t249 != 0);
    if (t250 == 1)
        goto LAB151;

LAB152:
LAB153:    goto LAB110;

LAB113:    t86 = (t107 + 4);
    *((unsigned int *)t107) = 1;
    *((unsigned int *)t86) = 1;
    goto LAB114;

LAB115:    *((unsigned int *)t120) = 1;
    goto LAB118;

LAB117:    t127 = (t120 + 4);
    *((unsigned int *)t120) = 1;
    *((unsigned int *)t127) = 1;
    goto LAB118;

LAB119:    t132 = (t0 + 2096U);
    t133 = *((char **)t132);
    memset(t134, 0, 8);
    t132 = (t133 + 4);
    t135 = *((unsigned int *)t132);
    t136 = (~(t135));
    t137 = *((unsigned int *)t133);
    t138 = (t137 & t136);
    t139 = (t138 & 1U);
    if (t139 != 0)
        goto LAB122;

LAB123:    if (*((unsigned int *)t132) != 0)
        goto LAB124;

LAB125:    t141 = (t134 + 4);
    t142 = *((unsigned int *)t134);
    t143 = *((unsigned int *)t141);
    t144 = (t142 || t143);
    if (t144 > 0)
        goto LAB126;

LAB127:    memcpy(t162, t134, 8);

LAB128:    memset(t192, 0, 8);
    t193 = (t162 + 4);
    t194 = *((unsigned int *)t193);
    t195 = (~(t194));
    t196 = *((unsigned int *)t162);
    t197 = (t196 & t195);
    t198 = (t197 & 1U);
    if (t198 != 0)
        goto LAB140;

LAB141:    if (*((unsigned int *)t193) != 0)
        goto LAB142;

LAB143:    t201 = *((unsigned int *)t120);
    t202 = *((unsigned int *)t192);
    t203 = (t201 & t202);
    *((unsigned int *)t200) = t203;
    t204 = (t120 + 4);
    t205 = (t192 + 4);
    t206 = (t200 + 4);
    t207 = *((unsigned int *)t204);
    t208 = *((unsigned int *)t205);
    t209 = (t207 | t208);
    *((unsigned int *)t206) = t209;
    t210 = *((unsigned int *)t206);
    t211 = (t210 != 0);
    if (t211 == 1)
        goto LAB144;

LAB145:
LAB146:    goto LAB121;

LAB122:    *((unsigned int *)t134) = 1;
    goto LAB125;

LAB124:    t140 = (t134 + 4);
    *((unsigned int *)t134) = 1;
    *((unsigned int *)t140) = 1;
    goto LAB125;

LAB126:    t146 = (t0 + 1936U);
    t147 = *((char **)t146);
    memset(t145, 0, 8);
    t146 = (t147 + 4);
    t148 = *((unsigned int *)t146);
    t149 = (~(t148));
    t150 = *((unsigned int *)t147);
    t151 = (t150 & t149);
    t152 = (t151 & 1U);
    if (t152 != 0)
        goto LAB132;

LAB130:    if (*((unsigned int *)t146) == 0)
        goto LAB129;

LAB131:    t153 = (t145 + 4);
    *((unsigned int *)t145) = 1;
    *((unsigned int *)t153) = 1;

LAB132:    memset(t154, 0, 8);
    t155 = (t145 + 4);
    t156 = *((unsigned int *)t155);
    t157 = (~(t156));
    t158 = *((unsigned int *)t145);
    t159 = (t158 & t157);
    t160 = (t159 & 1U);
    if (t160 != 0)
        goto LAB133;

LAB134:    if (*((unsigned int *)t155) != 0)
        goto LAB135;

LAB136:    t163 = *((unsigned int *)t134);
    t164 = *((unsigned int *)t154);
    t165 = (t163 & t164);
    *((unsigned int *)t162) = t165;
    t166 = (t134 + 4);
    t167 = (t154 + 4);
    t168 = (t162 + 4);
    t169 = *((unsigned int *)t166);
    t170 = *((unsigned int *)t167);
    t171 = (t169 | t170);
    *((unsigned int *)t168) = t171;
    t172 = *((unsigned int *)t168);
    t173 = (t172 != 0);
    if (t173 == 1)
        goto LAB137;

LAB138:
LAB139:    goto LAB128;

LAB129:    *((unsigned int *)t145) = 1;
    goto LAB132;

LAB133:    *((unsigned int *)t154) = 1;
    goto LAB136;

LAB135:    t161 = (t154 + 4);
    *((unsigned int *)t154) = 1;
    *((unsigned int *)t161) = 1;
    goto LAB136;

LAB137:    t174 = *((unsigned int *)t162);
    t175 = *((unsigned int *)t168);
    *((unsigned int *)t162) = (t174 | t175);
    t176 = (t134 + 4);
    t177 = (t154 + 4);
    t178 = *((unsigned int *)t134);
    t179 = (~(t178));
    t180 = *((unsigned int *)t176);
    t181 = (~(t180));
    t182 = *((unsigned int *)t154);
    t183 = (~(t182));
    t184 = *((unsigned int *)t177);
    t185 = (~(t184));
    t87 = (t179 & t181);
    t88 = (t183 & t185);
    t186 = (~(t87));
    t187 = (~(t88));
    t188 = *((unsigned int *)t168);
    *((unsigned int *)t168) = (t188 & t186);
    t189 = *((unsigned int *)t168);
    *((unsigned int *)t168) = (t189 & t187);
    t190 = *((unsigned int *)t162);
    *((unsigned int *)t162) = (t190 & t186);
    t191 = *((unsigned int *)t162);
    *((unsigned int *)t162) = (t191 & t187);
    goto LAB139;

LAB140:    *((unsigned int *)t192) = 1;
    goto LAB143;

LAB142:    t199 = (t192 + 4);
    *((unsigned int *)t192) = 1;
    *((unsigned int *)t199) = 1;
    goto LAB143;

LAB144:    t212 = *((unsigned int *)t200);
    t213 = *((unsigned int *)t206);
    *((unsigned int *)t200) = (t212 | t213);
    t214 = (t120 + 4);
    t215 = (t192 + 4);
    t216 = *((unsigned int *)t120);
    t217 = (~(t216));
    t218 = *((unsigned int *)t214);
    t219 = (~(t218));
    t220 = *((unsigned int *)t192);
    t221 = (~(t220));
    t222 = *((unsigned int *)t215);
    t223 = (~(t222));
    t89 = (t217 & t219);
    t224 = (t221 & t223);
    t225 = (~(t89));
    t226 = (~(t224));
    t227 = *((unsigned int *)t206);
    *((unsigned int *)t206) = (t227 & t225);
    t228 = *((unsigned int *)t206);
    *((unsigned int *)t206) = (t228 & t226);
    t229 = *((unsigned int *)t200);
    *((unsigned int *)t200) = (t229 & t225);
    t230 = *((unsigned int *)t200);
    *((unsigned int *)t200) = (t230 & t226);
    goto LAB146;

LAB147:    *((unsigned int *)t231) = 1;
    goto LAB150;

LAB149:    t238 = (t231 + 4);
    *((unsigned int *)t231) = 1;
    *((unsigned int *)t238) = 1;
    goto LAB150;

LAB151:    t251 = *((unsigned int *)t239);
    t252 = *((unsigned int *)t245);
    *((unsigned int *)t239) = (t251 | t252);
    t253 = (t97 + 4);
    t254 = (t231 + 4);
    t255 = *((unsigned int *)t253);
    t256 = (~(t255));
    t257 = *((unsigned int *)t97);
    t258 = (t257 & t256);
    t259 = *((unsigned int *)t254);
    t260 = (~(t259));
    t261 = *((unsigned int *)t231);
    t262 = (t261 & t260);
    t263 = (~(t258));
    t264 = (~(t262));
    t265 = *((unsigned int *)t245);
    *((unsigned int *)t245) = (t265 & t263);
    t266 = *((unsigned int *)t245);
    *((unsigned int *)t245) = (t266 & t264);
    goto LAB153;

LAB156:    t21 = (t13 + 4);
    *((unsigned int *)t13) = 1;
    *((unsigned int *)t21) = 1;
    goto LAB157;

LAB158:    *((unsigned int *)t28) = 1;
    goto LAB161;

LAB160:    t27 = (t28 + 4);
    *((unsigned int *)t28) = 1;
    *((unsigned int *)t27) = 1;
    goto LAB161;

LAB162:    t39 = (t0 + 2096U);
    t40 = *((char **)t39);
    memset(t35, 0, 8);
    t39 = (t40 + 4);
    t37 = *((unsigned int *)t39);
    t38 = (~(t37));
    t42 = *((unsigned int *)t40);
    t43 = (t42 & t38);
    t44 = (t43 & 1U);
    if (t44 != 0)
        goto LAB168;

LAB166:    if (*((unsigned int *)t39) == 0)
        goto LAB165;

LAB167:    t41 = (t35 + 4);
    *((unsigned int *)t35) = 1;
    *((unsigned int *)t41) = 1;

LAB168:    memset(t74, 0, 8);
    t49 = (t35 + 4);
    t45 = *((unsigned int *)t49);
    t46 = (~(t45));
    t47 = *((unsigned int *)t35);
    t48 = (t47 & t46);
    t51 = (t48 & 1U);
    if (t51 != 0)
        goto LAB169;

LAB170:    if (*((unsigned int *)t49) != 0)
        goto LAB171;

LAB172:    t52 = *((unsigned int *)t28);
    t53 = *((unsigned int *)t74);
    t55 = (t52 & t53);
    *((unsigned int *)t97) = t55;
    t63 = (t28 + 4);
    t69 = (t74 + 4);
    t70 = (t97 + 4);
    t56 = *((unsigned int *)t63);
    t57 = *((unsigned int *)t69);
    t59 = (t56 | t57);
    *((unsigned int *)t70) = t59;
    t60 = *((unsigned int *)t70);
    t61 = (t60 != 0);
    if (t61 == 1)
        goto LAB173;

LAB174:
LAB175:    goto LAB164;

LAB165:    *((unsigned int *)t35) = 1;
    goto LAB168;

LAB169:    *((unsigned int *)t74) = 1;
    goto LAB172;

LAB171:    t50 = (t74 + 4);
    *((unsigned int *)t74) = 1;
    *((unsigned int *)t50) = 1;
    goto LAB172;

LAB173:    t62 = *((unsigned int *)t97);
    t64 = *((unsigned int *)t70);
    *((unsigned int *)t97) = (t62 | t64);
    t75 = (t28 + 4);
    t77 = (t74 + 4);
    t65 = *((unsigned int *)t28);
    t66 = (~(t65));
    t67 = *((unsigned int *)t75);
    t68 = (~(t67));
    t71 = *((unsigned int *)t74);
    t72 = (~(t71));
    t73 = *((unsigned int *)t77);
    t90 = (~(t73));
    t54 = (t66 & t68);
    t58 = (t72 & t90);
    t91 = (~(t54));
    t92 = (~(t58));
    t93 = *((unsigned int *)t70);
    *((unsigned int *)t70) = (t93 & t91);
    t94 = *((unsigned int *)t70);
    *((unsigned int *)t70) = (t94 & t92);
    t95 = *((unsigned int *)t97);
    *((unsigned int *)t97) = (t95 & t91);
    t96 = *((unsigned int *)t97);
    *((unsigned int *)t97) = (t96 & t92);
    goto LAB175;

LAB176:    *((unsigned int *)t107) = 1;
    goto LAB179;

LAB178:    t79 = (t107 + 4);
    *((unsigned int *)t107) = 1;
    *((unsigned int *)t79) = 1;
    goto LAB179;

LAB180:    t81 = (t0 + 3136);
    t82 = (t81 + 56U);
    t83 = *((char **)t82);
    t84 = ((char*)((ng4)));
    t85 = ((char*)((ng6)));
    memset(t120, 0, 8);
    xsi_vlog_unsigned_minus(t120, 32, t84, 32, t85, 32);
    memset(t134, 0, 8);
    t86 = (t83 + 4);
    t121 = (t120 + 4);
    t108 = *((unsigned int *)t83);
    t109 = *((unsigned int *)t120);
    t110 = (t108 ^ t109);
    t111 = *((unsigned int *)t86);
    t112 = *((unsigned int *)t121);
    t113 = (t111 ^ t112);
    t114 = (t110 | t113);
    t115 = *((unsigned int *)t86);
    t116 = *((unsigned int *)t121);
    t117 = (t115 | t116);
    t118 = (~(t117));
    t119 = (t114 & t118);
    if (t119 != 0)
        goto LAB186;

LAB183:    if (t117 != 0)
        goto LAB185;

LAB184:    *((unsigned int *)t134) = 1;

LAB186:    memset(t145, 0, 8);
    t128 = (t134 + 4);
    t122 = *((unsigned int *)t128);
    t123 = (~(t122));
    t124 = *((unsigned int *)t134);
    t125 = (t124 & t123);
    t126 = (t125 & 1U);
    if (t126 != 0)
        goto LAB187;

LAB188:    if (*((unsigned int *)t128) != 0)
        goto LAB189;

LAB190:    t133 = (t145 + 4);
    t129 = *((unsigned int *)t145);
    t130 = *((unsigned int *)t133);
    t131 = (t129 || t130);
    if (t131 > 0)
        goto LAB191;

LAB192:    memcpy(t239, t145, 8);

LAB193:    memset(t268, 0, 8);
    t243 = (t239 + 4);
    t233 = *((unsigned int *)t243);
    t234 = (~(t233));
    t235 = *((unsigned int *)t239);
    t236 = (t235 & t234);
    t237 = (t236 & 1U);
    if (t237 != 0)
        goto LAB219;

LAB220:    if (*((unsigned int *)t243) != 0)
        goto LAB221;

LAB222:    t240 = *((unsigned int *)t107);
    t241 = *((unsigned int *)t268);
    t242 = (t240 | t241);
    *((unsigned int *)t269) = t242;
    t245 = (t107 + 4);
    t253 = (t268 + 4);
    t254 = (t269 + 4);
    t246 = *((unsigned int *)t245);
    t247 = *((unsigned int *)t253);
    t248 = (t246 | t247);
    *((unsigned int *)t254) = t248;
    t249 = *((unsigned int *)t254);
    t250 = (t249 != 0);
    if (t250 == 1)
        goto LAB223;

LAB224:
LAB225:    goto LAB182;

LAB185:    t127 = (t134 + 4);
    *((unsigned int *)t134) = 1;
    *((unsigned int *)t127) = 1;
    goto LAB186;

LAB187:    *((unsigned int *)t145) = 1;
    goto LAB190;

LAB189:    t132 = (t145 + 4);
    *((unsigned int *)t145) = 1;
    *((unsigned int *)t132) = 1;
    goto LAB190;

LAB191:    t140 = (t0 + 1936U);
    t141 = *((char **)t140);
    memset(t154, 0, 8);
    t140 = (t141 + 4);
    t135 = *((unsigned int *)t140);
    t136 = (~(t135));
    t137 = *((unsigned int *)t141);
    t138 = (t137 & t136);
    t139 = (t138 & 1U);
    if (t139 != 0)
        goto LAB194;

LAB195:    if (*((unsigned int *)t140) != 0)
        goto LAB196;

LAB197:    t147 = (t154 + 4);
    t142 = *((unsigned int *)t154);
    t143 = *((unsigned int *)t147);
    t144 = (t142 || t143);
    if (t144 > 0)
        goto LAB198;

LAB199:    memcpy(t200, t154, 8);

LAB200:    memset(t231, 0, 8);
    t204 = (t200 + 4);
    t194 = *((unsigned int *)t204);
    t195 = (~(t194));
    t196 = *((unsigned int *)t200);
    t197 = (t196 & t195);
    t198 = (t197 & 1U);
    if (t198 != 0)
        goto LAB212;

LAB213:    if (*((unsigned int *)t204) != 0)
        goto LAB214;

LAB215:    t201 = *((unsigned int *)t145);
    t202 = *((unsigned int *)t231);
    t203 = (t201 & t202);
    *((unsigned int *)t239) = t203;
    t206 = (t145 + 4);
    t214 = (t231 + 4);
    t215 = (t239 + 4);
    t207 = *((unsigned int *)t206);
    t208 = *((unsigned int *)t214);
    t209 = (t207 | t208);
    *((unsigned int *)t215) = t209;
    t210 = *((unsigned int *)t215);
    t211 = (t210 != 0);
    if (t211 == 1)
        goto LAB216;

LAB217:
LAB218:    goto LAB193;

LAB194:    *((unsigned int *)t154) = 1;
    goto LAB197;

LAB196:    t146 = (t154 + 4);
    *((unsigned int *)t154) = 1;
    *((unsigned int *)t146) = 1;
    goto LAB197;

LAB198:    t153 = (t0 + 2096U);
    t155 = *((char **)t153);
    memset(t162, 0, 8);
    t153 = (t155 + 4);
    t148 = *((unsigned int *)t153);
    t149 = (~(t148));
    t150 = *((unsigned int *)t155);
    t151 = (t150 & t149);
    t152 = (t151 & 1U);
    if (t152 != 0)
        goto LAB204;

LAB202:    if (*((unsigned int *)t153) == 0)
        goto LAB201;

LAB203:    t161 = (t162 + 4);
    *((unsigned int *)t162) = 1;
    *((unsigned int *)t161) = 1;

LAB204:    memset(t192, 0, 8);
    t166 = (t162 + 4);
    t156 = *((unsigned int *)t166);
    t157 = (~(t156));
    t158 = *((unsigned int *)t162);
    t159 = (t158 & t157);
    t160 = (t159 & 1U);
    if (t160 != 0)
        goto LAB205;

LAB206:    if (*((unsigned int *)t166) != 0)
        goto LAB207;

LAB208:    t163 = *((unsigned int *)t154);
    t164 = *((unsigned int *)t192);
    t165 = (t163 & t164);
    *((unsigned int *)t200) = t165;
    t168 = (t154 + 4);
    t176 = (t192 + 4);
    t177 = (t200 + 4);
    t169 = *((unsigned int *)t168);
    t170 = *((unsigned int *)t176);
    t171 = (t169 | t170);
    *((unsigned int *)t177) = t171;
    t172 = *((unsigned int *)t177);
    t173 = (t172 != 0);
    if (t173 == 1)
        goto LAB209;

LAB210:
LAB211:    goto LAB200;

LAB201:    *((unsigned int *)t162) = 1;
    goto LAB204;

LAB205:    *((unsigned int *)t192) = 1;
    goto LAB208;

LAB207:    t167 = (t192 + 4);
    *((unsigned int *)t192) = 1;
    *((unsigned int *)t167) = 1;
    goto LAB208;

LAB209:    t174 = *((unsigned int *)t200);
    t175 = *((unsigned int *)t177);
    *((unsigned int *)t200) = (t174 | t175);
    t193 = (t154 + 4);
    t199 = (t192 + 4);
    t178 = *((unsigned int *)t154);
    t179 = (~(t178));
    t180 = *((unsigned int *)t193);
    t181 = (~(t180));
    t182 = *((unsigned int *)t192);
    t183 = (~(t182));
    t184 = *((unsigned int *)t199);
    t185 = (~(t184));
    t87 = (t179 & t181);
    t88 = (t183 & t185);
    t186 = (~(t87));
    t187 = (~(t88));
    t188 = *((unsigned int *)t177);
    *((unsigned int *)t177) = (t188 & t186);
    t189 = *((unsigned int *)t177);
    *((unsigned int *)t177) = (t189 & t187);
    t190 = *((unsigned int *)t200);
    *((unsigned int *)t200) = (t190 & t186);
    t191 = *((unsigned int *)t200);
    *((unsigned int *)t200) = (t191 & t187);
    goto LAB211;

LAB212:    *((unsigned int *)t231) = 1;
    goto LAB215;

LAB214:    t205 = (t231 + 4);
    *((unsigned int *)t231) = 1;
    *((unsigned int *)t205) = 1;
    goto LAB215;

LAB216:    t212 = *((unsigned int *)t239);
    t213 = *((unsigned int *)t215);
    *((unsigned int *)t239) = (t212 | t213);
    t232 = (t145 + 4);
    t238 = (t231 + 4);
    t216 = *((unsigned int *)t145);
    t217 = (~(t216));
    t218 = *((unsigned int *)t232);
    t219 = (~(t218));
    t220 = *((unsigned int *)t231);
    t221 = (~(t220));
    t222 = *((unsigned int *)t238);
    t223 = (~(t222));
    t89 = (t217 & t219);
    t224 = (t221 & t223);
    t225 = (~(t89));
    t226 = (~(t224));
    t227 = *((unsigned int *)t215);
    *((unsigned int *)t215) = (t227 & t225);
    t228 = *((unsigned int *)t215);
    *((unsigned int *)t215) = (t228 & t226);
    t229 = *((unsigned int *)t239);
    *((unsigned int *)t239) = (t229 & t225);
    t230 = *((unsigned int *)t239);
    *((unsigned int *)t239) = (t230 & t226);
    goto LAB218;

LAB219:    *((unsigned int *)t268) = 1;
    goto LAB222;

LAB221:    t244 = (t268 + 4);
    *((unsigned int *)t268) = 1;
    *((unsigned int *)t244) = 1;
    goto LAB222;

LAB223:    t251 = *((unsigned int *)t269);
    t252 = *((unsigned int *)t254);
    *((unsigned int *)t269) = (t251 | t252);
    t267 = (t107 + 4);
    t270 = (t268 + 4);
    t255 = *((unsigned int *)t267);
    t256 = (~(t255));
    t257 = *((unsigned int *)t107);
    t258 = (t257 & t256);
    t259 = *((unsigned int *)t270);
    t260 = (~(t259));
    t261 = *((unsigned int *)t268);
    t262 = (t261 & t260);
    t263 = (~(t258));
    t264 = (~(t262));
    t265 = *((unsigned int *)t254);
    *((unsigned int *)t254) = (t265 & t263);
    t266 = *((unsigned int *)t254);
    *((unsigned int *)t254) = (t266 & t264);
    goto LAB225;

}

static void Cont_51_1(char *t0)
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

LAB0:    t1 = (t0 + 4936U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(51, ng0);
    t2 = (t0 + 3616);
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

LAB7:    t13 = (t0 + 5880);
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
    t26 = (t0 + 5768);
    *((int *)t26) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t3) = 1;
    goto LAB7;

}

static void Cont_52_2(char *t0)
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

LAB0:    t1 = (t0 + 5184U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(52, ng0);
    t2 = (t0 + 3456);
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

LAB7:    t13 = (t0 + 5944);
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
    t26 = (t0 + 5784);
    *((int *)t26) = 1;

LAB1:    return;
LAB4:    *((unsigned int *)t3) = 1;
    goto LAB7;

}

static void Cont_53_3(char *t0)
{
    char t5[40];
    char t16[8];
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
    char *t17;
    char *t18;
    char *t19;
    char *t20;
    char *t21;
    char *t22;

LAB0:    t1 = (t0 + 5432U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(53, ng0);
    t2 = (t0 + 3296);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t6 = (t0 + 3296);
    t7 = (t6 + 72U);
    t8 = *((char **)t7);
    t9 = (t0 + 3296);
    t10 = (t9 + 64U);
    t11 = *((char **)t10);
    t12 = (t0 + 3136);
    t13 = (t12 + 56U);
    t14 = *((char **)t13);
    t15 = ((char*)((ng3)));
    memset(t16, 0, 8);
    xsi_vlog_unsigned_minus(t16, 32, t14, 4, t15, 32);
    xsi_vlog_generic_get_array_select_value(t5, 130, t4, t8, t11, 2, 1, t16, 32, 2);
    t17 = (t0 + 6008);
    t18 = (t17 + 56U);
    t19 = *((char **)t18);
    t20 = (t19 + 56U);
    t21 = *((char **)t20);
    xsi_vlog_bit_copy(t21, 0, t5, 0, 130);
    xsi_driver_vfirst_trans(t17, 0, 129);
    t22 = (t0 + 5800);
    *((int *)t22) = 1;

LAB1:    return;
}


extern void worx_mktb2_m_15690114692364976605_2542354795_init()
{
	static char *pe[] = {(void *)Always_30_0,(void *)Cont_51_1,(void *)Cont_52_2,(void *)Cont_53_3};
	xsi_register_didat("worx_mktb2_m_15690114692364976605_2542354795", "isim/runsim.isim.sim/worx_mkTB2/m_15690114692364976605_2542354795.didat");
	xsi_register_executes(pe);
}
