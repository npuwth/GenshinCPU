/*
 * @Author: Johnson Yang
 * @Date: 2021-03-27 17:12:06
 * @LastEditTime: 2021-07-06 16:42:17
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 协处理器CP0（实现了CP0中的 BadVAddr、Count、Compare、Status、Cause、EPC6个寄存器的部分功能）
 * 
 */
 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module cp0_reg (  
    input logic             clk,
    input logic             rst,
    input logic  [5:0]      Interrupt,                 //6个外部硬件中断输入 
    // read port        
    input logic  [4:0]      CP0_RdAddr,                //要读取的CP0寄存器的地址
    output logic [31:0]     CP0_RdData,                //读出的CP0某个寄存器的值 
    //write port from reg
    input RegsWrType        MEM_RegsWrType,
    input logic  [4:0]      MEM_Dst,
    input logic  [31:0]     MEM_Result,
    //write port from tlb
    input                   MEM_IsTLBP,                //写index寄存器
    input logic             MEM_IsTLBR,                //写EntryHi，EntryLo0，EntryLo1
    CP0_MMU_Interface       CMBus, 
    //exception
    input ExceptinPipeType  WB_ExceptType,
    input logic  [31:0]     WB_PC,
    input logic             WB_IsInDelaySlot,
    input logic  [31:0]     WB_ALUOut
    );

    logic                   TimCount2;
    logic                   CP0_TimerInterrupt;         //是否有定时中断发生
    
    cp0_regs CP0;
    
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.
        end
    end



    //read port
    always_comb begin
        case(CP0_RdAddr)
            `CP0_REG_COUNT:      CP0_RdData = CP0_Count;
            `CP0_REG_COMPARE:    CP0_RdData = CP0_Compare;
            `CP0_REG_STATUS:     CP0_RdData = CP0_Status;
            `CP0_REG_CAUSE:      CP0_RdData = CP0_Cause;
            `CP0_REG_EPC:        CP0_RdData = CP0_EPC;
            `CP0_REG_BADVADDR:   CP0_RdData = CP0_BadVAddr;
            `CP0_REG_INDEX:      CP0_RdData = CP0_Index;
            `CP0_REG_ENTRYHI:    CP0_RdData = CP0_EntryHi;
            `CP0_REG_ENTRYLO0:   CP0_RdData = CP0_EntryLo0;
            `CP0_REG_ENTRYLO1:   CP0_RdData = CP0_EntryLo1;
            default:             CP0_RdData = 'x;
        endcase
    end

    //与TLB交互
    assign CMBus.CP0_index      = CP0_Index[3:0];
    assign CMBus.CP0_vpn2       = CP0_EntryHi[31:13];
    assign CMBus.CP0_asid       = CP0_EntryHi[7:0];
    assign CMBus.CP0_pfn0       = CP0_EntryLo0[25:6];
    assign CMBus.CP0_c0         = CP0_EntryLo0[5:3];
    assign CMBus.CP0_d0         = CP0_EntryLo0[2];
    assign CMBus.CP0_v0         = CP0_EntryLo0[1];
    assign CMBus.CP0_g0         = CP0_EntryLo0[0];
    assign CMBus.CP0_pfn1       = CP0_EntryLo1[25:6];
    assign CMBus.CP0_c1         = CP0_EntryLo1[5:3];
    assign CMBus.CP0_d1         = CP0_EntryLo1[2];
    assign CMBus.CP0_v1         = CP0_EntryLo1[1];
    assign CMBus.CP0_g1         = CP0_EntryLo1[0];
endmodule
