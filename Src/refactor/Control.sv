/*
 * @Author:Juan
 * @Date: 2021-06-16 16:11:20
 * @LastEditTime: 2021-07-17 03:22:10
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
`include "CommonDefines.svh"
`include "Cache_options.svh"


module Control(
    // input logic  [2:0]  EX_Entry_Sel,       
    input logic         Flush_Exception,          //异常Exception产生的
    input logic         I_IsTLBStall,             // TLB
    input logic         D_IsTLBStall,  
    input logic         Icache_busy,              // Icache信号 表示Icache是否要暂停流水线 
    input logic         Dcache_busy,              // Dcache信号 表示Dcache是否要暂停流水线 (miss 前store后load 的情况等)
    input logic         DH_Stall,                 //DataHazard产生的
    input logic         ID_IsAImmeJump,           // ID级的J, JAL指令,需要flush一拍
    input logic         BranchFailed,             // 分支预测失败时，需要flush两拍
    input logic         DIVMULTBusy,              // 乘除法状态机空闲  & 注意需要取反后使用
    input logic [31:0]  MEM_Addr,                 // MEM级的访存地址信息
    input logic         MEM_loadstore_req,        // MEM级的requset信息
    input logic [31:0]  MEM2_Addr,                // MEM2级的的地址信息
    input logic         MEM2_store_req,           // MEM2级的store信息
    input logic [31:0]  WB_Addr,                  // WB级的的地址信息            
    input logic         WB_store_req,             // WB级的store信息
//------------------------------------output----------------------------------------------------//
    output logic        PREIF_Wr,
    output logic        IF_Wr,
    output logic        ID_Wr,
    output logic        EXE_Wr,
    output logic        MEM_Wr,
    output logic        MEM2_Wr,
    output logic        WB_Wr,
     
    output logic        IF_Flush,
    output logic        ID_Flush,
    output logic        EXE_Flush,
    output logic        MEM_Flush,
    output logic        MEM2_Flush,
    output logic        WB_Flush,

    output logic        EXE_DisWr,      //传到EXE级，用于关闭HILO写使能
    output logic        MEM_DisWr,      //传到MEM级，用于关闭CP0的写使能
    output logic        WB_DisWr,       //传到WB级 ，用于停滞流水线

    output logic       IcacheFlush,    //给Icache的Flush
    // output logic       DcacheFlush,    //给Dcache的Flush
    output logic       IReq_valid,     //是否给Icache发送请求 1表示发送 0 表示不发送
    output logic       DReq_valid,     //是否给Dcache发送请求 1表示发送 0 表示不发送

    output logic       ICacheStall,    // 如果出现cache数据准备好，但CPU阻塞的清空，
                                    // 需要发送stall信号，cache状态机停滞知道数据被CPU接受
    output logic       DCacheStall
    // output logic       HiLo_Not_Flush
);

    logic Load_store_stall ;
    localparam int unsigned INDEX_WIDTH = $clog2(`ICACHE_LINE_WORD*4) ;
    

    always_comb begin
        if (MEM_loadstore_req == 1'b1 && MEM2_store_req == 1'b1 && MEM_Addr[31:INDEX_WIDTH] == MEM2_Addr[31:INDEX_WIDTH]) begin
            Load_store_stall = 1'b1;
        end
        else if (MEM_loadstore_req == 1'b1 && WB_store_req == 1'b1 && MEM_Addr[31:INDEX_WIDTH] == WB_Addr[31:INDEX_WIDTH] ) begin
            Load_store_stall = 1'b1;
        end
        else begin
            Load_store_stall = 1'b0;
        end
    end


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
            // DCacheFlush  = 1'b1;

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
            // DCacheFlush  = 1'b0;

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
            // DCacheFlush  = 1'b0;

            IReq_valid   = 1'b1;
            DReq_valid   = 1'b0;

            ICacheStall  = 1'b1;
            DCacheStall  = 1'b1;
        end
        else if (Load_store_stall) begin
            PREIF_Wr     = 1'b0;
            IF_Wr        = 1'b0;
            ID_Wr        = 1'b0;
            EXE_Wr       = 1'b0;
            MEM_Wr       = 1'b0; 
            MEM2_Wr      = 1'b0;
            WB_Wr        = 1'b1;
            
            EXE_DisWr    = 1'b0;
            MEM_DisWr    = 1'b0;
            WB_DisWr     = 1'b0; 
                       
            IF_Flush     = 1'b0;
            ID_Flush     = 1'b0;
            EXE_Flush    = 1'b0;
            MEM_Flush    = 1'b0;
            MEM2_Flush   = 1'b1;
            WB_Flush     = 1'b0;

            IcacheFlush  = 1'b0;
            // DCacheFlush  = 1'b0;

            IReq_valid   = 1'b0;  // 此时Icache  Dcache都不能发起请求
            DReq_valid   = 1'b0;

            ICacheStall  = 1'b1;
            DCacheStall  = 1'b0;
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
            // DCacheFlush  = 1'b0;

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
            // DCacheFlush  = 1'b0;

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
            // DCacheFlush  = 1'b0;

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
            // DCacheFlush  = 1'b0;

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
            // DCacheFlush  = 1'b0;

            IReq_valid   = 1'b1;
            DReq_valid   = 1'b1;

            ICacheStall  = 1'b0;
            DCacheStall  = 1'b0;
        end
    end


    // // HILO的flush
    // always_comb begin
    //     HiLo_Not_Flush =  (EX_Entry_Sel == `IsNone) ? 1'b1:1'b0;
    // end
    
    
endmodule