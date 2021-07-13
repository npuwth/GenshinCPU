/*
 * @Author: Yang
 * @Date: 2021-07-12 22:32:30
 * @LastEditTime: 2021-07-13 12:15:40
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_MEM2 (
    input logic                  clk,
    input logic                  resetn,
    input logic                  MEM2_Flush,
    input logic                  MEM2_Wr,
    MEM_MEM2_Interface           MM2Bus,
    MEM2_WB_Interface            M2WBus,
    CPU_Bus_Interface            cpu_dbus,
    //--------------------output--------------------//
    output logic [31:0]          MEM2_Result,  // 用于旁路数据
    output logic [4:0]           MEM2_Dst,
    output RegsWrType            MEM2_RegsWrType
);
    MEM2_Reg U_MEM2_REG(
    .clk                    (clk ),
    .rst                    (resetn ),
    .MEM2_Flush             (MEM2_Flush ),
    .MEM2_Wr                (MEM2_Wr ),
    .MEM_ALUOut             (MM2Bus.MEM_ALUOut ),
    .MEM_PC                 (MM2Bus.MEM_PC ),
    .MEM_Instr              (MM2Bus.MEM_Instr ),
    .MEM_WbSel              (MM2Bus.MEM_WbSel ),
    .MEM_Dst                (MM2Bus.MEM_Dst ),
    .MEM_OutB               (MM2Bus.MEM_OutB ),
    .MEM_RegsWrType_final   (MM2Bus.MEM_RegsWrType_final ),
    .MEM_ExceptType_final   (MM2Bus.MEM_ExceptType_final ),
    .MEM_IsABranch          (MM2Bus.MEM_IsABranch ),
    .MEM_IsAImmeJump        (MM2Bus.MEM_IsAImmeJump ),
    .MEM_IsInDelaySlot      (MM2Bus.MEM_IsInDelaySlot ),
//-----------------------------output-------------------------------------//
    .MEM2_ALUOut            (M2WBus.MEM2_ALUOut ),
    .MEM2_PC                (M2WBus.MEM2_PC ),
    .MEM2_Instr             (M2WBus.MEM2_Instr ),
    .MEM2_WbSel             (M2WBus.MEM2_WbSel ),
    .MEM2_Dst               (M2WBus.MEM2_Dst ),
    .MEM2_OutB              (M2WBus.MEM2_OutB ),
    .MEM2_RegsWrType        (M2WBus.MEM2_RegsWrType ),
    .MEM2_ExceptType        (MM2Bus.MEM2_ExceptType ),
    .MEM2_IsABranch         (MM2Bus.MEM2_IsABranch ),
    .MEM2_IsAImmeJump       (MM2Bus.MEM2_IsAImmeJump ),
    .MEM2_IsInDelaySlot     (MM2Bus.MEM2_IsInDelaySlot)
    );
    //output for forwarding 
    assign MEM2_Dst              = M2WBus.MEM2_Dst;
    assign MEM2_RegsWrType       = M2WBus.MEM2_RegsWrType;
    // output to MEM for CP0
    assign MM2Bus.MEM2_ALUOut    = M2WBus.MEM2_ALUOut;
    assign MM2Bus.MEM2_PC        = M2WBus.MEM2_PC;
    // output to WB
    assign M2WBus.MEM_DMOut      = cpu_dbus.rdata;       //读取结果直接放入DMOut
    //-------------------------------用于旁路的多选器-----------------------//
    MUX4to1 #(32) U_MUXINWB(
        .d0                  (M2WBus.MEM2_PC + 8),                                     // JAL,JALR等指令将PC+8写回RF
        .d1                  (M2WBus.MEM2_ALUOut),                                   // ALU计算结果
        .d2                  (M2WBus.MEM2_OutB  ),                                     // MTC0 MTHI LO等指令需要写寄存器
        .d3                  ('x                ),                               
        .sel4_to_1           (M2WBus.MEM2_WbSel ),
        .y                   (MEM2_Result       )                                    
    );
    
endmodule
