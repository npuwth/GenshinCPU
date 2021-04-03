/*
 * @Author: npuwth
 * @Date: 2021-03-31 15:16:20
 * @LastEditTime: 2021-04-03 11:00:08
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 `include "CPU_Defines.svh"
 `include "CommonDefines.svh"

module IDEXE_Reg( PipeLineRegsInterface.ID_EXE port );

  always_ff @( posedge port.clk ) begin
    if( port.rst | port.IDEXE_Flush ) begin
      port.EXE_BusA <= 32'b0;
      port.EXE_BusB <= 32'b0;
      port.EXE_Imm32 <= 32'b0;
      port.EXE_PCAdd1 <= 32'b0;
      port.EXE_rs <= 5'b0;
      port.EXE_rt <= 5'b0;
      port.EXE_rd <= 5'b0;
      port.EXE_ALUOp <= 4'b0;
      port.EXE_LoadType <= '{0,2'b0};
      port.EXE_StoreType <= '{2'b0};
      port.EXE_RegsWrType <= '{0,0,0};
      port.EXE_WbSel <= 2'b0;
      port.EXE_DstSel <= 2'b0;
      port.EXE_ReadMem <= 1'b0;
      port.EXE_DMWr <= 1'b0;
      port.EXE_ExceptType <= '{0,0,0,0,0,0};
      port.EXE_Shamt <= 5'b0;
      port.EXE_Funct <= 6'b0;
    end
    else begin
      port.EXE_BusA <= port.ID_BusA;
      port.EXE_BusB <= port.ID_BusB;
      port.EXE_Imm32 <= port.ID_Imm32;
      port.EXE_PCAdd1 <= port.ID_PCAdd1;
      port.EXE_rs <= port.ID_rs;
      port.EXE_rt <= port.ID_rt;
      port.EXE_rd <= port.ID_rd;
      port.EXE_ALUOp <= port.ID_ALUOp;
      port.EXE_LoadType <= port.ID_LoadType;
      port.EXE_StoreType <= port.ID_StoreType;
      port.EXE_RegsWrType <= port.ID_RegsWrType;
      port.EXE_WbSel <= port.ID_WbSel;
      port.EXE_DstSel <= port.ID_DstSel;
      port.EXE_ReadMem <= port.ID_ReadMem;
      port.EXE_DMWr <= port.ID_DMWr;
      port.EXE_ExceptType <= port.ID_ExceptType;
      port.EXE_Shamt <= port.ID_Imm32[10:6];
      port.EXE_Funct <= port.ID_Imm32[5:0];
    end
  end

endmodule