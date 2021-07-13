/*
 * @Author:Juan
 * @Date: 2021-06-16 16:11:20
 * @LastEditTime: 2021-07-13 17:44:21
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
`include "CommonDefines.svh"
module WrFlushControl(
    input logic       Flush_Exception,          //异常产生的flush 
    input logic       DH_PreIFWr,               // Load & R型的数据冒险   1代表没有出现该异常，流水线可以流动
    input logic       DH_IFWr,                  // Load & R型的数据冒险 
    input logic       DH_IDWr,                  // Load & R型的数据冒险 
    input logic       EXE_Flush_DataHazard,     // 数据冒险产生的flush  
    input logic       DIVMULTBusy,              // 乘除法状态机空闲  & 注意需要取反后使用
    input logic       BranchFailed,             // 分支预测失败时，需要flush两拍
    input logic       ID_IsAImmeJump,           // ID级的J, JAL指令,需要flush两拍
    input logic       Icache_busy,              // Icache信号 表示Icache是否要暂停流水线 
    input logic       Dcache_busy,              // Dcache信号 表示Dcache是否要暂停流水线 (miss 前store后load 的情况等)
    input logic       I_IsTLBStall,             // TLB
    input logic       D_IsTLBStall,  
//------------------------------------output----------------------------------------------------//
    output logic      PreIFWr,
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

    output logic      EXE_DisWr,
    output logic      MEM_DisWr,      //传到MEM级关闭CP0的写使能
    output logic      WB_DisWr,       // 用于停滞流水线

    output logic      IcacheFlush,    //给Icache的Flush
    output logic      DcacheFlush     //给Dcache的Flush
);

    always_comb begin
        if (Flush_Exception == `FlushEnable ) begin
            IcacheFlush = 1'b1;
        end
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            IcacheFlush = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED ) begin  // 分支跳转失败，J JAL指令 JALR指令需要给出Icache flush
            IcacheFlush = 1'b1;                                              // 在ID级给出的原因：防止I$ busy，收不进去数据           
        end else begin
            IcacheFlush = 1'b0;
        end
    end
    // Dcache Flush
    always_comb begin
        if (Flush_Exception == `FlushEnable ) begin
            DcacheFlush = 1'b1;
        end
        else begin
            DcacheFlush = 1'b0;
        end
    end
    // PreIFWr
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            PreIFWr   = 1'b1;
        end 
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY || I_IsTLBStall == 1'b1) begin
            PreIFWr   = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED ) begin // 在D$空闲的情况下，考虑分支跳转失败，J JAL指令 JALR指令需要给出PC写使能
            PreIFWr   = 1'b1;
        end
        else begin
            if (DH_PreIFWr == 1'b0 || DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                PreIFWr = 1'b0;
            end
            else begin
                PreIFWr = 1'b1;
            end
        end
    end
    //IF_Wr
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            IF_Wr   = 1'bx;
        end
        else if (Dcache_busy == `CACHEBUSY|| Icache_busy == `CACHEBUSY || I_IsTLBStall == 1'b1) begin
            IF_Wr   = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED ) begin // 分支跳转失败, JALR指令需要给出 IF/ID Flush（因此IF/ID写使能不重要）
            IF_Wr   = 1'b1;
        end
        else if (Icache_busy == `CACHEBUSY && ID_IsAImmeJump == 1'b1) begin  // J JAL指令(在ID级跳转的指令) 需要给出IF/IDWR
            IF_Wr   = 1'b0;
        end
        else begin
             if (DH_IFWr == 1'b0 || DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                IF_Wr = 1'b0;
            end
            else begin
                IF_Wr = 1'b1;
            end
        end
    end
    // ID_Wr
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            ID_Wr   = 1'bx;
        end
        else if (Dcache_busy == `CACHEBUSY|| Icache_busy == `CACHEBUSY || I_IsTLBStall == 1'b1) begin
            ID_Wr   = 1'b0;
        end
        else if (BranchFailed == `BRANCKFAILED ) begin // 分支跳转失败, JALR指令需要给出 IF/ID Flush（因此IF/ID写使能不重要）
            ID_Wr   = 1'b1;
        end
        else if (Icache_busy == `CACHEBUSY && ID_IsAImmeJump == 1'b1) begin  // J JAL指令(在ID级跳转的指令) 需要给出IF/IDWR
            ID_Wr   = 1'b0;
        end
        else begin
             if (DH_IDWr == 1'b0 || DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                ID_Wr = 1'b0;
            end
            else begin
                ID_Wr = 1'b1;
            end
        end
    end
    // EXE_Wr
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            EXE_Wr   = 1'bx;
        end 
        else if (Dcache_busy == `CACHEBUSY|| Icache_busy == `CACHEBUSY) begin  //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            EXE_Wr   = 1'b0;
        end
        else begin
             if (DIVMULTBusy == 1'b1) begin  // 数据冒险 & 乘除法
                EXE_Wr = 1'b0;
            end
            else begin
                EXE_Wr = 1'b1;
            end
        end
    end
    // MEM_Wr
    always_comb begin 
        if (Flush_Exception == `FlushEnable) begin
            MEM_Wr   = 1'bx;
        end 
        else if ( Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin  //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            MEM_Wr   = 1'b0;
        end
        else begin
            MEM_Wr   = 1'b1;
        end
    end
    //MEM2
    always_comb begin 
        if (Flush_Exception == `FlushEnable) begin
            MEM2_Wr   = 1'bx;
        end 
        else if ( Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin  //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            MEM2_Wr   = 1'b0;
        end
        else begin
            MEM2_Wr   = 1'b1;
        end
    end
    // WB_Wr
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            WB_Wr   = 1'b1;  // 异常时MEM_WB写使能始终打开
        end 
        else if ( Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin   //Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
            WB_Wr   = 1'b0;  // 停滞流水线时 wb级数据不能写入RF
        end
        else begin
            WB_Wr   = 1'b1;
        end
    end
    // ID_Flush
    always_comb begin
        if (Flush_Exception == `FlushEnable ) begin
            ID_Flush = 1'b1;
        end 
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY)begin
            ID_Flush = 1'b0;
        end
        else if (BranchFailed == 1'b1) begin // Dcache空闲的状态下，才考虑分支失败对应的flush
            ID_Flush = 1'b1;
        end
        // else if (Icache_busy == `CACHEBUSY ) begin // 策略调整为 Icache busy时，指令继续流动 
        //      ID_Flush = 1'b1;                   // Dcache busy停滞流水线 ， Icache busy 一个flush+继续流动后续流水线
        // end
        else begin
            ID_Flush = 1'b0;
        end
    end

    // EXE_Flush
    // 对于存在数据冒险的情况，必须等到I & D$不busy的时候，再去考虑Data Hazard 
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            EXE_Flush = 1'b1;
        end 
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            EXE_Flush = 1'b0;
        end
        else if  (EXE_Flush_DataHazard == 1'b1) begin   // Dcache 空闲的情况下，才考虑数据冒险的情况 
            EXE_Flush = 1'b1;
        end
        else begin
            EXE_Flush = 1'b0;
        end
    end

    // MEM_Flush
    always_comb begin
        if (Flush_Exception == `FlushEnable) begin
            MEM_Flush = 1'b1;
        end
        else begin
            MEM_Flush = 1'b0;
        end
    end

    assign WB_Flush = 1'b0;

//-------------------------DisWr信号生成---------------------------------------------------------//
    // Dcache 停滞流水线时 wb级数据不能写入RF
    always_comb begin
        if (Flush_Exception == `FlushEnable)begin  // 异常和D$busy同时出现，不需要关闭RF的写使能
            WB_DisWr =  1'b0;
        end
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            WB_DisWr =  1'b1;
        end else begin
            WB_DisWr =  1'b0;
        end
    end

    always_comb begin
        if (Flush_Exception == `FlushEnable)begin  // 异常和D$busy同时出现，不需要关闭RF的写使能
            MEM_DisWr =  1'b0;
        end
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            MEM_DisWr =  1'b1;
        end else begin
            MEM_DisWr =  1'b0;
        end
    end

    // HILO的flush  如果出现异常 产生flush信号，需要打断状态机
    // 乘除法中的状态机会被打断
    always_comb begin
        if (Flush_Exception == `FlushEnable)begin
            EXE_DisWr = 1'b0;
        end
        else if (Dcache_busy == `CACHEBUSY || Icache_busy == `CACHEBUSY) begin
            EXE_DisWr = 1'b1;
        end
        else begin
            EXE_DisWr = 1'b1;
        end
    end
    
endmodule