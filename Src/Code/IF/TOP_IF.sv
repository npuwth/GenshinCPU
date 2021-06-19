/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-19 22:10:08
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_IF ( 
    input logic clk,
    input logic resetn,
    input logic PC_Wr,
    
    IF_ID_Interface IIBus
);
    

    logic   [31:0]  IF_NPC;
    logic   [31:0]  IF_PC;

    PC U_PC ( //TODO 端口连线
        .clk(clk),
        .rst(rst),
        .PC_Wr(PC_Wr),
        .IF_NPC(IF_NPC),
        .IF_PC(IF_PC)
    );

endmodule