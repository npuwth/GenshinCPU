/*
 * @Author: npuwth
 * @Date: 2021-07-12 16:23:07
 * @LastEditTime: 2021-07-15 13:16:13
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module IF_REG( 
    input  logic             clk,
    input  logic             rst,
    input  logic             IF_Wr,
    input  logic             IF_Flush,
    input logic  [31:0]      PREIF_PC,
    input  ExceptinPipeType  IFTLB_ExceptType,
    
    output logic [31:0]      IF_PC,
    output ExceptinPipeType  IF_ExceptType
);
  
  always_ff @( posedge clk ) begin
    if( (rst == `RstEnable) || (IF_Flush == `FlushEnable) ) begin
      IF_PC                 <= '0;
      IFTLB_ExceptType      <= '0;

    end
    else if( IF_Wr ) begin
      IF_PC                 <= PREIF_PC;
      IFTLB_ExceptType      <= IF_ExceptType;
    end
  end

endmodule