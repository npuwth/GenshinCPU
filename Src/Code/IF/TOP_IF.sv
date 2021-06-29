/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-29 15:54:19
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_IF ( 
    input logic         clk,
    input logic         resetn,
    input logic         PC_Wr,
    input logic [31:0]  MEM_CP0Epc,
    input logic [31:0]  EXE_BusA_L1,
    input logic         ID_Flush_BranchSolvement,
    input logic         ID_IsAImmeJump,
    input logic         IsExceptionorEret,
    input logic         EXE_BranchType,
    input logic         ID_Wr,
    input logic         ID_Flush_Exception,
    input logic         EXE_Flush_DataHazard,
    input logic [31:0]  EXE_PC,
    input logic [31:0]  EXE_Imm32,
    IF_ID_Interface.IF  IIBus,
    AXI_Bus_Interface   axi_ibus
);

    logic   [31:0]      IF_PC;
    logic   [31:0]      IF_NPC;
    logic   [2:0]       PCSel;
    logic   [31:0]      ID_PCAdd4;

    assign PC_4         = IF_PC + 4;
    assign ID_PCAdd4    = IIBus.ID_PC+4;
    assign JumpAddr     = {ID_PCAdd4[31:28],IIBus.ID_Instr[25:0],2'b0};
    assign BranchAddr   = EXE_PC+4+{EXE_Imm32[29:0],2'b0};

    assign IIBus.IF_PC    = IF_PC;

    PC U_PC ( 
        .clk            (clk),
        .rst            (resetn),
        .PC_Wr          (PC_Wr),
        .IF_NPC         (IF_NPC),
        //---------------output----------------//
        .IF_PC          (IF_PC)
    );

    MUX8to1 U_PCMUX (
        .d0             (PC_4),
        .d1             (JumpAddr),
        .d2             (MEM_CP0Epc),
        .d3             (32'hBFC00380),
        .d4             (BranchAddr),
        .d5             (EXE_BusA_L1),
        .sel8_to_1      (PCSel),
        //---------------output----------------//
        .y              (IF_NPC)
    );

    PCSEL U_PCSEL(
        .isBranch       (ID_Flush_BranchSolvement),
        .isImmeJump     (ID_IsAImmeJump),
        .isExceptorERET (IsExceptionorEret),
        .EXE_BranchType (EXE_BranchType),
        //---------------output-------------------//
        .PCSel          (PCSel)
    );

    //---------------------------------cache--------------------------------//
    assign IIBus.IF_Instr = cpu_ibus.rdata;
    assign {cpu_ibus.tag,cpu_ibus.index,cpu_ibus.offset} = IF_NPC;    // 如果D$ busy 则将PC送给I$ ,否则送NPC
    assign cpu_ibus.valid = (ID_Flush_Exception)?1'b1:(EXE_Flush_DataHazard || ID_Wr == 1'b0)?1'b0:1'b1;
    assign cpu_ibus.op    = 1'b0;
    assign cpu_ibus.wstrb = 'x;
    assign cpu_ibus.wdata = 'x;
    assign cpu_ibus.ready = ID_Wr;

    ICache U_ICache(
        .clk            (clk),
        .resetn         (resetn),
        .CPUBus         (cpu_ibus.slave),
        .AXIBus         (axi_ibus.master)
    );

endmodule