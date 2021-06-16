/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:24:26
 * @LastEditTime: 2021-06-16 17:49:20
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module MEMWB_Reg( MEM_WB_Interface port,
                  input                 rst );

  always_ff @(posedge port.clk ,negedge rst) begin
    if( rst == `RstEnable || port.MEMWB_Flush == `FlushEnable) begin
      WB_WbSel <= 2'b0;
      WB_PCAdd1 <= 32'b0;
      WB_ALUOut <= 32'b0;
      WB_OutB <= 32'b0;
      WB_DMOut <= 32'b0;
      WB_Dst <= 5'b0;
      WB_LoadType <= '0;
      WB_RegsWrType <= '0;
      WB_ExceptType <= '0;
      WB_IsABranch <= 1'b0;
      WB_IsAImmeJump <= 1'b0;
      WB_IsDelaySlot <= 1'b0;
      WB_Instr <= 32'b0;
      WB_Hi <= 32'b0;
      WB_Lo <= 32'b0;
    end
    else if( port.MEM_WBWr ) begin
      WB_WbSel <= port.MEM_WbSel;
      WB_PCAdd1 <= port.MEM_PCAdd1;
      WB_ALUOut <= port.MEM_ALUOut;
      WB_OutB <= port.MEM_OutB;
      WB_DMOut <= port.MEM_DMOut;
      WB_Dst <= port.MEM_Dst;
      WB_LoadType <= port.MEM_LoadType;
      WB_RegsWrType <= port.MEM_RegsWrType_new;
      WB_ExceptType <= port.MEM_ExceptType_final;
      WB_IsABranch <= port.MEM_IsABranch;
      WB_IsAImmeJump <= port.MEM_IsAImmeJump;
      WB_IsDelaySlot <= port.MEM_IsDelaySlot;
      WB_Instr <= port.MEM_Instr;
      WB_Hi <= port.MEM_Hi;
      WB_Lo <= port.MEM_Lo;
    end
  end

endmodule