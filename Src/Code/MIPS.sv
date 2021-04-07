/*
 * @Author: Juan Jiang
 * @Date: 2021-04-05 20:20:45
 * @LastEditTime: 2021-04-07 15:10:48
 * @LastEditors: Juan Jiang
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






 endmodule