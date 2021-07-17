/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-17 16:07:19
 * @LastEditors: Please set LastEditors
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
    input logic                  WB_Wr,
    input logic                  WB_DisWr,
    input logic                  MEM2_store_req,
    MEM2_WB_Interface            M2WBus,
    //--------------------output--------------------//
    output logic [31:0]          WB_Result,
    output logic [4:0]           WB_Dst,
    output RegsWrType            WB_Final_Wr,
    output RegsWrType            WB_RegsWrType,
    output logic [31:0]          WB_PC,
    output logic                 WB_store_req,
    output logic [31:0]          WB_ALUOut,
    output logic                 WB_Isincache
);
    logic [31:0]                 WB_DMOut;
    // logic [31:0]                 WB_ALUOut;
    logic [31:0]                 WB_Instr;
    logic [31:0]                 WB_OutB;
    logic [1:0]                  WB_WbSel;

    assign WB_Final_Wr = (WB_DisWr)? '0: WB_RegsWrType ;  // Dcache 停滞流水线时 wb级数据不能写入RF
    
    WB_Reg U_WB_REG ( 
        .clk                  (clk ),
        .rst                  (resetn ),
        .WB_Flush             (WB_Flush ),
        .WB_Wr                (WB_Wr ),
        
        .MEM2_ALUOut          (M2WBus.MEM2_ALUOut ),
        .MEM2_PC              (M2WBus.MEM2_PC ),
        .MEM2_Instr           (M2WBus.MEM2_Instr ),
        .MEM2_WbSel           (M2WBus.MEM2_WbSel ),
        .MEM2_Dst             (M2WBus.MEM2_Dst ),
        .MEM2_DMOut           (M2WBus.MEM2_DMOut ),
        .MEM2_OutB            (M2WBus.MEM2_OutB ),
        .MEM2_RegsWrType      (M2WBus.MEM2_RegsWrType ),
        .MEM2_store_req       (MEM2_store_req),
        .MEM2_Isincache       (M2WBus.MEM2_Isincache),
        //-------------------------out----------------------------//
        .WB_ALUOut            (WB_ALUOut ),
        .WB_PC                (WB_PC ),
        .WB_Instr             (WB_Instr ),
        .WB_WbSel             (WB_WbSel ),
        .WB_Dst               (WB_Dst ),
        .WB_DMOut             (WB_DMOut ),
        .WB_OutB              (WB_OutB ),
        .WB_RegsWrType        (WB_RegsWrType ),
        .WB_store_req         (WB_store_req),
        .WB_Isincache         (WB_Isincache)
    );

  
    MUX4to1 #(32) U_MUXINWB(
        .d0                  (WB_PC+8),                                     // JAL,JALR等指令将PC+8写回RF
        .d1                  (WB_ALUOut),                                   // ALU计算结果
        .d2                  (WB_OutB),                                     // MTC0 MTHI LO等指令需要写寄存器
        .d3                  (WB_DMOut),                               
        .sel4_to_1           (WB_WbSel),
        .y                   (WB_Result)                                    
    );

endmodule