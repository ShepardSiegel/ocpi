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
    worx_mktb11_m_12587204337618245352_0632645039_init();
    worx_mktb11_m_04052959901817908855_0622517412_init();
    worx_mktb11_m_04052959901817908855_1539468517_init();
    worx_mktb11_m_08070838236131486829_3535604955_init();
    worx_mktb11_m_08070838236131486829_1529052955_init();
    worx_mktb11_m_12404756575713869139_1010460769_init();
    worx_mktb11_m_15900933413593705828_3863955574_init();
    worx_mktb11_m_14982918413845116657_4239552358_init();
    worx_mktb11_m_16608811249923958053_0832196448_init();
    worx_mktb11_m_01742021551875684769_0740523798_init();
    worx_mktb11_m_01118172201867290916_0286164271_init();


    xsi_register_tops("worx_mktb11_m_01118172201867290916_0286164271");


    return xsi_run_simulation(argc, argv);

}
