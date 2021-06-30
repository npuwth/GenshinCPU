/*
 * @Author: npuwth
 * @Date: 2021-06-30 22:17:38
 * @LastEditTime: 2021-06-30 23:13:37
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module TLBMMU (
    input logic                  clk,
    input logic [31:0]           Virt_Iaddr,
    input logic [31:0]           Virt_Daddr,
    input logic                  EXE_IsTLBP,//表示是否是TLBP指令
    CP0_MMU_Interface            CMBus,
    output logic [31:0]          Phsy_Iaddr,
    output logic [31:0]          Phsy_Daddr
);
    logic                        s0_found;
    logic [3:0]                  s0_index;
    logic [2:0]                  s0_c;
    logic                        s0_d;
    logic                        s0_v;     

    logic [18:0]                 s1_vpn2;
    logic                        s1_odd_page;      
    logic                        s1_found;
    logic [3:0]                  s1_index;
    logic [2:0]                  s1_c;
    logic                        s1_d;
    logic                        s1_v; 

    tlb U_TLB ( 
        .clk                     (clk ),
        //search port 0
        .s0_vpn2                 (Virt_Iaddr[31:13] ),
        .s0_odd_page             (Virt_Iaddr[12] ),
        .s0_asid                 (CMBus.CP0_asid ),
        .s0_found                (s0_found ),
        .s0_index                (s0_index ),
        .s0_pfn                  (s0_pfn ),
        .s0_c                    (s0_c ),
        .s0_d                    (s0_d ),
        .s0_v                    (s0_v ),
        //search port 1
        .s1_vpn2                 (s1_vpn2 ),
        .s1_odd_page             (Virt_Daddr[12] ),
        .s1_asid                 (CMBus.CP0_asid ),
        .s1_found                (s1_found ),
        .s1_index                (s1_index ),
        .s1_pfn                  (s1_pfn ),
        .s1_c                    (s1_c ),
        .s1_d                    (s1_d ),
        .s1_v                    (s1_v ),
        //write port
        .we                      (we ),
        .w_index                 (w_index ),
        .w_vpn2                  (w_vpn2 ),
        .w_asid                  (w_asid ),
        .w_g                     (w_g ),
        .w_pfn0                  (w_pfn0 ),
        .w_c0                    (w_c0 ),
        .w_d0                    (w_d0 ),
        .w_v0                    (w_v0 ),
        .w_pfn1                  (w_pfn1 ),
        .w_c1                    (w_c1 ),
        .w_d1                    (w_d1 ),
        .w_v1                    (w_v1 ),
        //read port
        .r_index                 (r_index ),
        .r_vpn2                  (r_vpn2 ),
        .r_asid                  (r_asid ),
        .r_g                     (r_g ),
        .r_pfn0                  (r_pfn0 ),
        .r_c0                    (r_c0 ),
        .r_d0                    (r_d0 ),
        .r_v0                    (r_v0 ),
        .r_pfn1                  (r_pfn1 ),
        .r_c1                    (r_c1 ),
        .r_d1                    (r_d1 ),
        .r_v1                    ( r_v1)
    );

    always_comb begin
        if(Virt_Iaddr < 32'hC000_0000 && Virt_Iaddr > 32'h9FFF_FFFF) begin
            Phsy_Iaddr        = Virt_Iaddr - 32'hA000_0000; 
        end
        else if(Virt_Iaddr < 32'hA000_0000 && Virt_Iaddr > 32'h7FFF_FFFF) begin
            Phsy_Iaddr        = Virt_Iaddr - 32'h8000_0000;
        end
        else begin
            Phsy_Iaddr        = {s0_pfn,Virt_Iaddr[11:0]};
        end
    end

    always_comb begin
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'hA000_0000;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'h8000_0000;
        end
        else begin
            Phsy_Daddr        = {s1_pfn,Virt_Daddr[11:0]};
        end
    end

    MUX2to1#(19) U_MUX_s1vpn (
        .d0                   (Virt_Daddr[31:13]),
        .d1                   (CMBus.CP0_vpn2),
        .sel2_to_1            (EXE_IsTLBP),//
        .y                    (s1_vpn2)
    );//EXE级四选一B之后的那个二选一




endmodule