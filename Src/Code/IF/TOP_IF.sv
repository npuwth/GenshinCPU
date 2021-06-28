/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-28 21:31:29
 * @LastEditors: npuwth
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
    input logic [31:0]  MEM_CP0Epc,
    input logic [31:0]  EXE_BusA_L1,
    input logic IFID_Flush_BranchSolvement,
    input logic ID_IsAImmeJump,
    input logic IsExceptionorEret,
    input logic EXE_BranchType,
    IF_ID_Interface IIBus
);

    logic   [31:0]  IF_NPC;
    logic   [31:0]  IF_PC;
    logic   [2:0]   PCSel;

    assign PC_4 = IF_PC + 4;
    assign JumpAddr = {x.ID_PCAdd1[31:28],x.ID_Instr[25:0],2'b0};
    assign BranchAddr = x.EXE_PCAdd1+{x.EXE_Imm32[29:0],2'b0};

    PC U_PC ( 
        .clk(clk),
        .rst(rst),
        .PC_Wr(PC_Wr),
        .IF_NPC(IF_NPC),
        //---------------output----------------//
        .IF_PC(IF_PC)
    );

    MUX8to1 U_PCMUX (
        .d0(PC_4),
        .d1(JumpAddr),
        .d2(MEM_CP0Epc),
        .d3(32'hBFC00380),
        .d4(BranchAddr),
        .d5(EXE_BusA_L1),
        .sel8_to_1(PCSel),
        //---------------output----------------//
        .y(IF_NPC)
    );

    PCSEL U_PCSEL(
        .isBranch(IFID_Flush_BranchSolvement),
        .isImmeJump(ID_IsAImmeJump),
        .isExceptorERET(IsExceptionorEret),
        .EXE_BranchType(EXE_BranchType),
        //---------------output-------------------//
        .PCSel(PCSel)
    );

endmodule