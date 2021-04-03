/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:01:30
 * @LastEditTime: 2021-04-03 18:16:50
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module EXEMEM_Reg( PipeLineRegsInterface.EXE_MEM port );

  always_ff @( posedge port.clk ) begin
    if( port.rst | port.EXEMEM_Flush ) begin
      port.MEM_ALUOut <= 32'b0;
      port.MEM_PCAdd1 <= 32'b0;
      port.MEM_WbSel <= 2'b0;
      port.MEM_Dst <= 5'b0;
      port.MEM_LoadType <= '0;
      port.MEM_StoreType <= '0;
      port.MEM_RegsWrType <= '0;
      port.MEM_OutB <= 32'b0;
      port.MEM_ExceptType <= '0;
    end
    else begin
      port.MEM_ALUOut <= port.EXE_ALUOut;
      port.MEM_PCAdd1 <= port.EXE_PCAdd1;
      port.MEM_WbSel <= port.EXE_WbSel;
      port.MEM_Dst <= port.EXE_Dst;
      port.MEM_LoadType <= port.EXE_LoadType;
      port.MEM_StoreType <= port.EXE_StoreType;
      port.MEM_RegsWrType <= port.EXE_RegsWrType;
      port.MEM_OutB <= port.EXE_OutB;
      port.MEM_ExceptType <= port.EXE_ExceptType;
    end
  end

endmodule