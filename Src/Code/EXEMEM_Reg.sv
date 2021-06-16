/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:01:30
 * @LastEditTime: 2021-06-16 18:09:12
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module EXEMEM_Reg ( 

    input logic [31:0]       EXE_ALUOut,
    input logic [31:0]       EXE_PC,
    input logic [1:0]       EXE_WbSel,
    input logic [4:0]       EXE_Dst,
    input LoadType          EXE_LoadType,
    input StoreType         EXE_StoreType,
    input RegsWrType        EXE_RegsWrType,
    input logic [31:0]       EXE_OutB,
    input ExceptinPipeType        EXE_ExceptType_final,
    input logic        EXE_BranchType;
    input logic        EXE_IsAImmeJump,
    input logic        EXE_Instr,
    input logic        EXE_Hi,
    input logic        EXE_Lo,
    input logic   rst,
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
    output logic
);

    always_ff @( posedge port.clk ,negedge rst ) begin
        if( (rst == `RstEnable )|| ( EXEMEM_Flush == `FlushEnable )) begin
            MEM_ALUOut         <= 32'b0;
            MEM_PCAdd1         <= 32'b0;
            MEM_WbSel          <= 2'b0;
            MEM_Dst            <= 5'b0;
            MEM_LoadType       <= '0;
            MEM_StoreType      <= '0;
            MEM_RegsWrType     <= '0;
            MEM_OutB           <= 32'b0;
            MEM_ExceptType     <= '0;
            MEM_IsABranch      <= '0;
            MEM_IsAImmeJump    <= 1'b0;
            MEM_Instr          <= 32'b0;
            MEM_Hi             <= 32'b0;
            MEM_Lo             <= 32'b0;
        end
        else if( EXE_MEMWr ) begin
            MEM_ALUOut <= EXE_ALUOut;
            MEM_PCAdd1 <= EXE_PCAdd1;
            MEM_WbSel <= EXE_WbSel;
            MEM_Dst <= EXE_Dst;
            MEM_LoadType <= EXE_LoadType;
            MEM_StoreType <= EXE_StoreType;
            MEM_RegsWrType <= EXE_RegsWrType;
            MEM_OutB <= EXE_OutB;
            MEM_ExceptType <= EXE_ExceptType_final;
            MEM_IsABranch <= EXE_BranchType.isBranch;
            MEM_IsAImmeJump <= EXE_IsAImmeJump;
            MEM_Instr <= EXE_Instr;
            MEM_Hi <= EXE_Hi;
            MEM_Lo <= EXE_Lo;
        end
    end
endmodule