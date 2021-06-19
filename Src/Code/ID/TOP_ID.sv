/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-19 22:07:20
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_ID (
    input logic              clk,
    input logic              resetn,
    input logic              ID_Flush,
    input logic              ID_Wr,
    IF_ID_Interface          IIBus,//TODO: 不如改成IF_ID_Bus 
    ID_EXE_interface         IEBus            
);
    
    logic [31:0]             ID_JumpAddr;

    ID_Reg U_ID_Reg ( //TODO: 端口的连线还没改好
        
        .clk (clk ),
        .rst (rst ),
        .ID_Flush (ID_Flush ),
        .ID_Wr (ID_Wr ),
        .IF_Instr (IIBus.IF_Instr ),
        .IF_PC (IIBus.IF_PC ),
        .ID_Instr (IEBus.ID_Instr ),
        .ID_Imm16 (IEBus.ID_Imm16 ),
        .ID_rs (IEBus.ID_rs ),
        .ID_rt (IEBus.ID_rt ),
        .ID_rd (IEBus.ID_rd ),
        .ID_JumpAddr (ID_JumpAddr ),
        .ID_Sel (ID_Sel ),
        .ID_PC  (IEBus.ID_PC )
  );



endmodule  