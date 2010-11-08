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
    work_m_15900933413593705828_3863955574_init();
    work_m_14982918413845116657_4239552358_init();
    work_m_16608811249923958053_0832196448_init();
    work_m_06347725114716612532_2719985614_init();
    work_m_12587204337618245352_0632645039_init();
    work_m_06152927948264307607_0622517412_init();
    work_m_15242001635182948293_4136080323_init();
    work_m_05455458968086505219_1010460769_init();
    work_m_04682914041379791573_2347614550_init();


    xsi_register_tops("work_m_04682914041379791573_2347614550");


    return xsi_run_simulation(argc, argv);

}
