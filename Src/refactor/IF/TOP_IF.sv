/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-16 12:42:07
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_IF ( 
    input logic                 clk,
    input logic                 resetn,
    input logic                 IF_Wr,
    input logic                 IF_Flush,
    input logic  [31:0]         PREIF_PC,
    input logic  [1:0]          IF_TLBExceptType,
    IF_ID_Interface             IIBus,
    CPU_Bus_Interface           cpu_ibus
);

    ExceptinPipeType PREIF_ExceptType;
    
    always_comb begin
        if(IF_TLBExceptType == `IF_TLBRefill) begin
            PREIF_ExceptType = {10'b0,1'b1,8'b0};
        end
        else if(IF_TLBExceptType == `IF_TLBInvalid) begin
            PREIF_ExceptType = {11'b0,1'b1,7'b0};
        end
        else begin
            PREIF_ExceptType = '0;
        end
    end
    
    IF_REG U_IF_REG (
        .clk                    (clk ),
        .rst                    (resetn ),
        .IF_Wr                  (IF_Wr ),
        .IF_Flush               (IF_Flush ),
        .PREIF_PC               (PREIF_PC ),
        .PREIF_ExceptType       (PREIF_ExceptType ),
//-----------------------------output-------------------------------------//
        .IF_PC                  (IIBus.IF_PC ),
        .IF_ExceptType          (IIBus.IF_ExceptType)
    );  

    assign IIBus.IF_Instr = cpu_ibus.rdata;

endmodule