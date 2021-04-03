/*
 * @Author: npuwth
 * @Date: 2021-03-29 14:36:47
 * @LastEditTime: 2021-04-03 16:46:08
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module EXT2(WB_DMOut_i,WB_ALUOut_i,WB_DMResult_o,WB_LoadType_i);

  input logic [31:0]    WB_DMOut_i;
  input logic [31:0]    WB_ALUOut_i;
  input LoadType        WB_LoadType_i;
  output logic [31:0]   WB_DMResult_o; 

  always_comb begin
    unique case({WB_LoadType_i.sign,WB_LoadType_i.size})
      `LOADTYPE_LW: WB_DMResult_o = WB_DMOut_i;  //LW
      `LOADTYPE_LH: if(WB_ALUOut_i[1] == 1'b0) //LH
                WB_DMResult_o = {{16{WB_DMOut_i[15]}},WB_DMOut_i[15:0]};
              else
                WB_DMResult_o = {{16{WB_DMOut_i[31]}},WB_DMOut_i[31:16]}; 
      `LOADTYPE_LHU: if(WB_ALUOut_i[1] == 1'b0) //LHU
                WB_DMResult_o = {16'b0,WB_DMOut_i[15:0]};
              else
                WB_DMResult_o = {16'b0,WB_DMOut_i[31:16]};
      `LOADTYPE_LB: if(WB_ALUOut_i[1:0] == 2'b00) //LB
                WB_DMResult_o = {{24{WB_DMOut_i[7]}},WB_DMOut_i[7:0]};
              else if(WB_ALUOut_i[1:0] == 2'b01)
                WB_DMResult_o = {{24{WB_DMOut_i[15]}},WB_DMOut_i[15:8]};
              else if(WB_ALUOut_i[1:0] == 2'b10)
                WB_DMResult_o = {{24{WB_DMOut_i[23]}},WB_DMOut_i[23:16]};
              else
                WB_DMResult_o = {{24{WB_DMOut_i[31]}},WB_DMOut_i[31:24]};
      `LOADTYPE_LBU: if(WB_ALUOut_i[1:0] == 2'b00) //LBU
                WB_DMResult_o = {24'b0,WB_DMOut_i[7:0]};
              else if(WB_ALUOut_i[1:0] == 2'b01)
                WB_DMResult_o = {24'b0,WB_DMOut_i[15:8]};
              else if(WB_ALUOut_i[1:0] == 2'b10)
                WB_DMResult_o = {24'b0,WB_DMOut_i[23:16]};
              else
                WB_DMResult_o = {24'b0,WB_DMOut_i[31:24]};
      default:WB_DMResult_o = 32'b0;
    endcase
  end

endmodule