/*
 * @Author: Juan Jiang
 * @Date: 2021-04-05 20:20:45
 * @LastEditTime: 2021-04-07 22:12:42
 * @LastEditors: Seddon Shen
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

    logic           isBranch;//PCSEL的端口 
    logic           isImmeJump;
    logic [1:0]     isExceptorERET;
    logic [2:0]     PCSel;

    logic [31:0]    JumpAddr;//PCSel多选器
    logic [31:0]    BranchAddr;
    logic [31:0]    PC_4;
    logic [31:0]    EPCData;

//---------------------------------------------seddon
    logic [1:0] EXE_ForwardA,EXE_ForwardB; 
    logic [31:0] EXE_OutA,EXE_OutB;
    logic IFID_Flush;
    logic [31:0] WB_Result;
    logic [31:0] EXE_ResultA,EXE_ResultB;
//------------------------seddonend

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
//---------------------------------------------seddon
    ForwardUnit U_ForwardUnit(
        .WB_RegsWrType(x.WB_RegsWrType),
        .MEM_RegsWrType(x.MEM_RegsWrType),
        .EXE_rt(x.EXE_rt),
        .EXE_rs(x.EXE_rs),
        .MEM_Wr(x.MEM_Wr),
        .WB_Wr(x.WB.Wr),
        .MEM_Dst(x.MEM_Dst),
        .WB_Dst(x.WB_Dst),
        .EXE_ForwardA(EXE_ForwardA),
        .EXE_ForwardB(EXE_ForwardB)//该模块已检查
    );

    BranchSolve U_BranchSolve(
        .EXE_BranchType(x.EXE_BranchType),//新定义的信号，得在定义里面新加
        .EXE_OutA(EXE_OutA),
        .EXE_OutB(EXE_OutB),//INPUT
        .IFID_Flush(IFID_Flush)//这个阻塞信号的线没有加，只是定义了一个
    );
    
    MUX3to1 U_MUXA(
        .d0(x.EXE_BusA),
        .d1(x.MEM_ALUOut),
        .d2(x.WB_Result),
        .sel3_to_1(EXE_ForwardA),
        .y(EXE_OutA)
    );//EXE级组合逻辑三选一A
    
    MUX3to1 U_MUXB(
        .d0(x.EXE_BusB),
        .d1(x.MEM_ALUOut),
        .d2(x.WB_Result),
        .sel3_to_1(EXE_ForwardB),
        .y(EXE_OutB)
    );//EXE级组合逻辑三选一B

    MUX2to1 U_MUXSrcA(
        .d0(EXE_OutA),
        .d1(x.EXE_Shamt),
        .sel2_to_1(x.EXE_ALUSrcA),
        .y(EXE_ResultA)
    );//EXE级三选一A之后的那个二选一

    MUX2to1 U_MUXSrcB(
        .d0(EXE_OutB),
        .d1(x.EXE_Imm32),
        .sel2_to_1(x.EXE_ALUSrcB),
        .y(EXE_ResultB)
    );//EXE级三选一B之后的那个二选一

    MUX3to1 U_EXEDstSrc(
        .d0(x.EXE_rd),
        .d1(x.EXE_rt),
        .d2(32'b0000_0000_0000_0000_0000_0000_0001_1111),
        .sel3_to_1(x.EXE_DstSel),
        .y(x.EXE_Dst)
    );//EXE级Dst三选一
    
    ALU U_ALU(
        .EXE_ExceptType(x.EXE_ExceptType),
        .EXE_ResultA(EXE_ResultA),
        .EXE_ResultB(EXE_ResultB),
        .EXE_ALUOp(x.EXE_ALUOp),
        .EXE_ALUOut(x.EXE_ALUOut),
        .EXE_ExceptType_new(x.EXE_ExceptType)//input
    );
//---------------------------------------------seddonend
    

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






 endmodule