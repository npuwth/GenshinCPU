/*
 * @Author: npuwth
 * @Date: 2021-06-28 18:45:50
 * @LastEditTime: 2021-07-11 20:46:36
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CPU_Defines.svh"
`include "CommonDefines.svh"

module mycpu_top (
    input  logic  [ 5:0]       ext_int,
    input  logic               aclk,
    input  logic               aresetn,
    output logic  [ 3:0]       arid,
    output logic  [31:0]       araddr,
    output logic  [ 3:0]       arlen,
    output logic  [ 2:0]       arsize,
    output logic  [ 1:0]       arburst,
    output logic  [ 1:0]       arlock,
    output logic  [ 3:0]       arcache,
    output logic  [ 2:0]       arprot,
    output logic               arvalid,
    input  logic               arready,
    input  logic  [ 3:0]       rid,
    input  logic  [31:0]       rdata,
    input  logic  [ 1:0]       rresp,
    input  logic               rlast,
    input  logic               rvalid,
    output logic               rready,
    output logic  [ 3:0]       awid,
    output logic  [31:0]       awaddr,
    output logic  [ 3:0]       awlen,
    output logic  [ 2:0]       awsize,
    output logic  [ 1:0]       awburst,
    output logic  [ 1:0]       awlock,
    output logic  [ 3:0]       awcache,
    output logic  [ 2:0]       awprot,
    output logic               awvalid,
    input  logic               awready,
    output logic  [ 3:0]       wid,
    output logic  [31:0]       wdata,
    output logic  [ 3:0]       wstrb,
    output logic               wlast,
    output logic               wvalid,
    input  logic               wready,
    input  logic  [ 3:0]       bid,
    input  logic  [ 1:0]       bresp,
    input  logic               bvalid,
    output logic               bready,
    output [31:0]              debug_wb_pc,        
    output [31:0]              debug_wb_rf_wdata,  
    output [3:0]               debug_wb_rf_wen,    
    output [4:0]               debug_wb_rf_wnum   
);
    logic [31:0]               WB_PC;                     //来自WB级,用于Debug
    logic [31:0]               WB_Result;                 //来自WB级,用于Debug
    logic [4:0]                WB_Dst;                    //来自WB级,用于Debug
    RegsWrType                 WB_Final_Wr;               //来自
    logic                      ID_Flush_Exception;        //来自exception
    logic                      EXE_Flush_Exception;       //来自exception
    logic                      MEM_Flush_Exception;       //来自exception
    logic                      DH_PCWr;                   //来自DataHazard
    logic                      DH_IDWr;                   //来自DataHazard
    logic                      EXE_Flush_DataHazard;      //来自DataHazard
    logic                      EXE_MULTDIVStall;          //来自EXE级的乘除法,用于阻塞
    logic [2:0]                EX_Entry_Sel;         //来自MEM级，表示有异常或异常返回
    logic                      ID_Flush_BranchSolvement;  //来自EXE级的branchsolvement，清空ID寄存器
    logic                      ID_IsAImmeJump;            //来自ID级，表示是j，jal跳转
    logic [31:0]               CP0_EPC;                   //来自MEM级的EPC
    //-----------------------------流水线寄存器的写使能和flush------------------------------//
    logic                      PC_Wr;                     //来自WRFlushControl
    logic                      ID_Wr;                     //来自WRFlushControl
    logic                      EXE_Wr;                    //来自WRFlushControl  
    logic                      MEM_Wr;                    //来自WRFlushControl
    logic                      WB_Wr;                     //来自WRFlushControl
    logic                      ID_Flush;                  //来自WRFlushControl
    logic                      EXE_Flush;                 //来自WRFlushControl
    logic                      MEM_Flush;                 //来自WRFlushControl
    logic                      WB_Flush;                  //来自WRFlushControl
    //--------------------------------------------------------------------------------------//
    logic                      MEM_DisWr;                 //来自WRFLUSHCONTROL，传至MEM级 
    logic                      WB_DisWr;                  //来自WRFlushControl,传至WB级，用于生成WB_Final_Wr
    logic                      HiLo_Not_Flush;            //来自WRFlushControl,传至HILO寄存器

    logic [31:0]               EXE_BusA_L1;               //来自EXE，用于MT指令写HiLo，也用于生成jr的npc
    
    RegsWrType                 WB_RegsWrType;             //WB级的写使能

    BranchType                 EXE_BranchType;            //来自EXE级，传至IF，用于生成NPC
    logic [31:0]               EXE_PC;                    //来自EXE级，传至IF，用于生成NPC
    logic [31:0]               EXE_Imm32;                 //来自EXE级，传至IF，用于生成NPC  
    //----------------------------------------------关于TLBMMU-----------------------------------------------------//
    logic                      MEM_IsTLBP;                //传至TLBMMU，用于判断是普通访存还是TLBP
    logic [31:0]               Virt_Daddr;                //传至TLBMMU，用于TLB转换
    logic [31:0]               Phsy_Daddr;                //传至TLBMMU，用于TLB转换
    logic [31:0]               Virt_Iaddr;                //传至TLBMMU，用于TLB转换
    logic [31:0]               Phsy_Iaddr;                //传至TLBMMU，用于TLB转换
    logic                      I_IsCached;                //指示Cache属性
    logic                      D_IsCached;                //指示Cache属性
    logic                      I_IsTLBException;          //指示TLB例外
    logic                      D_IsTLBException;          //指示TLB例外
    logic                      MEM_IsTLBW;                //传至TLBMMU，用于写TLB
    logic [31:0]               MEM_PC;                    //传至IF，用于TLB重取机制
    ExceptinPipeType           IF_ExceptType;             //用于TLB例外的判断        
    ExceptinPipeType           IF_ExceptType_new;         //用于TLB例外的判断   
    ExceptinPipeType           MEM_ExceptType;            //用于TLB例外的判断    
    ExceptinPipeType           MEM_ExceptType_new;        //用于TLB例外的判断    
    LoadType                   MEM_LoadType;              //用于TLB例外的判断 
    StoreType                  MEM_StoreType;             //用于TLB例外的判断 
    //--------------------------------------用于golden trace-------------------------------------------------------//
    assign debug_wb_pc = WB_PC;                                                              //写回级的PC
    assign debug_wb_rf_wdata = WB_Result;                                                    //写回寄存器的数据
    assign debug_wb_rf_wen = (WB_Final_Wr.RFWr) ? 4'b1111 : 4'b0000;                         //4位字节写使能
    assign debug_wb_rf_wnum = WB_Dst;                                                        //写回寄存器的地址
    //---------------------------------------interface实例化-------------------------------------------------------//
    CPU_Bus_Interface           cpu_ibus();
    CPU_Bus_Interface           cpu_dbus();
    AXI_Bus_Interface           axi_ibus();
    AXI_Bus_Interface           axi_dbus();
    AXI_UNCACHE_Interface       axi_ubus();
    IF_ID_Interface             IIBus();
    ID_EXE_Interface            IEBus();
    EXE_MEM_Interface           EMBus();
    MEM_WB_Interface            MWBus();
    CP0_MMU_Interface           CMBus();
    //--------------------------------------------------------------------------------------------------------------//
    WrFlushControl U_WRFlushControl (
        .ID_Flush_Exception     (ID_Flush_Exception),
        .EXE_Flush_Exception    (EXE_Flush_Exception),
        .MEM_Flush_Exception    (MEM_Flush_Exception),
        .DH_PCWr                (DH_PCWr),
        .DH_IDWr                (DH_IDWr),
        .EXE_Flush_DataHazard   (EXE_Flush_DataHazard), // 以上三个是数据冒险的3个控制信号
        .DIVMULTBusy            (EXE_MULTDIVStall),
        .EX_Entry_Sel           (EX_Entry_Sel),
        .BranchFailed           (ID_Flush_BranchSolvement),
        .ID_IsAImmeJump         (ID_IsAImmeJump),
        .Icache_data_ok         (cpu_ibus.data_ok),
        .Icache_busy            (~cpu_ibus.addr_ok),  // addr_ok = 1表示cache空闲
        .Dcache_data_ok         (cpu_dbus.data_ok),
        .Dcache_busy            (~cpu_dbus.addr_ok),  // addr_ok = 1表示cache空闲
        .I_IsTLBException       (I_IsTLBException),
        .D_IsTLBException       (D_IsTLBException),
        //-------------------------------- output-----------------------------//
        .PC_Wr                  (PC_Wr),
        .ID_Wr                  (ID_Wr),
        .EXE_Wr                 (EXE_Wr),
        .MEM_Wr                 (MEM_Wr),
        .WB_Wr                  (WB_Wr),
        .ID_Flush               (ID_Flush),
        .EXE_Flush              (EXE_Flush),
        .MEM_Flush              (MEM_Flush),
        .MEM_DisWr              (MEM_DisWr),
        .WB_Flush               (WB_Flush),
        .WB_DisWr               (WB_DisWr),
        .HiLo_Not_Flush         (HiLo_Not_Flush),
        .IcacheFlush            (cpu_ibus.flush),
        .DcacheFlush            (cpu_dbus.flush)
    );

    //------------------------AXI-----------------------//
    AXIInteract AXIInteract_dut (
        .clk                    (aclk ),
        .resetn                 (aresetn ),
        .dbus                   (axi_dbus.slave ),
        .ibus                   (axi_ibus.slave ),
        .udbus                  (axi_ubus.slave) ,
        .m_axi_arid             (arid ),
        .m_axi_araddr           (araddr ),
        .m_axi_arlen            (arlen ),
        .m_axi_arsize           (arsize ),
        .m_axi_arburst          (arburst ),
        .m_axi_arlock           (arlock ),
        .m_axi_arcache          (arcache ),
        .m_axi_arprot           (arprot ),
        .m_axi_arvalid          (arvalid ),
        .m_axi_arready          (arready ),
        .m_axi_rid              (rid ),
        .m_axi_rdata            (rdata ),
        .m_axi_rresp            (rresp ),
        .m_axi_rlast            (rlast ),
        .m_axi_rvalid           (rvalid ),
        .m_axi_rready           (rready ),
        .m_axi_awid             (awid ),
        .m_axi_awaddr           (awaddr ),
        .m_axi_awlen            (awlen ),
        .m_axi_awsize           (awsize ),
        .m_axi_awburst          (awburst ),
        .m_axi_awlock           (awlock ),
        .m_axi_awcache          (awcache ),
        .m_axi_awprot           (awprot ),
        .m_axi_awvalid          (awvalid ),
        .m_axi_awready          (awready ),
        .m_axi_wid              (wid ),
        .m_axi_wdata            (wdata ),
        .m_axi_wstrb            (wstrb ),
        .m_axi_wlast            (wlast ),
        .m_axi_wvalid           (wvalid ),
        .m_axi_wready           (wready ),
        .m_axi_bid              (bid ),
        .m_axi_bresp            (bresp ),
        .m_axi_bvalid           (bvalid ),
        .m_axi_bready           (bready)
    );

    TOP_IF U_TOP_IF ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .PC_Wr (PC_Wr ),
        .MEM_CP0Epc (CP0_EPC ),
        .EXE_BusA_L1 (EXE_BusA_L1 ),
        .ID_Flush_BranchSolvement (ID_Flush_BranchSolvement ),
        .ID_IsAImmeJump (ID_IsAImmeJump ),
        .EX_Entry_Sel (EX_Entry_Sel ),
        .EXE_BranchType (EXE_BranchType ),
        .ID_Wr (ID_Wr ),
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_DataHazard (EXE_Flush_DataHazard ),
        .EXE_PC (EXE_PC ),
        .EXE_Imm32 (EXE_Imm32 ),
        .Phsy_Iaddr(Phsy_Iaddr),
        .I_IsCached(I_IsCached),
        .MEM_PC (MEM_PC),
        .IF_ExceptType_new(IF_ExceptType_new),
        //--------------------output-----------------//
        .IIBus  ( IIBus.IF),
        .cpu_ibus (cpu_ibus),
        .axi_ibus (axi_ibus),
        .Virt_Iaddr(Virt_Iaddr),
        .IF_ExceptType(IF_ExceptType)
    );

    TOP_ID U_TOP_ID ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .ID_Flush (ID_Flush ),
        .ID_Wr (ID_Wr ),
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_RegsWrType (WB_RegsWrType ),
        .IIBus (IIBus.ID ),
        .IEBus (IEBus.ID ),
        //-------------------------------output-------------------//
        .ID_IsAImmeJump (ID_IsAImmeJump),
        .DH_PCWr(DH_PCWr),
        .DH_IDWr(DH_IDWr),
        .EXE_Flush_DataHazard(EXE_Flush_DataHazard)
    );

    TOP_EXE U_TOP_EXE ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .EXE_Flush (EXE_Flush ),
        .EXE_Wr (EXE_Wr ),
        .WB_RegsWrType (WB_RegsWrType ), //???
        .WB_Dst (WB_Dst ),
        .WB_Result (WB_Result ),
        .HiLo_Not_Flush (HiLo_Not_Flush ),
        .IEBus (IEBus.EXE ),
        .EMBus (EMBus.EXE ),
        //--------------------------output-------------------------//
        .ID_Flush_BranchSolvement (ID_Flush_BranchSolvement ),
        .EXE_MULTDIVStall  (EXE_MULTDIVStall),
        .EXE_BusA_L1 (EXE_BusA_L1),
        .EXE_BranchType (EXE_BranchType),
        .EXE_PC (EXE_PC),
        .EXE_Imm32 (EXE_Imm32)
    );

    TOP_MEM U_TOP_MEM ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .MEM_Flush (MEM_Flush ),
        .MEM_Wr (MEM_Wr ),
        .WB_Wr (WB_Wr),
        .Phsy_Daddr(Phsy_Daddr),
        .D_IsCached(D_IsCached),
        .Interrupt(ext_int),
        .MEM_ExceptType_new(MEM_ExceptType_new),
        .MEM_DisWr(MEM_DisWr),
        .EMBus (EMBus.MEM ),
        .MWBus (MWBus.MEM ),
        .CMBus (CMBus ),
        .cpu_dbus (cpu_dbus),
        .axi_dbus (axi_dbus),
        .axi_ubus (axi_ubus),
        //--------------------------output-------------------------//
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_Exception (EXE_Flush_Exception ),
        .MEM_Flush_Exception (MEM_Flush_Exception ),
        .EX_Entry_Sel (EX_Entry_Sel ),
        .Virt_Daddr(Virt_Daddr),
        .MEM_IsTLBP(MEM_IsTLBP),
        .MEM_IsTLBW(MEM_IsTLBW),
        .MEM_PC(MEM_PC),
        .CP0_EPC(CP0_EPC),
        .MEM_ExceptType(MEM_ExceptType),
        .MEM_LoadType (MEM_LoadType),
        .MEM_StoreType (MEM_StoreType)
    );

    TOP_WB U_TOP_WB ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .WB_Flush (WB_Flush ),
        .WB_Wr (WB_Wr ),
        .WB_DisWr (WB_DisWr ),
        .MWBus (MWBus.WB ),
        //--------------------------output-------------------------//
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_Final_Wr (WB_Final_Wr ),
        .WB_RegsWrType (WB_RegsWrType),
        .WB_PC(WB_PC )
    );

    TLBMMU U_TLBMMU ( 
        .clk (aclk ),
        .rst (aresetn),
        .Virt_Iaddr (Virt_Iaddr ),
        .Virt_Daddr (Virt_Daddr ),
        .MEM_LoadType (MEM_LoadType),
        .MEM_StoreType (MEM_StoreType),
        .IF_ExceptType(IF_ExceptType),
        .MEM_ExceptType(MEM_ExceptType),
        .MEM_IsTLBP (MEM_IsTLBP ),
        .MEM_IsTLBW (MEM_IsTLBW),
        .CMBus (CMBus.MMU ),
        //--------------------------output-----------------//
        .Phsy_Iaddr (Phsy_Iaddr ),
        .Phsy_Daddr  ( Phsy_Daddr),
        .I_IsCached  (I_IsCached),
        .D_IsCached  (D_IsCached),
        .I_IsTLBException (I_IsTLBException),
        .D_IsTLBException (D_IsTLBException),
        .IF_ExceptType_new(IF_ExceptType_new),
        .MEM_ExceptType_new(MEM_ExceptType_new)
    );
     logic [31:0]doutb;
     logic [31:0]dina;
     logic enb;
     always_ff @(posedge aclk) begin
         if (aresetn == `RstEnable) begin
             dina <= '0;
         end else begin
             dina <= dina+1;
         end
     end
    always_ff @(posedge aclk ) begin
        if (aresetn == `RstEnable) begin
            enb <= '0;
        end else begin
            enb <= ~enb;
        end
    end
    xpm_memory_sdpram #(
       .ADDR_WIDTH_A(6),               // DECIMAL
       .ADDR_WIDTH_B(6),               // DECIMAL
       .AUTO_SLEEP_TIME(0),            // DECIMAL
       .BYTE_WRITE_WIDTH_A(32),        // DECIMAL
       .CASCADE_HEIGHT(0),             // DECIMAL
       .CLOCKING_MODE("common_clock"), // String
       .ECC_MODE("no_ecc"),            // String
       .MEMORY_INIT_FILE("none"),      // String
       .MEMORY_INIT_PARAM("0"),        // String
       .MEMORY_OPTIMIZATION("true"),   // String
       .MEMORY_PRIMITIVE("block"),      // String
       .MEMORY_SIZE(2048),             // DECIMAL
       .MESSAGE_CONTROL(0),            // DECIMAL
       .READ_DATA_WIDTH_B(32),         // DECIMAL
       .READ_LATENCY_B(1),             // DECIMAL
       .READ_RESET_VALUE_B("0"),       // String
       .RST_MODE_A("SYNC"),            // String
       .RST_MODE_B("SYNC"),            // String
       .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       .USE_EMBEDDED_CONSTRAINT(0),    // DECIMAL
       .USE_MEM_INIT(1),               // DECIMAL
       .WAKEUP_TIME("disable_sleep"),  // String
       .WRITE_DATA_WIDTH_A(32),        // DECIMAL
       .WRITE_MODE_B("read_first")      // String
    )
   xpm_memory_sdpram_inst (
      .dbiterrb(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port B.

      .doutb(doutb),                   // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      .sbiterrb(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port B.

      .addra('0),                   // ADDR_WIDTH_A-bit input: Address for port A write operations.
      .addrb('0),                   // ADDR_WIDTH_B-bit input: Address for port B read operations.
      .clka(aclk),                     // 1-bit input: Clock signal for port A. Also clocks port B when
                                       // parameter CLOCKING_MODE is "common_clock".

      .clkb(aclk),                     // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                       // "independent_clock". Unused when parameter CLOCKING_MODE is
                                       // "common_clock".

      .dina(dina),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when write operations are initiated. Pipelined internally.

      .enb(enb),                       // 1-bit input: Memory enable signal for port B. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(), // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(), // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regceb(1'b0),                 // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rstb(~aresetn),                     // 1-bit input: Reset signal for the final port B output register stage.
                                       // Synchronously resets output port doutb to the value specified by
                                       // parameter READ_RESET_VALUE_B.

      .sleep('0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(1'b1)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

endmodule

