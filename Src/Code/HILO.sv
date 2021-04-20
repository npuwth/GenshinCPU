/*
 * @Author: npuwth
 * @Date: 2021-04-07 14:52:54
 * @LastEditTime: 2021-04-20 10:21:01
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

//`timescale 1ns / 1ps
//******************************************************************************
//                          特殊寄存器HI、LO模块
//******************************************************************************
`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module HILO(
    input logic                rst,
    input logic                clk,
    input logic                MULT_DIV_finish,
    //写端口
    input logic                HIWr,
    input logic                LOWr,
    input logic   [`RegBus]    Data_i,    //  MTLO MTHI
    input logic   [`RegBus]    EXE_MULTDIVtoLO,  // 乘除法写
    input logic   [`RegBus]    EXE_MULTDIVtoHI,  // 乘除法写

    //读端口
    output logic  [`RegBus]    HI_o,
    output logic  [`RegBus]    LO_o
    );

    always @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            HI_o <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1) begin
            HI_o <= EXE_MULTDIVtoHI;
        end else if (HIWr == `WriteEnable) begin
            HI_o <= Data_i;
        end 
    end
    always @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            LO_o <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1) begin
            LO_o <= EXE_MULTDIVtoLO;
        end else if (LOWr == `WriteEnable) begin
            LO_o <= Data_i;
        end
        // `ifdef DEBUG
        //     $monitor("HI:%8X LO:%8X",HI_o,LO_o);
        // `endif
    end
    
endmodule
