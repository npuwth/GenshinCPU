/*
 * @Author: Juan Jiang
 * @Date: 2021-04-05 20:20:45
 * @LastEditTime: 2021-04-07 14:17:09
 * @LastEditors: Juan Jiang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 
 `include "CPU_Defines.svh"

 module MIPS(
     input logic            clk,
     input logic            rst,
     input AsynExceptType   Interrupt//来自CPU外部的中断信号
 );
    PipeLineRegsInterface x(
        .clk(clk),
        .rst(rst)
    );



    PCSEL U_PCSEL(
        .isBranch(),
        .isImmeJump(),
        .isExceptorERET()
    );

 endmodule