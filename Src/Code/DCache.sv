/*
 * @Author: npuwth
 * @Date: 2021-03-29 15:27:17
 * @LastEditTime: 2021-04-10 12:52:43
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0 
 * @IO PORT:
 * @Description: 改成了组合逻辑
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module DCache(clk,MEM_ALUOut,MEM_OutB,MEM_StoreType,MEM_LoadType,MEM_ExceptType,MEM_ExceptType_new,MEM_SWData,data_sram_wen);

  input logic              clk;
  input logic [31:0]       MEM_ALUOut;
  input logic [31:0]       MEM_OutB;
  input StoreType          MEM_StoreType;
  input LoadType           MEM_LoadType;
  input ExceptinPipeType   MEM_ExceptType;
  
  output ExceptinPipeType  MEM_ExceptType_new;  
  output logic [3:0]       data_sram_wen;       //字节信号写使能
  output logic [31:0]      MEM_SWData;          //StoreType要写入的信号

  // assign MEM_DMOut = Dmem[MEM_ALUOut[11:2]];

  always_comb begin
      
    if(MEM_StoreType.DMWr) begin
      unique case(MEM_StoreType.sign)
        `STORETYPE_SW: begin //SW
          // Dmem[MEM_ALUOut[11:2]] <= MEM_OutB;
          MEM_SWData    <= MEM_OutB;
          data_sram_wen <= 4'b1111;
        end
        `STORETYPE_SH: begin //SH
          if(MEM_ALUOut[1] == 1'b0)begin
            MEM_SWData    <= {16'b0,MEM_OutB[15:0]};
            data_sram_wen <= 4'b0011;
          end
            // Dmem[MEM_ALUOut[11:2]][15:0] <= MEM_OutB[15:0];
          else begin
            MEM_SWData    <= {MEM_OutB[15:0],16'b0};
            data_sram_wen <= 4'b1100;
          end
            // Dmem[MEM_ALUOut[11:2]][31:16] <= MEM_OutB[15:0];
        end
        `STORETYPE_SB: begin //SB
          if(MEM_ALUOut[1:0] == 2'b00) begin
            MEM_SWData    <= {24'b0,MEM_OutB[7:0]};
            data_sram_wen <= 4'b0001;
          end
            // Dmem[MEM_ALUOut[11:2]][7:0] <= MEM_OutB[7:0];
          else if(MEM_ALUOut[1:0] == 2'b01) begin
            MEM_SWData    <= {16'b0,MEM_OutB[7:0],8'b0};
            data_sram_wen <= 4'b0010;
          end
            // Dmem[MEM_ALUOut[11:2]][15:8] <= MEM_OutB[7:0];
          else if(MEM_ALUOut[1:0] == 2'b10) begin
            MEM_SWData    <= {8'b0,MEM_OutB[7:0],16'b0};
            data_sram_wen <= 4'b0100;
          end
            // Dmem[MEM_ALUOut[11:2]][23:16] <= MEM_OutB[7:0];
          else if(MEM_ALUOut[1:0] == 2'b11) begin
            MEM_SWData    <= {MEM_OutB[7:0],24'b0};
            data_sram_wen <= 4'b1000;
          end
            // Dmem[MEM_ALUOut[11:2]][31:24] <= MEM_OutB[7:0];
        end
        default: begin
            MEM_SWData    <= 32'b0;
            data_sram_wen <= 4'b0000;
        end
        
      endcase
    end else begin
      MEM_SWData    <= 32'b0;
      data_sram_wen <= 4'b0000;
    end
      
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