/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-12 12:35:16
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"
// TODO: CUPTOP中需要修改接口
module TOP_MEM (
    input logic                  clk,
    input logic                  resetn,
    input logic                  MEM_Flush,
    input logic                  MEM_Wr,
    input logic  [31:0]          Phsy_Daddr, 
    input logic                  D_IsCached,
    input logic  [5:0]           Interrupt,//中断
    input ExceptinPipeType       MEM_ExceptType_new,
    input logic                  MEM_DisWr,
    EXE_MEM_Interface            EMBus,
    MEM_MEM2_Interface           MM2Bus,
    // MEM_WB_Interface             MWBus,
    CP0_MMU_Interface            CMBus,
    CPU_Bus_Interface            cpu_dbus,
    AXI_Bus_Interface            axi_dbus,
    AXI_UNCACHE_Interface        axi_ubus,
    output logic                 ID_Flush_Exception,
    output logic                 EXE_Flush_Exception,
    output logic                 MEM_Flush_Exception,
    output logic [2:0]           EX_Entry_Sel,
    output logic [31:0]          Virt_Daddr,
    output logic                 MEM_IsTLBP,
    output logic                 MEM_IsTLBW,
    output logic                 MEM_IsTLBR,
    output logic [31:0]          MEM_PC,
    output logic [31:0]          CP0_EPC,
    output ExceptinPipeType      MEM_ExceptType,
    output LoadType              MEM_LoadType,
    output StoreType             MEM_StoreType,
    output logic [31:0]          Exception_Vector   
);

	RegsWrType                   MEM_RegsWrType; 
    logic                        MEM_Forward_data_sel;
    logic [31:0]                 RFHILO_Bus;
    logic [1:0]                  MEM_RegsReadSel;
    logic [4:0]                  MEM_rd;
    logic [31:0]                 MEM_Result;
    logic [31:0]                 CP0_Bus;
    RegsWrType                   MEM_Final_Wr;
    logic [3:0]                  MEM_DCache_Wen;   
    logic [31:0]                 MEM_DataToDcache; 
    //传给Exception
    logic                        CP0_Status_BEV;
    logic [7:0]                  CP0_Status_IM7_0;
    logic                        CP0_Status_EXL;
    logic                        CP0_Status_IE;
    logic [7:2]                  CP0_Cause_IP7_2;
    logic [1:0]                  CP0_Cause_IP1_0;

    //表示当前指令是否在延迟槽中，通过判断上一条指令是否是branch或jump实现
    assign MM2Bus.MEM_IsInDelaySlot = MM2Bus.MEM2_IsABranch || MM2Bus.MEM2_IsAImmeJump; 
    assign EMBus.MEM_RegsWrType     = MM2Bus.MEM_RegsWrType_final;  // 用于旁路
    assign EMBus.MEM_Dst            = MM2Bus.MEM_Dst;               // 判断是否是entry high
    assign EMBus.MEM_Result         = MEM_Result;                   // 传给EXE用于旁路
    // assign MM2Bus.MEM_Result        = MEM_Result;       
    assign EMBus.MEM_IsTLBR         = MEM_IsTLBR;
    assign EMBus.MEM_IsTLBW         = MEM_IsTLBW;
    assign EMBus.MEM_Instr          = MM2Bus.MEM_Instr;            // 判断是否是entery high
    assign MEM_PC                   = MM2Bus.MEM_PC;
    assign MEM_LoadType             = MM2Bus.MEM_LoadType;

    assign MEM_Final_Wr             = (MEM_DisWr)? '0: MEM_RegsWrType ;

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
        .EXE_RegsReadSel         (EMBus.EXE_RegsReadSel),
        .EXE_rd                  (EMBus.EXE_rd),
    //------------------------out--------------------------------------------------//
        .MEM_ALUOut              (MM2Bus.MEM_ALUOut ),  
        .MEM_OutB                (RFHILO_Bus ),
        .MEM_PC                  (MM2Bus.MEM_PC ),
        .MEM_Instr               (MM2Bus.MEM_Instr ),
        .MEM_IsABranch           (MM2Bus.MEM_IsABranch ),
        .MEM_IsAImmeJump         (MM2Bus.MEM_IsAImmeJump ),
        .MEM_LoadType            (MM2Bus.MEM_LoadType ),
        .MEM_StoreType           (MEM_StoreType),
        .MEM_Dst                 (MM2Bus.MEM_Dst ),
        .MEM_RegsWrType          (MEM_RegsWrType ),
        .MEM_WbSel               (MM2Bus.MEM_WbSel ),
        .MEM_ExceptType          (MEM_ExceptType ),
        .MEM_DCache_Wen          (MEM_DCache_Wen),
        .MEM_DataToDcache        (MEM_DataToDcache),
        .MEM_IsTLBP              (MEM_IsTLBP),
        .MEM_IsTLBW              (MEM_IsTLBW),
        .MEM_IsTLBR              (MEM_IsTLBR),
        .MEM_RegsReadSel         (MEM_RegsReadSel),
        .MEM_rd                  (MEM_rd)
    );

    Exception U_Exception(
        .MEM_RegsWrType          (MEM_RegsWrType),              
        .MEM_ExceptType          (MEM_ExceptType_new),            
        .MEM_PC                  (MM2Bus.MEM_PC),   
        .CP0_Status_BEV          (CP0_Status_BEV),                  
        .CP0_Status_IM7_0        (CP0_Status_IM7_0 ),
        .CP0_Status_EXL          (CP0_Status_EXL ),
        .CP0_Status_IE           (CP0_Status_IE ),
        .CP0_Cause_IP7_2         (CP0_Cause_IP7_2 ),
        .CP0_Cause_IP1_0         (CP0_Cause_IP1_0),      
    //------------------------------out--------------------------------------------//
        .MEM_RegsWrType_final    (MM2Bus.MEM_RegsWrType),            
        .ID_Flush                (ID_Flush_Exception),                
        .EXE_Flush               (EXE_Flush_Exception),                       
        .MEM_Flush               (MEM_Flush_Exception),                           
        .EX_Entry_Sel            (EX_Entry_Sel),            
        .MEM_ExceptType_final    (MM2Bus.MEM_ExceptType_final),
        .Exception_Vector        (Exception_Vector)        // TODO:异常入口地址                    
    );

    cp0_reg U_CP0 (
        .clk                    (clk ),
        .rst                    (resetn ),
        .Interrupt              (Interrupt ),
        .CP0_RdAddr             (MEM_rd ),
        .CP0_RdData             (CP0_Bus ),
        .MEM_RegsWrType         (MEM_Final_Wr ),
        .MEM_Dst                (MM2Bus.MEM_Dst ),
        .MEM_Result             (MEM_Result ),
        .MEM_IsTLBP             (MEM_IsTLBP ),
        .MEM_IsTLBR             (MEM_IsTLBR ),
        .CMBus                  (CMBus.CP0 ),
        .MEM2_ExceptType        (MM2Bus.MEM2_ExceptType ),
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
    assign MEM_Forward_data_sel= (MM2Bus.MEM_WbSel == `WBSel_OutB)?1'b1:1'b0;

    MUX2to1 U_MUXINMEM ( //选择用于旁路的数据来自ALUOut还是OutB
        .d0                      (MM2Bus.MEM_ALUOut),
        .d1                      (MM2Bus.MEM_OutB),
        .sel2_to_1               (MEM_Forward_data_sel),
        .y                       (MEM_Result)
    );
    //---------------------------------------------------------------------------//
//-------------------------------------------TO Cache-------------------------------//
    assign cpu_dbus.wdata                                 =  MM2Bus.MEM_ALUOut;
    assign cpu_dbus.valid                                 = (MM2Bus.MEM_LoadType.ReadMem || MM2Bus.MEM_StoreType.DMWr )  ? 1 : 0;
    assign {cpu_dbus.tag,cpu_dbus.index,cpu_dbus.offset}  =  MM2Bus.MEM_ALUOut;                 // inst_sram_addr_o 虚拟地址
    assign cpu_dbus.op                                    = (MM2Bus.MEM_LoadType.ReadMem)? 1'b0 :
                                                            (MM2Bus.MEM_StoreType.DMWr) ? 1'b1  :
                                                             1'bx;
    // assign MM2Bus.MEM_DMOut                               = cpu_dbus.rdata;       //读取结果直接放入DMOut
    assign cpu_dbus.storeType                             = MM2Bus.MEM_StoreType;
    assign cpu_dbus.wstrb                                 = MEM_DCache_Wen;
    assign cpu_dbus.loadType                              = MM2Bus.MEM_LoadType;
    DCache U_DCACHE(  // TODO: cache的组织结构
        .clk            (clk),
        .resetn         (resetn),
        .Phsy_Daddr     (Phsy_Daddr),
        .D_IsCached     (D_IsCached),
        .MEM_Wr         (MEM_Wr),
        .CPUBus         (cpu_dbus.slave),
        .AXIBus         (axi_dbus.master),
        .UBus           (axi_ubus.master),
        .Virt_Daddr     (Virt_Daddr)
    );

    MUX4to1 #(32) U_MUX_OutB2 ( 
        .d0             (RFHILO_Bus),
        .d1             (RFHILO_Bus),
        .d2             (RFHILO_Bus),
        .d3             (CP0_Bus),
        .sel4_to_1      (MEM_RegsReadSel),
        .y              (MM2Bus.MEM_OutB)
    );

endmodule