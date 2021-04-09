/*
 * @Author: Juan Jiang
 * @Date: 2021-04-09 14:16:59
 * @LastEditTime: 2021-04-09 14:21:31
 * @LastEditors: Juan Jiang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 module ICache (
     input logic[31:0] IF_PC,

     output logic[31:0] IF_Instr
 );
     logic [31:0][31:0] icache;

     assign IF_Instr = icache[IF_PC];
 endmodule
