/*
 * @Author: npuwth
 * @Date: 2021-06-30 22:17:38
 * @LastEditTime: 2021-07-11 20:10:08
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
    input logic                  rst,
    input logic [31:0]           Virt_Iaddr,                        //也就是PC
    input logic [31:0]           Virt_Daddr,                        //也就是MEM_ALUOut
    input LoadType               MEM_LoadType,
    input StoreType              MEM_StoreType,
    input ExceptinPipeType       IF_ExceptType,
    input ExceptinPipeType       MEM_ExceptType,
    input logic                  MEM_IsTLBP,                        //表示是否是TLBP指令
    input logic                  MEM_IsTLBW,
    input logic                  TLBBuffer_Flush,                   //TLBW等修改TLB的指令时对TLB Buffer进行清空
    CP0_MMU_Interface            CMBus,
    output logic [31:0]          Phsy_Iaddr,
    output logic [31:0]          Phsy_Daddr,
    output logic                 I_IsCached,
    output logic                 D_IsCached,
    output logic                 I_IsTLBBufferValid,
    output logic                 D_IsTLBBufferValid,
    output ExceptinPipeType      IF_ExceptType_new,
    output ExceptinPipeType      MEM_ExceptType_new
);
    logic                        s0_found;
    logic [3:0]                  s0_index;
    logic [18:0]                 s1_vpn2;                           //访存和指令TLBP复用
    logic                        s1_found;
    logic [3:0]                  s1_index;

    TLB_Buffer                   I_TLBBuffer;                       //取指的TLB Buffer
    TLB_Buffer                   D_TLBBuffer;                       //访存的TLB Buffer
    TLB_Entry                    I_TLBEntry;                        //TLB Buffer与TLB进行页表项的换入换出
    TLB_Entry                    D_TLBEntry;                        //TLB Buffer与TLB进行页表项的换入换出
    logic                        I_TLBBuffer_Wr;                    //TLB Buffer的写使能
    logic                        D_TLBBuffer_Wr;                    //TLB Buffer的写使能
    logic                        I_IsTLBException;                  //查询TLB是否发生异常
    logic                        D_IsTLBException;                  //查询TLB是否发生异常
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
        .w_index                 (CMBus.CP0_index ),  //写索引
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

//------------------------------------根据TLB Buffer进行虚实地址转换-----------------------------------//
    always_comb begin //TLBI
        if(Virt_Iaddr < 32'hC000_0000 && Virt_Iaddr > 32'h9FFF_FFFF) begin
            Phsy_Iaddr        = Virt_Iaddr - 32'hA000_0000; 
        end
        else if(Virt_Iaddr < 32'hA000_0000 && Virt_Iaddr > 32'h7FFF_FFFF) begin
            Phsy_Iaddr        = Virt_Iaddr - 32'h8000_0000;
        end
        else if(Virt_Iaddr[12] == 1'b0) begin                            //根据TLB Buffer进行转换
            Phsy_Iaddr        = {I_TLBBuffer.PFN0,Virt_Iaddr[11:0]};
        end
        else begin
            Phsy_Iaddr        = {I_TLBBuffer.PFN1,Virt_Iaddr[11:0]};
        end
    end

    always_comb begin //TLBD
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'hA000_0000;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'h8000_0000;
        end
        else if(Virt_Daddr[12] == 1'b0) begin
            Phsy_Daddr        = {D_TLBBufferD.PFN0,Virt_Daddr[11:0]};
        end
        else begin
            Phsy_Daddr        = {D_TLBBufferD.PFN1,Virt_Daddr[11:0]};
        end
    end
//---------------------------------判断使用TLB Buffer进行的地址转换是否有效------------------//
    always_comb begin //TLBI
        if(Virt_Iaddr < 32'hC000_0000 && Virt_Iaddr > 32'h9FFF_FFFF) begin  //不走TLB，认为有效
            I_IsTLBBufferValid= 1'b1; 
        end
        else if(Virt_Iaddr < 32'hA000_0000 && Virt_Iaddr > 32'h7FFF_FFFF) begin
            I_IsTLBBufferValid= 1'b1; 
        end
        else if((Virt_Iaddr[31:13] == I_TLBBuffer.VPN2) && ((CMBus.CP0_asid == I_TLBBuffer.ASID) || I_TLBBuffer.G)) begin //说明TLB Buffer正好是我们想要的
            if(Virt_Iaddr[12] == 1'b0) begin
                if(I_TLBBuffer.V0 == 1'b0) I_IsTLBBufferValid = 1'b0; //判断是否有效
                else                       I_IsTLBBufferValid = 1'b1;
            end
            else begin
                if(I_TLBBuffer.V1 == 1'b0) I_IsTLBBufferValid = 1'b0;
                else                       I_IsTLBBufferValid = 1'b1;
            end
        end
        else begin     //说明TLB Buffer不是我们想要的
            I_IsTLBBufferValid= 1'b0;
        end
    end

    always_comb begin //TLBD
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin  //不走TLB，认为有效
            D_IsTLBBufferValid= 1'b1; 
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            D_IsTLBBufferValid= 1'b1; 
        end
        else if((Virt_Daddr[31:13] == D_TLBBuffer.VPN2) && ((CMBus.CP0_asid == D_TLBBuffer.ASID) || D_TLBBuffer.G)) begin //说明TLB Buffer正好是我们想要的
            if(Virt_Daddr[12] == 1'b0) begin
                if(D_TLBBuffer.V0 == 1'b0) D_IsTLBBufferValid = 1'b0; //判断是否有效
                else if(D_TLBBuffer.V0 == 1'b1 && D_TLBBuffer.D0 == 1'b0 && MEM_StoreType.DMWr == 1'b1) D_IsTLBBufferValid = 1'b0; //判断是否有修改例外
                else                       D_IsTLBBufferValid = 1'b1;
            end
            else begin
                if(D_TLBBuffer.V1 == 1'b0) D_IsTLBBufferValid = 1'b0;
                else if(D_TLBBuffer.V1 == 1'b1 && D_TLBBuffer.D1 == 1'b0 && MEM_StoreType.DMWr == 1'b1) D_IsTLBBufferValid = 1'b0;
                else                       D_IsTLBBufferValid = 1'b1;
            end
        end
        else begin     //说明TLB Buffer不是我们想要的
            D_IsTLBBufferValid= 1'b0;
        end
    end
//---------------------------------------------------------------------------------------//
//------------------------------------对TLB Buffer进行赋值---------------------------------//
    //--------------------对一整个TLB项进行换入换出----------------------//
    always_ff @(posedge clk ) begin //TLBI
        if(rst == `RstEnable || TLBBuffer_Flush == 1'b1) begin
            I_TLBBuffer.VPN2          <= '0;
            I_TLBBuffer.ASID          <= '0;
            I_TLBBuffer.G             <= '0;
            I_TLBBuffer.PFN0          <= '0;
            I_TLBBuffer.C0            <= '0;
            I_TLBBuffer.D0            <= '0;
            I_TLBBuffer.V0            <= '0;
            I_TLBBuffer.PFN1          <= '0;
            I_TLBBuffer.C1            <= '0;
            I_TLBBuffer.D1            <= '0;
            I_TLBBuffer.V1            <= '0;
        end
        else if(I_TLBBuffer_Wr == 1'b1) begin
            I_TLBBuffer.VPN2          <= I_TLBEntry.VPN2;
            I_TLBBuffer.ASID          <= I_TLBEntry.ASID;
            I_TLBBuffer.G             <= I_TLBEntry.G;
            I_TLBBuffer.PFN0          <= I_TLBEntry.PFN0;
            I_TLBBuffer.C0            <= I_TLBEntry.C0;
            I_TLBBuffer.D0            <= I_TLBEntry.D0;
            I_TLBBuffer.V0            <= I_TLBEntry.V0;
            I_TLBBuffer.PFN1          <= I_TLBEntry.PFN1;
            I_TLBBuffer.C1            <= I_TLBEntry.C1;
            I_TLBBuffer.D1            <= I_TLBEntry.D1;
            I_TLBBuffer.V1            <= I_TLBEntry.V1;
        end
    end

    always_ff @(posedge clk ) begin //TLBD
        if(rst == `RstEnable || TLBBuffer_Flush == 1'b1) begin
            D_TLBBuffer.VPN2          <= '0;
            D_TLBBuffer.ASID          <= '0;
            D_TLBBuffer.G             <= '0;
            D_TLBBuffer.PFN0          <= '0;
            D_TLBBuffer.C0            <= '0;
            D_TLBBuffer.D0            <= '0;
            D_TLBBuffer.V0            <= '0;
            D_TLBBuffer.PFN1          <= '0;
            D_TLBBuffer.C1            <= '0;
            D_TLBBuffer.D1            <= '0;
            D_TLBBuffer.V1            <= '0;
        end
        else if(D_TLBBuffer_Wr == 1'b1) begin
            D_TLBBuffer.VPN2          <= D_TLBEntry.VPN2;
            D_TLBBuffer.ASID          <= D_TLBEntry.ASID;
            D_TLBBuffer.G             <= D_TLBEntry.G;
            D_TLBBuffer.PFN0          <= D_TLBEntry.PFN0;
            D_TLBBuffer.C0            <= D_TLBEntry.C0;
            D_TLBBuffer.D0            <= D_TLBEntry.D0;
            D_TLBBuffer.V0            <= D_TLBEntry.V0;
            D_TLBBuffer.PFN1          <= D_TLBEntry.PFN1;
            D_TLBBuffer.C1            <= D_TLBEntry.C1;
            D_TLBBuffer.D1            <= D_TLBEntry.D1;
            D_TLBBuffer.V1            <= D_TLBEntry.V1;
        end
    end
    //----------------------对TLB Buffer的异常是分开赋值的--------------------------//
    always_ff @(posedge clk ) begin //TLBI
        if(rst == `RstEnable || TLBBuffer_Flush == 1'b1) begin
            I_TLBBuffer.IsTLBException<= '0;
        end
        else begin
            I_TLBBuffer.IsTLBException<= I_IsTLBException;
        end
    end

    always_ff @(posedge clk ) begin //TLBD
        if(rst == `RstEnable || TLBBuffer_Flush == 1'b1) begin
            D_TLBBuffer.IsTLBException<= '0;
        end
        else begin
            D_TLBBuffer.IsTLBException<= D_IsTLBException;
        end
    end

//-------------------------------复用访存的port实现TLBP-----------------------------------------//
    MUX2to1#(19) U_MUX_s1vpn (
        .d0                   (Virt_Daddr[31:13]),
        .d1                   (CMBus.CP0_vpn2),
        .sel2_to_1            (MEM_IsTLBP),//
        .y                    (s1_vpn2)
    );
//-------------------------------对search的结果进行奇偶页选择--------------------------------------//
    always_comb begin
        if(s0_found == 0) begin//未命中
            s0_pfn   = 'x;
            s0_c     = 'x;
            s0_d     = 'x;
            s0_v     = 'x;
        end
        else begin             //根据oddpage，即地址第12位判断取 前半段 还是取 后半段
            if(s0_odd_page==0) begin
                s0_pfn = tlb_pfn0[s0_index];
                s0_c   = tlb_c0[s0_index];
                s0_d   = tlb_d0[s0_index];
                s0_v   = tlb_v0[s0_index];
            end
            else begin
                s0_pfn = tlb_pfn1[s0_index];
                s0_c   = tlb_c1[s0_index];
                s0_d   = tlb_d1[s0_index];
                s0_v   = tlb_v1[s0_index];
            end
        end
    end

    always_comb begin
        if(s1_found == 0) begin//未命中
            s1_pfn   = 'x;
            s1_c     = 'x;
            s1_d     = 'x;
            s1_v     = 'x;
        end
        else begin             //根据oddpage，即地址第12位判断取 前半段 还是取 后半段
            if(s1_odd_page==0) begin
                s1_pfn = tlb_pfn0[s1_index];
                s1_c   = tlb_c0[s1_index];
                s1_d   = tlb_d0[s1_index];
                s1_v   = tlb_v0[s1_index];
            end
            else begin
                s1_pfn = tlb_pfn1[s1_index];
                s1_c   = tlb_c1[s1_index];
                s1_d   = tlb_d1[s1_index];
                s1_v   = tlb_v1[s1_index];
            end
        end
    end

//------------------------------进行异常判断----------------------------------------------//
    assign IF_ExceptType_new.Interrupt              = IF_ExceptType.Interrupt;
    assign IF_ExceptType_new.WrongAddressinIF       = IF_ExceptType.WrongAddressinIF;
    assign IF_ExceptType_new.ReservedInstruction    = IF_ExceptType.ReservedInstruction;
    assign IF_ExceptType_new.Syscall                = IF_ExceptType.Syscall;
    assign IF_ExceptType_new.Break                  = IF_ExceptType.Break;
    assign IF_ExceptType_new.Eret                   = IF_ExceptType.Eret;
    assign IF_ExceptType_new.WrWrongAddressinMEM    = IF_ExceptType.WrWrongAddressinMEM;
    assign IF_ExceptType_new.RdWrongAddressinMEM    = IF_ExceptType.RdWrongAddressinMEM;
    assign IF_ExceptType_new.Overflow               = IF_ExceptType.Overflow;
    assign IF_ExceptType_new.Refetch                = IF_ExceptType.Refetch;
    assign IF_ExceptType_new.Trap                   = IF_ExceptType.Trap;
    assign IF_ExceptType_new.RdTLBRefillinMEM       = IF_ExceptType.RdTLBRefillinMEM;
    assign IF_ExceptType_new.RdTLBInvalidinMEM      = IF_ExceptType.RdTLBInvalidinMEM;
    assign IF_ExceptType_new.WrTLBRefillinMEM       = IF_ExceptType.WrTLBRefillinMEM;
    assign IF_ExceptType_new.WrTLBInvalidinMEM      = IF_ExceptType.WrTLBInvalidinMEM;
    assign IF_ExceptType_new.TLBModified            = IF_ExceptType.TLBModified;

    always_comb begin
        if(s0_found == 1'b0 && (Virt_Iaddr > 32'hbfff_ffff || Virt_Iaddr < 32'h8000_0000)) begin
            IF_ExceptType_new.TLBRefillinIF         = 1'b1;
            IF_ExceptType_new.TLBInvalidinIF        = 1'b0;  
            I_IsTLBException                        = 1'b1;
        end          
        else if(s0_found == 1'b1 && s0_v == 1'b0 && (Virt_Iaddr > 32'hbfff_ffff || Virt_Iaddr < 32'h8000_0000)) begin
            IF_ExceptType_new.TLBRefillinIF         = 1'b0;
            IF_ExceptType_new.TLBInvalidinIF        = 1'b1;
            I_IsTLBException                        = 1'b1;
        end
        else begin
            IF_ExceptType_new.TLBRefillinIF         = 1'b0;
            IF_ExceptType_new.TLBInvalidinIF        = 1'b0; 
            I_IsTLBException                        = 1'b0;
        end
    end

    assign MEM_ExceptType_new.Interrupt             = MEM_ExceptType.Interrupt;
    assign MEM_ExceptType_new.WrongAddressinIF      = MEM_ExceptType.WrongAddressinIF;
    assign MEM_ExceptType_new.ReservedInstruction   = MEM_ExceptType.ReservedInstruction;
    assign MEM_ExceptType_new.Syscall               = MEM_ExceptType.Syscall;
    assign MEM_ExceptType_new.Break                 = MEM_ExceptType.Break;
    assign MEM_ExceptType_new.Eret                  = MEM_ExceptType.Eret;
    assign MEM_ExceptType_new.WrWrongAddressinMEM   = MEM_ExceptType.WrWrongAddressinMEM;
    assign MEM_ExceptType_new.RdWrongAddressinMEM   = MEM_ExceptType.RdWrongAddressinMEM;
    assign MEM_ExceptType_new.Overflow              = MEM_ExceptType.Overflow;
    assign MEM_ExceptType_new.Refetch               = MEM_ExceptType.Refetch;
    assign MEM_ExceptType_new.Trap                  = MEM_ExceptType.Trap;
    assign MEM_ExceptType_new.TLBRefillinIF         = MEM_ExceptType.TLBRefillinIF;
    assign MEM_ExceptType_new.TLBInvalidinIF        = MEM_ExceptType.TLBInvalidinIF;
    
    always_comb begin
        if(s1_found == 1'b0 && MEM_LoadType.ReadMem == 1'b1 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.RdTLBRefillinMEM      = 1'b1;
            MEM_ExceptType_new.RdTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.WrTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.WrTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b0;
            D_IsTLBException                         = 1'b1;
        end
        else if(s1_found == 1'b1 && s1_v == 1'b0 && MEM_LoadType.ReadMem == 1'b1 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.RdTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.RdTLBInvalidinMEM     = 1'b1;
            MEM_ExceptType_new.WrTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.WrTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b0;
            D_IsTLBException                         = 1'b1;
        end
        else if(s1_found == 1'b0 && MEM_StoreType.DMWr == 1'b1 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.RdTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.RdTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.WrTLBRefillinMEM      = 1'b1;
            MEM_ExceptType_new.WrTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b0;
            D_IsTLBException                         = 1'b1;
        end
        else if(s1_found == 1'b1 && s1_v == 1'b0 && MEM_StoreType.DMWr == 1'b1 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.RdTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.RdTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.WrTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.WrTLBInvalidinMEM     = 1'b1;
            MEM_ExceptType_new.TLBModified           = 1'b0;
            D_IsTLBException                         = 1'b1;
        end
        else if(s1_found == 1'b1 && s1_v == 1'b1 && s1_d == 1'b0 && MEM_StoreType.DMWr == 1'b1 && (Virt_Daddr > 32'hbfff_ffff || Virt_Daddr < 32'h8000_0000)) begin
            MEM_ExceptType_new.RdTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.RdTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.WrTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.WrTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b1;
            D_IsTLBException                         = 1'b1;
        end
        else begin
            MEM_ExceptType_new.RdTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.RdTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.WrTLBRefillinMEM      = 1'b0;
            MEM_ExceptType_new.WrTLBInvalidinMEM     = 1'b0;
            MEM_ExceptType_new.TLBModified           = 1'b0;
            D_IsTLBException                         = 1'b0;
        end
    end

    always_comb begin
        if(Virt_Iaddr < 32'hC000_0000 && Virt_Iaddr > 32'h9FFF_FFFF) begin
            I_IsCached                               = 1'b0;
        end
        else if(Virt_Iaddr < 32'hA000_0000 && Virt_Iaddr > 32'h7FFF_FFFF) begin
            I_IsCached                               = 1'b1;
        end
        else begin
            if(s0_c == 3'b011) begin
                I_IsCached                           = 1'b1;
            end
            else begin
                I_IsCached                           = 1'b0;
            end
        end
    end

    always_comb begin
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            D_IsCached                               = 1'b0;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            D_IsCached                               = 1'b1;
        end
        else begin
            if(s1_c == 3'b011) begin
                D_IsCached                           = 1'b1;
            end
            else begin
                D_IsCached                           = 1'b0;
            end
        end
    end
//--------------------------------------------------------------------------------------//
endmodule