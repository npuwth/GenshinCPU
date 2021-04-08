/*
 * @Author: Juan Jiang
 * @Date: 2021-04-05 20:20:45
 * @LastEditTime: 2021-04-08 22:09:05
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 9787111674139
 */
 
 `include "CPU_Defines.svh"

 module MIPS(
     input logic            clk,
     input logic            rst,
     input AsynExceptType   Interrupt//来自CPU外部的中断信号
 );

    logic           isBranch;//PCSEL的端口 
    logic           isImmeJump;
    logic [1:0]     isExceptorERET;
    logic [2:0]     PCSel;

    logic [31:0]    JumpAddr;//PCSel多选器
    logic [31:0]    BranchAddr;
    logic [31:0]    PC_4;
    logic [31:0]    EPCData;
// *******************************Johnson Yang & WTH **********/

    ExceptinPipeType MEM_ExceptType_AfterDM;
    PipeLineRegsInterface x(
        .clk(clk),
        .rst(rst)
    );

    MUX8to1 U_PCMUX(
        .d0(PC_4),
        .d1(JumpAddr),
        .d2(EPCData),
        .d3(32'h80000180),
        .d4(BranchAddr),
        .sel8_to_1(PCSel),
        .y(x.IF_NPC)
    );

    PCSEL U_PCSEL(
        .isBranch(isBranch),
        .isImmeJump(isImmeJump),
        .isExceptorERET(isExceptorERET),
        .PCSel(PCSel)
    );

    

    PC U_PC(
        x.PC
    );

    IFID_Reg U_IFID(
        x
    );

    IDEXE_Reg U_IDEXE(
        x
    );

    EXEMEM_Reg U_EXEMEM(
        x
    );

    MEMWB_Reg U_MEMWB(
        x
    );

    DCache U_Dachce(
        .clk(clk),
        .MEM_ALUOut(x.MEM_ALUOut),
        .MEM_OutB(x.MEM_OutB),
        .MEM_StoreType(x.MEM_StoreType),
        .MEM_LoadType(x.MEM_LoadType),
        .MEM_ExceptType(x.MEM_ExceptType),

        .MEM_ExceptType_new(MEM_ExceptType_AfterDM),  // 新的异常信号
        .MEM_DMOut(x.MEM_DMOut)                     // 输出
    );

    Exception U_Exception(
        .clk(clk),
        .rst(rst),
        .MEM_RegsWrType_i(x.MEM_RegsWrType),
        .MEM_RegsWrType_o(x.MEM_RegsWrType_new),
        .IFID_Flush(IFID_Flush),
        .IDEXE_Flush(IDEXE_Flush),
        .EXEMEM_Flush(EXEMEM_Flush),
        .MEMWB_Flush(MEMWB_Flush),
        .IsExceptionorEret(IsExceptionorEret)
    ),



 endmodule