/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:24:26
 * @LastEditTime: 2021-07-12 12:03:22
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module WB_Reg (
//-----------------------------------------------------------------//   
    input logic                         clk,
    input logic                         rst,
    input logic                         WB_Flush,
    input logic                         WB_Wr,
    
    input logic		  [31:0] 		          MEM2_ALUOut,		
    input logic 		[31:0] 		          MEM2_PC,	
    input logic     [31:0]              MEM2_Instr,		
    input logic 		[1:0]  		          MEM2_WbSel,				
    input logic 		[4:0]  		          MEM2_Dst,
	  // input LoadType     			            MEM2_LoadType,
	  input logic 		[31:0] 		          MEM2_DMOut,
    input logic     [31:0]              MEM2_OutB,
	  input RegsWrType                    MEM2_RegsWrType,//经过exception solvement的新写使能
	  // input ExceptinPipeType 		          MEM2_ExceptType,
	  // input logic                         MEM_IsABranch,
	  // input logic                         MEM_IsAImmeJump,
	  // input logic                         MEM_IsInDelaySlot,
//------------------------------------------------------------------//
    output logic		[31:0] 		          WB_ALUOut,		
    output logic 		[31:0] 		          WB_PC,
    output logic    [31:0]              WB_Instr,			
    output logic 		[1:0]  		          WB_WbSel,				
    output logic 		[4:0]  		          WB_Dst,
	  // output LoadType     			          WB_LoadType,
	  output logic 		[31:0] 		          WB_DMOut,
    output logic    [31:0]              WB_OutB,
	  output RegsWrType                   WB_RegsWrType,//经过exception solvement的新写使能
	  // output ExceptinPipeType 		        WB_ExceptType
	  // output logic                        WB_IsABranch,
	  // output logic                        WB_IsAImmeJump,
	  // output logic                        WB_IsInDelaySlot
);

  always_ff @(posedge clk ) begin
    if( rst == `RstEnable || WB_Flush == `FlushEnable) begin
      WB_WbSel                          <= 2'b0;
      WB_PC                             <= 32'b0;
      WB_ALUOut                         <= 32'b0;
      WB_OutB                           <= 32'b0;
      WB_DMOut                          <= 32'b0;
      WB_Dst                            <= 5'b0;
      WB_RegsWrType                     <= '0;
      WB_Instr                          <= 32'b0;
    end
    else if( WB_Wr ) begin
      WB_WbSel                          <= MEM2_WbSel;
      WB_PC                             <= MEM2_PC;
      WB_ALUOut                         <= MEM2_ALUOut;
      WB_OutB                           <= MEM2_OutB;
      WB_DMOut                          <= MEM2_DMOut;
      WB_Dst                            <= MEM2_Dst;
      WB_RegsWrType                     <= MEM2_RegsWrType;
      WB_Instr                          <= MEM2_Instr;
    end
  end

endmodule