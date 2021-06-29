/*
 * @Author: npuwth
 * @Date: 2021-04-07 14:52:54
 * @LastEditTime: 2021-06-28 22:38:19
 * @LastEditors: npuwth
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
    input logic   [`RegBus]    Data_Wr,    //  MTLO MTHI
    input logic   [`RegBus]    EXE_MULTDIVtoLO,  // 乘除法写
    input logic   [`RegBus]    EXE_MULTDIVtoHI,  // 乘除法写

    //读端口
    output logic  [`RegBus]    HI_Rd,
    output logic  [`RegBus]    LO_Rd
    );
    
    logic [`RegBus] HI;
    logic [`RegBus] LO;

    always_comb begin
        if(MULT_DIV_finish == 1'b1)
            HI_Rd = EXE_MULTDIVtoHI;
        else if(HIWr == 1'b1)
            HI_Rd = Data_Wr;
        else begin
            HI_Rd = HI;
        end
    end

    always_comb begin
        if(MULT_DIV_finish == 1'b1)
            LO_Rd = EXE_MULTDIVtoLO;
        else if(LOWr == 1'b1)
            LO_Rd = Data_Wr;
        else begin
            LO_Rd = LO;
        end
    end

    always @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            HI <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1) begin
            HI <= EXE_MULTDIVtoHI;
        end else if (HIWr == `WriteEnable) begin
            HI <= Data_Wr;
        end 
    end
    always @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            LO <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1) begin
            LO <= EXE_MULTDIVtoLO;
        end else if (LOWr == `WriteEnable) begin
            LO <= Data_Wr;
        end
        // `ifdef DEBUG
        //     $monitor("HI:%8X LO:%8X",HI_Rd,LO_Rd);
        // `endif
    end
    
endmodule
