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

#include "xsi.h"

struct XSI_INFO xsi_info;



int main(int argc, char **argv)
{
    xsi_init_design(argc, argv);
    xsi_register_info(&xsi_info);

    xsi_register_min_prec_unit(-12);
    library_1_m_12587202844681273188_0632645039_init();
    library_1_m_02234334194214258194_0622517412_init();
    library_1_m_02234334194214258194_1539468517_init();
    library_1_m_01100418153369981992_3800225500_init();
    library_1_m_15899306113584329116_3863955574_init();
    library_1_m_03591842454357841730_1671309101_init();
    library_1_m_01484933403491285134_0832196448_init();
    library_1_m_01227567211450946152_1529106304_init();
    worx_mktb10_m_00941130015607619362_0286164271_init();


    xsi_register_tops("worx_mktb10_m_00941130015607619362_0286164271");


    return xsi_run_simulation(argc, argv);

}
