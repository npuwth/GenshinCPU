/*
 * @Author: npuwth
 * @Date: 2021-03-29 15:27:17
 * @LastEditTime: 2021-04-03 18:00:54
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0 
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module DCache(clk,MEM_ALUOut,MEM_OutB,MEM_StoreType,MEM_LoadType,MEM_ExceptType,MEM_ExceptType_new,MEM_DMOut);

  input logic              clk;
  input logic [31:0]       MEM_ALUOut;
  input logic [31:0]       MEM_OutB;
  input StoreType          MEM_StoreType;
  input LoadType           MEM_LoadType;
  input ExceptinPipeType   MEM_ExceptType;
  output ExceptinPipeType  MEM_ExceptType_new;
  output logic [31:0]      MEM_DMOut;
  logic [31:0]             Dmem[1023:0];

  assign MEM_DMOut = Dmem[MEM_ALUOut[11:2]];

  always_ff @(posedge clk) begin
      
    if(MEM_StoreType.DMWr)
      unique case(MEM_StoreType.sign)
        `STORETYPE_SW: begin //SW
          Dmem[MEM_ALUOut[11:2]] <= MEM_OutB;
        end
        `STORETYPE_SH: begin //SH
          if(MEM_ALUOut[1] == 1'b0)
            Dmem[MEM_ALUOut[11:2]][15:0] <= MEM_OutB[15:0];
          else
            Dmem[MEM_ALUOut[11:2]][31:16] <= MEM_OutB[15:0];
        end
        `STORETYPE_SB: begin //SB
          if(MEM_ALUOut[1:0] == 2'b00)
            Dmem[MEM_ALUOut[11:2]][7:0] <= MEM_OutB[7:0];
          else if(MEM_ALUOut[1:0] == 2'b01)
            Dmem[MEM_ALUOut[11:2]][15:8] <= MEM_OutB[7:0];
          else if(MEM_ALUOut[1:0] == 2'b10)
            Dmem[MEM_ALUOut[11:2]][23:16] <= MEM_OutB[7:0];
          else
            Dmem[MEM_ALUOut[11:2]][31:24] <= MEM_OutB[7:0];
        end
        default: begin
          Dmem[MEM_ALUOut[11:2]] <= MEM_OutB;
        end
      endcase
    //else  
  end

  assign MEM_ExceptType_new.Interrupt = MEM_ExceptType.Interrupt;
  assign MEM_ExceptType_new.WrongAddressinIF = MEM_ExceptType.WrongAddressinIF;
  assign MEM_ExceptType_new.ReservedInstruction = MEM_ExceptType.ReservedInstruction;
  assign MEM_ExceptType_new.Syscall = MEM_ExceptType.Syscall;
  assign MEM_ExceptType_new.Break = MEM_ExceptType.Break;
  assign MEM_ExceptType_new.Eret = MEM_ExceptType.Eret;
  assign MEM_ExceptType_new.WrWrongAddressinMEM = MEM_StoreType.DMWr&&(((MEM_StoreType.sign == `STORETYPE_SW)&&(MEM_ALUOut[1:0] != 2'b00))||((MEM_StoreType.sign == `STORETYPE_SH)&&(MEM_ALUOut[0] != 1'b0)));
  assign MEM_ExceptType_new.RdWrongAddressinMEM = MEM_LoadType.ReadMem&&(((MEM_LoadType.sign == 2'b00)&&(MEM_ALUOut[1:0] != 2'b00))||((MEM_LoadType.sign == 2'b01)&&(MEM_ALUOut[0] != 1'b0)));
  assign MEM_ExceptType_new.Overflow = MEM_ExceptType.Overflow;

endmodule