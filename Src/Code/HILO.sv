`timescale 1ns / 1ps
//******************************************************************************
//                          特殊寄存器HI、LO模块
//******************************************************************************
`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module hilo_reg(
    input logic                rst,
    input logic                clk,

    //写端口
    input logic                HIWr,
    input logic                LOWr,
    input logic   [`RegBus]    HI_i,
    input logic   [`RegBus]    LO_i,

    //读端口
    output logic  [`RegBus]    HI_o,
    output logic  [`RegBus]    LO_o
    );

    always @ ( posedge clk ) begin
        if(rst == `RstEnable) begin
            HI_o <= `ZeroWord;
            LO_o <= `ZeroWord;
        end else if (HIWr == `WriteEnable) begin
            HI_o <= HI_i;
        end else if (LOWr == `WriteEnable) begin
            LO_o <= LO_i;
        end
    end
    `ifdef DEBUG
        $monitor("HI:%8X LO:%8X",HI_o,LO_o);
    `endif
    
endmodule
