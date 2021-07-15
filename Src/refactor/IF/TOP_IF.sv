/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-12 12:07:54
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
    input ExceptinPipeType      IFTLB_ExceptType,
    IF_ID_Interface             IIBus,
    CPU_Bus_Interface           cpu_ibus
    // AXI_Bus_Interface   axi_ibus,
    // output logic [31:0] IF_NPC,
    // output logic [31:0] Virt_Iaddr,
    // output ExceptinPipeType IF_ExceptType
);

    // assign IIBus.IF_PC         = IF_PC;
    // assign IIBus.IF_ExceptType = IF_ExceptType_new; //现在没加tlb，所以先直接初始化成0

      IF_REG U_IF_REG (
        .clk                    (clk ),
        .rst                    (resetn ),
        .IF_Wr                  (IF_Wr ),
        .IF_Flush               (IF_Flush ),

        .PREIF_PC               (PREIF_PC ),
        .IFTLB_ExceptType       (IFTLB_ExceptType ),
//-----------------------------output-------------------------------------//
        .IF_PC                  (IIBus.IF_PC ),
        .IF_ExceptType          (IIBus.IF_ExceptType)
    );

    assign IIBus.IF_Instr = cpu_ibus.rdata;

endmodule