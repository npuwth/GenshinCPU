/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-28 21:11:34
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_WB ( 
    input logic                  clk,
    input logic                  resetn,
    input logic                  WB_Flush,
    MEM_WB_Interface             MWBus,
    WB_CP0_Interface             WCBus,
    output logic [31:0]          WB_Result,
    output logic [4:0]           WB_Dst,
    output RegsWrType            WB_RegsWrType,
    output logic [31:0]          WB_Hi,
    output logic [31:0]          WB_Lo
);
    logic [31:0]                 WB_DMOut;
    logic [31:0]                 WB_ALUOut;
    LoadType                     WB_LoadType;
    logic [31:0]                 WB_DMResult;

    assign MWBus.WB_Dst          = WB_Dst;
    assign MWBus.WB_Result       = WB_Result;
    assign WCBus.WB_CP0Wr        = WB_RegsWrType.CP0Wr;
    assign WCBus.WB_Dst          = WB_Dst;
    assign WCBus.WB_Result       = WB_Result;
    assign WCBus.WB_ExceptType   = WB_ExceptType;
    assign WCBus.WB_PC           = WB_PC;
    assign WCBus.WB_IsInDelaySlot  = WB_IsInDelaySlot;
    assign WCBus.WB_ALUOut       = WB_ALUOut;
    
    WB_Reg U_WB_REG ( 
        .clk                  (clk ),
        .rst                  (rst ),
        .WB_Flush             (WB_Flush ),
        .MEM_ALUOut           (MWBus.MEM_ALUOut ),
        .MEM_Hi               (MWBus.MEM_Hi ),
        .MEM_Lo               (MWBus.MEM_Lo ),
        .MEM_PC               (MWBus.MEM_PC ),
        .MEM_Instr            (MWBus.MEM_Instr ),
        .MEM_WbSel            (MWBus.MEM_WbSel ),
        .MEM_Dst              (MWBus.MEM_Dst ),
        .MEM_LoadType         (MWBus.MEM_LoadType ),
        .MEM_DMOut            (MWBus.MEM_DMOut ),
        .MEM_OutB             (MWBus.MEM_OutB ),
        .MEM_RegsWrType_final (MWBus.MEM_RegsWrType_final ),
        .MEM_ExceptType_final (MWBus.MEM_ExceptType_final ),
        .MEM_IsABranch        (MWBus.MEM_IsABranch ),
        .MEM_IsAImmeJump      (MWBus.MEM_IsAImmeJump ),
        .MEM_IsInDelaySlot    (MWBus.MEM_IsInDelaySlot ),
        //-------------------------out----------------------------//
        .WB_ALUOut            (WB_ALUOut ),
        .WB_Hi                (WB_Hi ),
        .WB_Lo                (WB_Lo ),
        .WB_PC                (WB_PC ),
        .WB_Instr             (WB_Instr ),
        .WB_WbSel             (WB_WbSel ),
        .WB_Dst               (WB_Dst ),
        .WB_LoadType          (WB_LoadType ),
        .WB_DMOut             (WB_DMOut ),
        .WB_OutB              (WB_OutB ),
        .WB_RegsWrType        (WB_RegsWrType ),
        .WB_ExceptType        (WB_ExceptType ),
        .WB_IsABranch         (MWBus.WB_IsABranch ),
        .WB_IsAImmeJump       (MWBus.WB_IsAImmeJump ),
        .WB_IsInDelaySlot     (WB_IsInDelaySlot )
    );

    EXT2 U_EXT2(
        .WB_DMOut_i(WB_DMOut),
        .WB_ALUOut_i(WB_ALUOut),
        .WB_LoadType_i(WB_LoadType),
        .WB_DMResult_o(WB_DMResult)
    );

    MUX4to1 #(32) U_MUXINWB(
        .d0(WB_PC+8),                                     // JAL,JALR等指令将PC+8写回RF
        .d1(WB_ALUOut),                                   // ALU计算结果
        .d2(WB_OutB),                                     // MTC0 MTHI LO等指令需要写寄存器
        .d3(WB_DMResult),                               
        .sel4_to_1(WB_WbSel),
        .y(WB_Result)                                    
    );





endmodule