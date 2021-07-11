/*
 * @Author: npuwth
 * @Date: 2021-06-27 20:08:23
 * @LastEditTime: 2021-07-11 20:08:49
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module tlb 
#(
    parameter TLBNUM = 16
)
(
    input  logic                       clk,
    input  logic                       rst,
    //search port0
    input  logic  [18:0]               s0_vpn2,
    input  logic  [7:0]                s0_asid,
    output logic                       s0_found,
    output logic  [$clog2(TLBNUM)-1:0] s0_index,
    output TLB_Entry                   I_TLBEntry,
    //search port1
    input  logic  [18:0]               s1_vpn2,
    input  logic  [7:0]                s1_asid,
    output logic                       s1_found,
    output logic  [$clog2(TLBNUM)-1:0] s1_index,
    output TLB_Entry                   D_TLBEntry,
    //write port
    input  logic                       we,             //写使能
    input  logic  [$clog2(TLBNUM)-1:0] w_index,
    input  TLB_Entry                   W_TLBEntry,
    //read port
    input logic   [$clog2(TLBNUM)-1:0] r_index,
    output TLB_Entry                   R_TLBEntry
);
    
    logic [18:0]  tlb_vpn2             [TLBNUM-1:0];
    logic [7:0]   tlb_asid             [TLBNUM-1:0];
    logic         tlb_g                [TLBNUM-1:0];
    logic [19:0]  tlb_pfn0             [TLBNUM-1:0];
    logic [2:0]   tlb_c0               [TLBNUM-1:0];
    logic         tlb_d0               [TLBNUM-1:0];
    logic         tlb_v0               [TLBNUM-1:0];
    logic [19:0]  tlb_pfn1             [TLBNUM-1:0];
    logic [2:0]   tlb_c1               [TLBNUM-1:0];
    logic         tlb_d1               [TLBNUM-1:0];
    logic         tlb_v1               [TLBNUM-1:0];
    logic [TLBNUM-1:0]                 match0;
    logic [TLBNUM-1:0]                 match1;

//----------------------------------write port-------------------------------------------//
    genvar i;
    generate
    	for(i = 0; i < TLBNUM; ++i)
    	begin: gen_for_tlb
    		always_ff @(posedge clk) begin
    			if(rst == `RstEnable) begin
    				tlb_vpn2[i] <= '0;
                    tlb_asid[i] <= '0;
                    tlb_g[i]    <= '0; 
                    tlb_pfn0[i] <= '0;
                    tlb_c0[i]   <= '0;
                    tlb_d0[i]   <= '0;
                    tlb_v0[i]   <= '0;
                    tlb_pfn1[i] <= '0;
                    tlb_c1[i]   <= '0;
                    tlb_d1[i]   <= '0;
                    tlb_v1[i]   <= '0;
    			end else begin
    				if( we && i == w_index) begin
    					tlb_vpn2[i] <= W_TLBEntry.VPN2;
                        tlb_asid[i] <= W_TLBEntry.ASID;
                        tlb_g[i]    <= W_TLBEntry.G;
                        tlb_pfn0[i] <= W_TLBEntry.PFN0;
                        tlb_c0[i]   <= W_TLBEntry.C0;
                        tlb_d0[i]   <= W_TLBEntry.D0;
                        tlb_v0[i]   <= W_TLBEntry.V0;
                        tlb_pfn1[i] <= W_TLBEntry.PFN1;
                        tlb_c1[i]   <= W_TLBEntry.C1;
                        tlb_d1[i]   <= W_TLBEntry.D1;
                        tlb_v1[i]   <= W_TLBEntry.V1;
                    end
    			end
    		end
    	end
    endgenerate
//---------------------------------read port-------------------------------------------------------//
    always_comb begin
        R_TLBEntry.VPN2 = tlb_vpn2[r_index];
        R_TLBEntry.ASID = tlb_asid[r_index];
        R_TLBEntry.G    = tlb_g[r_index];
        R_TLBEntry.PFN0 = tlb_pfn0[r_index];
        R_TLBEntry.C0   = tlb_c0[r_index];
        R_TLBEntry.D0   = tlb_d0[r_index];
        R_TLBEntry.V0   = tlb_v0[r_index];
        R_TLBEntry.PFN1 = tlb_pfn1[r_index];
        R_TLBEntry.C1   = tlb_c1[r_index];
        R_TLBEntry.D1   = tlb_d1[r_index];
        R_TLBEntry.V1   = tlb_v1[r_index];    
    end
//----------------------------------search port1-------------------------------------------------------//
    assign match0[ 0] = (s0_vpn2 == tlb_vpn2[ 0]) && ((s0_asid == tlb_asid[ 0]) || tlb_g[ 0]);
    assign match0[ 1] = (s0_vpn2 == tlb_vpn2[ 1]) && ((s0_asid == tlb_asid[ 1]) || tlb_g[ 1]);
    assign match0[ 2] = (s0_vpn2 == tlb_vpn2[ 2]) && ((s0_asid == tlb_asid[ 2]) || tlb_g[ 2]);
    assign match0[ 3] = (s0_vpn2 == tlb_vpn2[ 3]) && ((s0_asid == tlb_asid[ 3]) || tlb_g[ 3]);
    assign match0[ 4] = (s0_vpn2 == tlb_vpn2[ 4]) && ((s0_asid == tlb_asid[ 4]) || tlb_g[ 4]);
    assign match0[ 5] = (s0_vpn2 == tlb_vpn2[ 5]) && ((s0_asid == tlb_asid[ 5]) || tlb_g[ 5]);
    assign match0[ 6] = (s0_vpn2 == tlb_vpn2[ 6]) && ((s0_asid == tlb_asid[ 6]) || tlb_g[ 6]);
    assign match0[ 7] = (s0_vpn2 == tlb_vpn2[ 7]) && ((s0_asid == tlb_asid[ 7]) || tlb_g[ 7]);
    assign match0[ 8] = (s0_vpn2 == tlb_vpn2[ 8]) && ((s0_asid == tlb_asid[ 8]) || tlb_g[ 8]);
    assign match0[ 9] = (s0_vpn2 == tlb_vpn2[ 9]) && ((s0_asid == tlb_asid[ 9]) || tlb_g[ 9]);
    assign match0[10] = (s0_vpn2 == tlb_vpn2[10]) && ((s0_asid == tlb_asid[10]) || tlb_g[10]);
    assign match0[11] = (s0_vpn2 == tlb_vpn2[11]) && ((s0_asid == tlb_asid[11]) || tlb_g[11]);
    assign match0[12] = (s0_vpn2 == tlb_vpn2[12]) && ((s0_asid == tlb_asid[12]) || tlb_g[12]);
    assign match0[13] = (s0_vpn2 == tlb_vpn2[13]) && ((s0_asid == tlb_asid[13]) || tlb_g[13]);
    assign match0[14] = (s0_vpn2 == tlb_vpn2[14]) && ((s0_asid == tlb_asid[14]) || tlb_g[14]);
    assign match0[15] = (s0_vpn2 == tlb_vpn2[15]) && ((s0_asid == tlb_asid[15]) || tlb_g[15]);
    //--------------------s0_found生成逻辑，port0是否hit--------------------------------------------------// 
    always_comb begin          
        if(match0 == 0)
            s0_found = 0;
        else
            s0_found = 1; 
    end
    //--------------------s0查询结果数据生成逻辑-----------------------------------------------------------//
    assign I_TLBEntry.VPN2         = tlb_vpn2 [s0_index];
    assign I_TLBEntry.ASID         = tlb_asid [s0_index];
    assign I_TLBEntry.G            = tlb_g    [s0_index];
    assign I_TLBEntry.PFN0         = tlb_pfn0 [s0_index];
    assign I_TLBEntry.C0           = tlb_c0   [s0_index];
    assign I_TLBEntry.D0           = tlb_d0   [s0_index];    
    assign I_TLBEntry.V0           = tlb_v0   [s0_index];
    assign I_TLBEntry.PFN1         = tlb_pfn1 [s0_index];
    assign I_TLBEntry.C1           = tlb_c1   [s0_index];
    assign I_TLBEntry.D1           = tlb_d1   [s0_index];
    assign I_TLBEntry.V1           = tlb_v1   [s0_index];
    //-----------------------s0_index生成逻辑------------------------------------------------------------//
    always_comb begin          
        unique case(match0)
            16'b0000_0000_0000_0001:s0_index = 0;
            16'b0000_0000_0000_0010:s0_index = 1;
            16'b0000_0000_0000_0100:s0_index = 2;
            16'b0000_0000_0000_1000:s0_index = 3;
            16'b0000_0000_0001_0000:s0_index = 4;
            16'b0000_0000_0010_0000:s0_index = 5;
            16'b0000_0000_0100_0000:s0_index = 6;
            16'b0000_0000_1000_0000:s0_index = 7;
            16'b0000_0001_0000_0000:s0_index = 8;
            16'b0000_0010_0000_0000:s0_index = 9;
            16'b0000_0100_0000_0000:s0_index = 10;
            16'b0000_1000_0000_0000:s0_index = 11;
            16'b0001_0000_0000_0000:s0_index = 12;
            16'b0010_0000_0000_0000:s0_index = 13;
            16'b0100_0000_0000_0000:s0_index = 14;
            16'b1000_0000_0000_0000:s0_index = 15;
            default:s0_index = 'x;
        endcase
    end

//-----------------------------------search port2------------------------------------------------------//
    assign match1[ 0] = (s1_vpn2 == tlb_vpn2[ 0]) && ((s1_asid == tlb_asid[ 0]) || tlb_g[ 0]);
    assign match1[ 1] = (s1_vpn2 == tlb_vpn2[ 1]) && ((s1_asid == tlb_asid[ 1]) || tlb_g[ 1]);
    assign match1[ 2] = (s1_vpn2 == tlb_vpn2[ 2]) && ((s1_asid == tlb_asid[ 2]) || tlb_g[ 2]);
    assign match1[ 3] = (s1_vpn2 == tlb_vpn2[ 3]) && ((s1_asid == tlb_asid[ 3]) || tlb_g[ 3]);
    assign match1[ 4] = (s1_vpn2 == tlb_vpn2[ 4]) && ((s1_asid == tlb_asid[ 4]) || tlb_g[ 4]);
    assign match1[ 5] = (s1_vpn2 == tlb_vpn2[ 5]) && ((s1_asid == tlb_asid[ 5]) || tlb_g[ 5]);
    assign match1[ 6] = (s1_vpn2 == tlb_vpn2[ 6]) && ((s1_asid == tlb_asid[ 6]) || tlb_g[ 6]);
    assign match1[ 7] = (s1_vpn2 == tlb_vpn2[ 7]) && ((s1_asid == tlb_asid[ 7]) || tlb_g[ 7]);
    assign match1[ 8] = (s1_vpn2 == tlb_vpn2[ 8]) && ((s1_asid == tlb_asid[ 8]) || tlb_g[ 8]);
    assign match1[ 9] = (s1_vpn2 == tlb_vpn2[ 9]) && ((s1_asid == tlb_asid[ 9]) || tlb_g[ 9]);
    assign match1[10] = (s1_vpn2 == tlb_vpn2[10]) && ((s1_asid == tlb_asid[10]) || tlb_g[10]);
    assign match1[11] = (s1_vpn2 == tlb_vpn2[11]) && ((s1_asid == tlb_asid[11]) || tlb_g[11]);
    assign match1[12] = (s1_vpn2 == tlb_vpn2[12]) && ((s1_asid == tlb_asid[12]) || tlb_g[12]);
    assign match1[13] = (s1_vpn2 == tlb_vpn2[13]) && ((s1_asid == tlb_asid[13]) || tlb_g[13]);
    assign match1[14] = (s1_vpn2 == tlb_vpn2[14]) && ((s1_asid == tlb_asid[14]) || tlb_g[14]);
    assign match1[15] = (s1_vpn2 == tlb_vpn2[15]) && ((s1_asid == tlb_asid[15]) || tlb_g[15]);     
    //--------------------s1_found生成逻辑，port1是否hit--------------------------------------------------//    
    always_comb begin           
        if(match1 == 0)
            s1_found = 0;
        else
            s1_found = 1; 
    end
    //--------------------s1查询结果数据生成逻辑-----------------------------------------------------------//
    assign D_TLBEntry.VPN2         = tlb_vpn2 [s1_index];
    assign D_TLBEntry.ASID         = tlb_asid [s1_index];
    assign D_TLBEntry.G            = tlb_g    [s1_index];
    assign D_TLBEntry.PFN0         = tlb_pfn0 [s1_index];
    assign D_TLBEntry.C0           = tlb_c0   [s1_index];
    assign D_TLBEntry.D0           = tlb_d0   [s1_index];    
    assign D_TLBEntry.V0           = tlb_v0   [s1_index];
    assign D_TLBEntry.PFN1         = tlb_pfn1 [s1_index];
    assign D_TLBEntry.C1           = tlb_c1   [s1_index];
    assign D_TLBEntry.D1           = tlb_d1   [s1_index];
    assign D_TLBEntry.V1           = tlb_v1   [s1_index];
    //------------------------s1_index生成逻辑-----------------------------------------------------------//
    always_comb begin          
        unique case(match1)
            16'b0000_0000_0000_0001:s1_index = 0;
            16'b0000_0000_0000_0010:s1_index = 1;
            16'b0000_0000_0000_0100:s1_index = 2;
            16'b0000_0000_0000_1000:s1_index = 3;
            16'b0000_0000_0001_0000:s1_index = 4;
            16'b0000_0000_0010_0000:s1_index = 5;
            16'b0000_0000_0100_0000:s1_index = 6;
            16'b0000_0000_1000_0000:s1_index = 7;
            16'b0000_0001_0000_0000:s1_index = 8;
            16'b0000_0010_0000_0000:s1_index = 9;
            16'b0000_0100_0000_0000:s1_index = 10;
            16'b0000_1000_0000_0000:s1_index = 11;
            16'b0001_0000_0000_0000:s1_index = 12;
            16'b0010_0000_0000_0000:s1_index = 13;
            16'b0100_0000_0000_0000:s1_index = 14;
            16'b1000_0000_0000_0000:s1_index = 15;
            default:s1_index = 'x;
        endcase
    end
//----------------------------------------------------------------------------------------------------------//
endmodule
