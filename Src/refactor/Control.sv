/*
 * @Author:Juan
 * @Date: 2021-06-16 16:11:20
 * @LastEditTime: 2021-07-13 21:30:49
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
`include "CommonDefines.svh"
module Control(
    input logic       Flush_Exception,          //异常Exception产生的
    input logic       I_IsTLBStall,             // TLB
    input logic       D_IsTLBStall,  
    input logic       Icache_busy,              // Icache信号 表示Icache是否要暂停流水线 
    input logic       Dcache_busy,              // Dcache信号 表示Dcache是否要暂停流水线 (miss 前store后load 的情况等)
    input logic       DH_Stall,                 //DataHazard产生的
    input logic       ID_IsAImmeJump,           // ID级的J, JAL指令,需要flush一拍
    input logic       BranchFailed,             // 分支预测失败时，需要flush两拍
    input logic       DIVMULTBusy,              // 乘除法状态机空闲  & 注意需要取反后使用
//------------------------------------output----------------------------------------------------//
    output logic      PREIF_Wr,
    output logic      IF_Wr,
    output logic      ID_Wr,
    output logic      EXE_Wr,
    output logic      MEM_Wr,
    output logic      MEM2_Wr,
    output logic      WB_Wr,
     
    output logic      IF_Flush,
    output logic      ID_Flush,
    output logic      EXE_Flush,
    output logic      MEM_Flush,
    output logic      MEM2_Flush,
    output logic      WB_Flush,

    output logic      EXE_DisWr,      //传到EXE级，用于关闭HILO写使能
    output logic      MEM_DisWr,      //传到MEM级，用于关闭CP0的写使能
    output logic      WB_DisWr,       //传到WB级 ，用于停滞流水线

    output logic      IcacheFlush,    //给Icache的Flush
    output logic      DcacheFlush,    //给Dcache的Flush
    output logic      IReq_valid,     //是否给Icache发送请求 1表示发送 0 表示不发送
    output logic      DReq_valid,     //是否给Dcache发送请求 1表示发送 0 表示不发送

    output logic      ICacheStall,    // 如果出现cache数据准备好，但CPU阻塞的清空，
                                      // 需要发送stall信号，cache状态机停滞知道数据被CPU接受
    output logic      DCacheStall
);

    always_comb begin
        if (Flush_Exception == `FlushEnable)begin
            PREIF_Wr      = 1'b1;
            IF_Wr        = 1'bx;
            ID_Wr        = 1'bx;
            EXE_Wr       = 1'bx;
            MEM_Wr       = 1'bx; 
            MEM2_Wr      = 1'b1;
            WB_Wr        = 1'b1;
            
            IF_Flush     = 1'b1;
            ID_Flush     = 1'b1;
            EXE_Flush    = 1'b1;
            MEM_Flush    = 1'b1;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            EXE_DisWr    = 1'b1;
            MEM_DisWr    = 1'b1;
            WB_DisWr     = 1'b0;
            
            IcacheFlush  = 1'b1;
            DcacheFlush  = 1'b1;

            IReq_valid   = 1'b0;
            DReq_valid   = 1'b0;

            ICacheStall  = 1'b0;
            DCacheStall  = 1'b0;

        end
        else if (I_IsTLBStall == 1'b1  || Icache_busy == 1'b1 ) begin
            PREIF_Wr      = 1'b0;
            IF_Wr        = 1'b0;
            ID_Wr        = 1'b0;
            EXE_Wr       = 1'b0;
            MEM_Wr       = 1'b0; 
            MEM2_Wr      = 1'b0;
            WB_Wr        = 1'b0;
            
            EXE_DisWr    = 1'b1;
            MEM_DisWr    = 1'b1;
            WB_DisWr     = 1'b1; 
                       
            IF_Flush     = 1'b0;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b0;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b0;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b1;
            DCacheStall  = 1'b1;
        end
        else if (D_IsTLBStall == 1'b1  || Dcache_busy == 1'b1 ) begin
            PREIF_Wr      = 1'b0;
            IF_Wr        = 1'b0;
            ID_Wr        = 1'b0;
            EXE_Wr       = 1'b0;
            MEM_Wr       = 1'b0; 
            MEM2_Wr      = 1'b0;
            WB_Wr        = 1'b0;
            
            EXE_DisWr    = 1'b1;
            MEM_DisWr    = 1'b1;
            WB_DisWr     = 1'b1; 
                       
            IF_Flush     = 1'b0;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b0;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b1;
            DReq_valid   = 1'b0;

            ICacheStall  = 1'b1;
            DCacheStall  = 1'b1;
        end
        else if (DH_Stall == 1'b1) begin
            PREIF_Wr      = 1'b0;
            IF_Wr        = 1'b0;
            ID_Wr        = 1'b0;
            EXE_Wr       = 1'bx;
            MEM_Wr       = 1'b1; 
            MEM2_Wr      = 1'b1;
            WB_Wr        = 1'b1;
            
            EXE_DisWr    = 1'b0;
            MEM_DisWr    = 1'b0;
            WB_DisWr     = 1'b0; 
                       
            IF_Flush     = 1'b0;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b1;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b0;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b1;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b1;
            DCacheStall  = 1'b0;
        end
        else if (ID_IsAImmeJump == 1'b1) begin
            PREIF_Wr      = 1'b1;
            IF_Wr        = 1'bx;
            ID_Wr        = 1'b1;
            EXE_Wr       = 1'b1;
            MEM_Wr       = 1'b1; 
            MEM2_Wr      = 1'b1;
            WB_Wr        = 1'b1;
            
            EXE_DisWr    = 1'b0;
            MEM_DisWr    = 1'b0;
            WB_DisWr     = 1'b0; 
                       
            IF_Flush     = 1'b1;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b1;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b0;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b0;
            DCacheStall  = 1'b0;
        end
        else if (BranchFailed == 1'b1) begin
            PREIF_Wr      = 1'b1;
            IF_Wr        = 1'bx;
            ID_Wr        = 1'bx;
            EXE_Wr       = 1'b1;
            MEM_Wr       = 1'b1; 
            MEM2_Wr      = 1'b1;
            WB_Wr        = 1'b1;
            
            EXE_DisWr    = 1'b0;
            MEM_DisWr    = 1'b0;
            WB_DisWr     = 1'b0; 
                       
            IF_Flush     = 1'b1;
            ID_Flush     = 1'b1;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b1;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b0;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b0;
            DCacheStall  = 1'b0;
        end
        else if (DIVMULTBusy == 1'b1) begin
            PREIF_Wr      = 1'b0;
            IF_Wr        = 1'b0;
            ID_Wr        = 1'b0;
            EXE_Wr       = 1'b0;
            MEM_Wr       = 1'b0; 
            MEM2_Wr      = 1'b0;
            WB_Wr        = 1'b0;
            
            EXE_DisWr    = 1'b1;
            MEM_DisWr    = 1'b1;
            WB_DisWr     = 1'b1; 
                       
            IF_Flush     = 1'b0;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b0;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b1;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b1;
            DCacheStall  = 1'b1;
        end
        else begin
            PREIF_Wr      = 1'b1;
            IF_Wr        = 1'b1;
            ID_Wr        = 1'b1;
            EXE_Wr       = 1'b1;
            MEM_Wr       = 1'b1; 
            MEM2_Wr      = 1'b1;
            WB_Wr        = 1'b1;
            
            EXE_DisWr    = 1'b0;
            MEM_DisWr    = 1'b0;
            WB_DisWr     = 1'b0; 
                       
            IF_Flush     = 1'b0;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b0;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b0;
            DcacheFlush  = 1'b0;

            IReq_valid   = 1'b1;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b0;
            DCacheStall  = 1'b0;
        end
    end



    
    
endmodule