/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-17 10:05:16
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"
`include "../Cache_options.svh"
// TODO: CUPTOP中需要修改接口
module TOP_MEM (
    input logic                  clk,
    input logic                  resetn,
    input logic                  MEM_Flush,
    input logic                  MEM_Wr,

    input logic  [5:0]           Interrupt,//中断
    input logic                  MEM_DisWr,
    input TLB_Entry              D_TLBEntry,
    input logic                  s1_found,
    
    EXE_MEM_Interface            EMBus,
    MEM_MEM2_Interface           MM2Bus,
    CP0_TLB_Interface            CTBus,
    CPU_Bus_Interface            cpu_dbus,
    AXI_Bus_Interface            axi_dbus,
    AXI_UNCACHE_Interface        axi_ubus,
    output logic                 Flush_Exception,
    output logic [2:0]           EX_Entry_Sel,
    output logic                 MEM_IsTLBP,
    output logic                 MEM_IsTLBW,
    output logic                 MEM_TLBWIorR,
    output logic [31:0]          MEM_PC,
    output logic [31:0]          CP0_EPC,
    output LoadType              MEM_LoadType,
    output StoreType             MEM_StoreType,
    output logic [4:0]           MEM_rt,
    output logic [31:0]          Exception_Vector,
    output logic [31:13]         D_VPN2,
    output logic                 D_IsTLBBufferValid,
    output logic                 D_IsTLBStall,
    output logic                 TLBBuffer_Flush
);
    ExceptinPipeType             MEM_ExceptType;
	RegsWrType                   MEM_RegsWrType; 
    logic [31:0]                 RFHILO_Bus;
    logic [1:0]                  MEM_RegsReadSel;
    logic [4:0]                  MEM_rd;               //用于读CP0
    logic [31:0]                 MEM_Result;
    logic [31:0]                 CP0_Bus;
    RegsWrType                   MEM_Final_Wr;
    logic [3:0]                  MEM_DCache_Wen;   
    logic [31:0]                 MEM_DataToDcache;
    logic                        MEM_IsTLBR;
    //传给Exception
    logic                        CP0_Status_BEV;
    logic [7:0]                  CP0_Status_IM7_0;
    logic                        CP0_Status_EXL;
    logic                        CP0_Status_IE;
    logic [7:2]                  CP0_Cause_IP7_2;
    logic [1:0]                  CP0_Cause_IP1_0;
    logic [31:0]                 CP0_Ebase;
    logic [2:0]                  MEM_TLBExceptType;
    logic [31:0]                 Phsy_Daddr;
    logic                        D_IsCached;

    //表示当前指令是否在延迟槽中，通过判断上一条指令是否是branch或jump实现
    assign MM2Bus.MEM_IsInDelaySlot = MM2Bus.MEM2_IsABranch || MM2Bus.MEM2_IsAImmeJump; 
    assign EMBus.MEM_RegsWrType     = MM2Bus.MEM_RegsWrType;        // 传给EXE用于旁路
    assign EMBus.MEM_Dst            = MM2Bus.MEM_Dst;               // 用于旁路且判断重取判断是否是entry high
    assign EMBus.MEM_Result         = MEM_Result;                   // 传给EXE用于旁路    
    assign EMBus.MEM_IsTLBR         = MEM_IsTLBR;                   // 判断重取
    assign EMBus.MEM_IsTLBW         = MEM_IsTLBW;                   // 判断重取
    assign EMBus.MEM_Instr          = MM2Bus.MEM_Instr;             // 判断重取判断是否是entry high
    assign MEM_PC                   = MM2Bus.MEM_PC;                // MEM_PC要输出用于重取机制
    assign Virt_Daddr               = MM2Bus.MEM_ALUOut;
    assign MEM_Final_Wr             = (MEM_DisWr)? '0: MM2Bus.MEM_RegsWrType; //当发生阻塞时，要关掉CP0写使能，防止提前写入软件中断

    assign TLBBuffer_Flush          = (MEM_IsTLBR == 1'b1 || MEM_IsTLBW == 1'b1 || (MM2Bus.MEM_Instr[31:21] == 11'b01000000100 && MM2Bus.MEM_Dst == `CP0_REG_ENTRYHI));
    // assign MEM_store_req            = MEM_StoreType.DMWr ;
    MEM_Reg U_MEM_Reg ( 
        .clk                     (clk ),
        .rst                     (resetn ),
        .MEM_Flush               (MEM_Flush ),
        .MEM_Wr                  (MEM_Wr ),

        .EXE_ALUOut              (EMBus.EXE_ALUOut ),
        .EXE_OutB                (EMBus.EXE_OutB ),
        .EXE_PC                  (EMBus.EXE_PC ),
        .EXE_Instr               (EMBus.EXE_Instr ),
        .EXE_BranchType          (EMBus.EXE_BranchType ),
        .EXE_IsAImmeJump         (EMBus.EXE_IsAImmeJump ),
        .EXE_LoadType            (EMBus.EXE_LoadType ),
        .EXE_StoreType           (EMBus.EXE_StoreType ),
        .EXE_Dst                 (EMBus.EXE_Dst ),
        .EXE_RegsWrType          (EMBus.EXE_RegsWrType ),
        .EXE_WbSel               (EMBus.EXE_WbSel ),
        .EXE_ExceptType_final    (EMBus.EXE_ExceptType_final ),
        .EXE_DCache_Wen          (EMBus.EXE_DCache_Wen),
        .EXE_DataToDcache        (EMBus.EXE_DataToDcache),
        .EXE_IsTLBP              (EMBus.EXE_IsTLBP),
        .EXE_IsTLBW              (EMBus.EXE_IsTLBW),
        .EXE_IsTLBR              (EMBus.EXE_IsTLBR),
        .EXE_TLBWIorR            (EMBus.EXE_TLBWIorR),
        .EXE_RegsReadSel         (EMBus.EXE_RegsReadSel),
        .EXE_rd                  (EMBus.EXE_rd),
        .EXE_rt                  (EMBus.EXE_rt),
    //------------------------out--------------------------------------------------//
        .MEM_ALUOut              (MM2Bus.MEM_ALUOut ),  
        .MEM_OutB                (RFHILO_Bus ),
        .MEM_PC                  (MM2Bus.MEM_PC ),
        .MEM_Instr               (MM2Bus.MEM_Instr ),
        .MEM_IsABranch           (MM2Bus.MEM_IsABranch ),
        .MEM_IsAImmeJump         (MM2Bus.MEM_IsAImmeJump ),
        .MEM_LoadType            (MEM_LoadType ),
        .MEM_StoreType           (MEM_StoreType),
        .MEM_Dst                 (MM2Bus.MEM_Dst ),
        .MEM_RegsWrType          (MEM_RegsWrType ),//未经过Exception的
        .MEM_WbSel               (MM2Bus.MEM_WbSel ),
        .MEM_ExceptType          (MEM_ExceptType ),
        .MEM_DCache_Wen          (MEM_DCache_Wen),//DCache的字节写使能
        .MEM_DataToDcache        (MEM_DataToDcache),
        .MEM_IsTLBP              (MEM_IsTLBP),
        .MEM_IsTLBW              (MEM_IsTLBW),
        .MEM_IsTLBR              (MEM_IsTLBR),
        .MEM_TLBWIorR            (MEM_TLBWIorR),
        .MEM_RegsReadSel         (MEM_RegsReadSel),
        .MEM_rd                  (MEM_rd),
        .MEM_rt                  (MEM_rt)
    );

    Exception U_Exception(
        .MEM_RegsWrType          (MEM_RegsWrType),              
        .MEM_ExceptType          (MEM_ExceptType),        
        .MEM_TLBExceptType       (MEM_TLBExceptType),
        .MEM_PC                  (MM2Bus.MEM_PC),   
        .CP0_Status_BEV          (CP0_Status_BEV),                  
        .CP0_Status_IM7_0        (CP0_Status_IM7_0 ),
        .CP0_Status_EXL          (CP0_Status_EXL ),
        .CP0_Status_IE           (CP0_Status_IE ),
        .CP0_Cause_IP7_2         (CP0_Cause_IP7_2 ),
        .CP0_Cause_IP1_0         (CP0_Cause_IP1_0), 
        .CP0_Ebase               (CP0_Ebase),     
    //------------------------------out--------------------------------------------//
        .MEM_RegsWrType_final    (MM2Bus.MEM_RegsWrType),             
        .Flush_Exception         (Flush_Exception),                         
        .EX_Entry_Sel            (EX_Entry_Sel),            
        .MEM_ExcType             (MM2Bus.MEM_ExcType),
        .Exception_Vector        (Exception_Vector)                          
    );

    cp0_reg U_CP0 (
        .clk                    (clk ),
        .rst                    (resetn ),
        .Interrupt              (Interrupt ),
        .CP0_Sel                (MM2Bus.MEM_Instr[2:0]),
        .CP0_RdAddr             (MEM_rd ),
        .CP0_RdData             (CP0_Bus ),
        .MEM_RegsWrType         (MEM_Final_Wr ),
        .MEM_Dst                (MM2Bus.MEM_Dst ),
        .MEM_Result             (MEM_Result ),
        .MEM_IsTLBP             (MEM_IsTLBP ),
        .MEM_IsTLBR             (MEM_IsTLBR ),
        .CTBus                  (CTBus.CP0 ),
        .MEM2_ExcType           (MM2Bus.MEM2_ExcType ),
        .MEM2_PC                (MM2Bus.MEM2_PC ),
        .MEM2_IsInDelaySlot     (MM2Bus.MEM2_IsInDelaySlot ),
        .MEM2_ALUOut            (MM2Bus.MEM2_ALUOut ),
        //---------------output----------------//
        .CP0_Status_BEV         (CP0_Status_BEV),
        .CP0_Status_IM7_0       (CP0_Status_IM7_0 ),
        .CP0_Status_EXL         (CP0_Status_EXL ),
        .CP0_Status_IE          (CP0_Status_IE ),
        .CP0_Cause_IP7_2        (CP0_Cause_IP7_2 ),
        .CP0_Cause_IP1_0        (CP0_Cause_IP1_0),
        .CP0_EPC                (CP0_EPC)
  );

    
    //------------------------------用于旁路的多选器-------------------------------//
    MUX4to1 U_MUXINMEM ( //选择用于旁路的数据来自ALUOut还是OutB
        .d0                      (MM2Bus.MEM_PC + 8),
        .d1                      (MM2Bus.MEM_ALUOut),
        .d2                      (MM2Bus.MEM_OutB  ),
        .d3                      ('x               ),
        .sel4_to_1               (MM2Bus.MEM_WbSel ),
        .y                       (MEM_Result       )
    );
    //---------------------------------------------------------------------------//
//-------------------------------------------TO Cache-------------------------------//
    assign cpu_dbus.wdata                                 =  MM2Bus.MEM_OutB;
    assign cpu_dbus.tag                                   = Phsy_Daddr[31:12];
    assign {cpu_dbus.index,cpu_dbus.offset}               =  MM2Bus.MEM_ALUOut[11:0];                 // inst_sram_addr_o 虚拟地址
    assign cpu_dbus.op                                    = (MEM_LoadType.ReadMem)? 1'b0 :
                                                            (MEM_StoreType.DMWr) ? 1'b1  :
                                                             1'bx;
    assign cpu_dbus.wstrb                                 = MEM_DCache_Wen;
    assign cpu_dbus.loadType                              = MEM_LoadType;
    assign cpu_dbus.isCache                               = D_IsCached;
    Dcache #(
        .DATA_WIDTH              (32 ),
        .LINE_WORD_NUM           (`DCACHE_LINE_WORD ),
        .ASSOC_NUM               (`DCACHE_SET_ASSOC ),
        .WAY_SIZE                (4*1024*8 )
    )
    U_Dcache (
        .clk                     (clk ),
        .resetn                  (resetn ),
        .axi_ubus                (axi_ubus ),
        .cpu_bus                 (cpu_dbus ),
        .axi_bus                 ( axi_dbus)
    );

    MUX4to1 #(32) U_MUX_OutB2 ( 
        .d0                      (RFHILO_Bus),
        .d1                      (RFHILO_Bus),
        .d2                      (RFHILO_Bus),
        .d3                      (CP0_Bus),
        .sel4_to_1               (MEM_RegsReadSel),
        .y                       (MM2Bus.MEM_OutB)
    );

    DTLB U_DTLB (
        .clk                     (clk ),
        .rst                     (rst ),
        .Virt_Daddr              (MM2Bus.MEM_ALUOut ),
        .TLBBuffer_Flush         (TLBBuffer_Flush ),
        .D_TLBEntry              (D_TLBEntry ),
        .s1_found                (s1_found ),
        .MEM_LoadType            (MEM_LoadType ),
        .MEM_StoreType           (MEM_StoreType ),
        .Phsy_Daddr              (Phsy_Daddr ),
        .D_IsCached              (D_IsCached ),
        .D_IsTLBBufferValid      (D_IsTLBBufferValid ),
        .D_IsTLBStall            (D_IsTLBStall ),
        .MEM_TLBExceptType       (MEM_TLBExceptType ),
        .D_VPN2                  ( D_VPN2)
  );


endmodule