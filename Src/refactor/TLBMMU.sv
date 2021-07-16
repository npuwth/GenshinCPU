/*
 * @Author: npuwth
 * @Date: 2021-06-30 22:17:38
 * @LastEditTime: 2021-07-16 20:01:32
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 
`include "CommonDefines.svh"
`include "CPU_Defines.svh"

`define  IDLE           1'b0
`define  SEARCH         1'b1

module TLBMMU (
    input logic                  clk,
    input logic                  rst,
    input logic  [31:0]          Virt_Iaddr,                        //也就是PC
    input logic  [31:0]          Virt_Daddr,                        //也就是MEM_ALUOut
    input LoadType               MEM_LoadType,
    input StoreType              MEM_StoreType,
    input logic                  MEM_IsTLBP,                        //表示是否是TLBP指令
    input logic                  MEM_IsTLBW,                        //表示是否是TLBW指令
    input logic                  MEM_TLBWIorR,                      //TLBWI是0，TLBWR是1
    input logic                  TLBBuffer_Flush,                   //TLBW等修改TLB的指令时对TLB Buffer进行清空
    CP0_TLB_Interface            CTBus,
    output logic [31:0]          Phsy_Iaddr,
    output logic [31:0]          Phsy_Daddr,
    output logic                 I_IsCached,
    output logic                 D_IsCached,
    output logic                 I_IsTLBBufferValid,                //告诉Cache是否发起访存请求
    output logic                 D_IsTLBBufferValid,                //告诉Cache是否发起访存请求
    output logic                 I_IsTLBStall,                      //是否要停滞流水线
    output logic                 D_IsTLBStall,                      //是否要停滞流水线
    output logic [1:0]           IF_TLBExceptType,
    output logic [2:0]           MEM_TLBExceptType
);
//------------------------------------------------------------------------------------------------------//
    logic [3:0]                  s0_index;
    logic [18:0]                 s1_vpn2;                           //访存和指令TLBP复用
    logic                        s1_found;
    logic [3:0]                  s1_index;
    logic [3:0]                  w_index;                           //在Index和Random中进行选择

    TLB_Entry                    R_TLBEntry;                        //read port的TLB页表项
    TLB_Entry                    W_TLBEntry;                        //write port的TLB页表项

//---------------------------------tlb模块例化-------------------------------------------------------------//
    tlb U_TLB ( 
        .clk                     (clk ),
        .rst                     (rst ),
        //search port 0
        .s0_vpn2                 (Virt_Iaddr[31:13] ),
        .s0_asid                 (CMBus.CP0_asid ),
        .s0_found                (s0_found ),         //output        
        .s0_index                (s0_index ),         //output
        .I_TLBEntry              (I_TLBEntry ),       //output
        //search port 1
        .s1_vpn2                 (s1_vpn2 ),
        .s1_asid                 (CMBus.CP0_asid ),
        .s1_found                (s1_found ),         //output
        .s1_index                (s1_index ),         //output
        .D_TLBEntry              (D_TLBEntry ),       //output
        //write port
        .we                      (MEM_IsTLBW ),       //写使能
        .w_index                 (w_index ),          //写索引
        .W_TLBEntry              (W_TLBEntry ),       //写数据
        //read port
        .r_index                 (CMBus.CP0_index ),  //读索引
        .R_TLBEntry              (R_TLBEntry )        //读数据
    );
//-------------------------与CP0交互的部分-----------------------------------//
    assign W_TLBEntry         = {CMBus.CP0_vpn2,
                                CMBus.CP0_asid,
                                CMBus.CP0_g0 & CMBus.CP0_g1,         //写入的g是g0和g1的与
                                CMBus.CP0_pfn0,
                                CMBus.CP0_c0,
                                CMBus.CP0_d0,
                                CMBus.CP0_v0,
                                CMBus.CP0_pfn1,
                                CMBus.CP0_c1,
                                CMBus.CP0_d1,
                                CMBus.CP0_v1};
    //--------------------用于TLBR指令---------------------------------//
    assign CMBus.MMU_vpn2     = R_TLBEntry.VPN2;
    assign CMBus.MMU_asid     = R_TLBEntry.ASID;
    assign CMBus.MMU_pfn0     = R_TLBEntry.PFN0;
    assign CMBus.MMU_c0       = R_TLBEntry.C0;  
    assign CMBus.MMU_d0       = R_TLBEntry.D0;  
    assign CMBus.MMU_v0       = R_TLBEntry.V0;  
    assign CMBus.MMU_g0       = R_TLBEntry.G;   
    assign CMBus.MMU_pfn1     = R_TLBEntry.PFN1;
    assign CMBus.MMU_c1       = R_TLBEntry.C1;
    assign CMBus.MMU_d1       = R_TLBEntry.D1;
    assign CMBus.MMU_v1       = R_TLBEntry.V1;
    assign CMBus.MMU_g1       = R_TLBEntry.G;   
    //-------------------用于TLBP指令---------------------------------//
    assign CMBus.MMU_s1found  = s1_found;
    assign CMBus.MMU_index    = s1_index; 
//---------------------------------------------------------------------------------------//

//-------------------------------复用访存的port实现TLBP-----------------------------------------//
    MUX2to1#(19) U_MUX_s1vpn (
        .d0                   (Virt_Daddr[31:13]),
        .d1                   (CMBus.CP0_vpn2),
        .sel2_to_1            (MEM_IsTLBP),//
        .y                    (s1_vpn2)
    );
//--------------------------------TLBWI与TLBWR的选择-----------------------------------------------//
    MUX2to1#(4) U_MUX_windex ( 
        .d0                   (CMBus.CP0_index),
        .d1                   (CMBus.CP0_random),
        .sel2_to_1            (MEM_TLBWIorR),
        .y                    (w_index)
    );

//--------------------------------------------------------------------------------------//
endmodule