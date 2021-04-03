/*
 * @Author: npuwth
 * @Date: 2021-03-29 15:27:17
 * @LastEditTime: 2021-04-03 16:56:24
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0 
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"
`define SW  2'b00
`define SH  2'b01
`define SB  2'b10

module DCache(clk,MEM_ALUOut_i,MEM_OutB_i,MEM_StoreType_i,MEM_DMWr_i,MEM_DMOut_o);

  input logic           clk;
  input logic [31:0]    MEM_ALUOut_i;
  input logic [31:0]    MEM_OutB_i;
  input StoreType       MEM_StoreType_i;
  input logic           MEM_DMWr_i;
  output logic [31:0]   MEM_DMOut_o;
  logic [31:0] Dmem[1023:0];

assign MEM_DMOut_o = Dmem[MEM_ALUOut_i[11:2]];

always_ff @(posedge clk) begin
  
    if(MEM_DMWr_i)

      unique case(MEM_StoreType_i.size)
        `STORETYPE_SW: begin //SW
          Dmem[MEM_ALUOut_i[11:2]] = MEM_OutB_i;
        end
        `STORETYPE_SH: begin //SH
          if(MEM_ALUOut_i[1] == 1'b0)
            Dmem[MEM_ALUOut_i[11:2]][15:0] = MEM_OutB_i[15:0];
          else
            Dmem[MEM_ALUOut_i[11:2]][31:16] = MEM_OutB_i[15:0];
        end
        `STORETYPE_SB: begin //SB
          if(MEM_ALUOut_i[1:0] == 2'b00)
            Dmem[MEM_ALUOut_i[11:2]][7:0] = MEM_OutB_i[7:0];
          else if(MEM_ALUOut_i[1:0] == 2'b01)
            Dmem[MEM_ALUOut_i[11:2]][15:8] = MEM_OutB_i[7:0];
          else if(MEM_ALUOut_i[1:0] == 2'b10)
            Dmem[MEM_ALUOut_i[11:2]][23:16] = MEM_OutB_i[7:0];
          else
            Dmem[MEM_ALUOut_i[11:2]][31:24] = MEM_OutB_i[7:0];
        end
        default: begin
          Dmem[MEM_ALUOut_i[11:2]] = MEM_OutB_i;
        end
      endcase
    //else  
end

endmodule