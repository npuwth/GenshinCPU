/*
 * @Author: npuwth
 * @Date: 2021-06-28 18:45:50
 * @LastEditTime: 2021-06-28 21:20:27
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

 `include "CPU_Defines.svh"
 `include "CommonDefines.svh"

 module mycpu (
         ext_int,
         
         aclk,   
         aresetn,
         
         arid,   
         araddr, 
         arlen,  
         arsize, 
         arburst,
         arlock, 
         arcache,
         arprot, 
         arvalid,
         arready,
                
         rid,    
         rdata,  
         rresp,  
         rlast,  
         rvalid, 
         rready, 
                
         awid,   
         awaddr, 
         awlen,  
         awsize, 
         awburst,
         awlock, 
         awcache,
         awprot, 
         awvalid,
         awready,
             
         wid,    
         wdata,  
         wstrb,  
         wlast,  
         wvalid, 
         wready, 
             
         bid,    
         bresp,  
         bvalid, 
         bready,

         debug_wb_pc,
         debug_wb_rf_wen,
         debug_wb_rf_wnum,
         debug_wb_rf_wdata
         

 );
    input  logic  [ 5:0] ext_int;
    input  logic         aclk;
    input  logic         aresetn;
    output logic  [ 3:0] arid;
    output logic  [31:0] araddr;
    output logic  [ 3:0] arlen;
    output logic  [ 2:0] arsize;
    output logic  [ 1:0] arburst;
    output logic  [ 1:0] arlock;
    output logic  [ 3:0] arcache;
    output logic  [ 2:0] arprot;
    output logic         arvalid;
    input  logic         arready;
    input  logic  [ 3:0] rid;
    input  logic  [31:0] rdata;
    input  logic  [ 1:0] rresp;
    input  logic         rlast;
    input  logic         rvalid;
    output logic         rready;
    output logic  [ 3:0] awid;
    output logic  [31:0] awaddr;
    output logic  [ 3:0] awlen;
    output logic  [ 2:0] awsize;
    output logic  [ 1:0] awburst;
    output logic  [ 1:0] awlock;
    output logic  [ 3:0] awcache;
    output logic  [ 2:0] awprot;
    output logic         awvalid;
    input  logic         awready;
    output logic  [ 3:0] wid;
    output logic  [31:0] wdata;
    output logic  [ 3:0] wstrb;
    output logic         wlast;
    output logic         wvalid;
    input  logic         wready;
    input  logic  [ 3:0] bid;
    input  logic  [ 1:0] bresp;
    input  logic         bvalid;
    output logic         bready;

    output [31:0]        debug_wb_pc;        // 写回级的PC
    output [31:0]        debug_wb_rf_wdata;  // 写回的数据
    output [3:0]         debug_wb_rf_wen;    // 写回级的写使能
    output [4:0]         debug_wb_rf_wnum;   // 写寄存器的地址

    assign Interrupt_o   =  {ext_int[0],ext_int[1],ext_int[2],ext_int[3],ext_int[4],ext_int[5]};  //硬件中断信号

    CPU_Bus_Interface cpu_ibus();
    CPU_Bus_Interface cpu_dbus();
    AXI_Bus_Interface axi_ibus();
    AXI_Bus_Interface axi_dbus();
    AXI_UNCACHE_Interface axi_ubus();

    WrFlushControl U_WRFlushControl (
    // input 
        // Flush 
        .IFID_Flush_Exception_o (IFID_Flush_Exception_o ),
        .IDEXE_Flush_Exception_o(IDEXE_Flush_Exception_o),
        .EXEMEM_Flush_Exception_o(EXEMEM_Flush_Exception_o),
        // Wr
        .DH_IF_PCWr_o(DH_IF_PCWr_o),
        .DH_IF_IDWr_o(DH_IF_IDWr_o),
        .IDEXE_Flush_DataHazard_o(IDEXE_Flush_DataHazard_o), // 以上三个是数据冒险的3个控制信号
        .DIVMULTBusy(EXE_MULTDIVStall),
        .IsExceptionorEret_o(IsExceptionorEret_o),
        .BranchFailed(IFID_Flush_BranchSolvement_o),
        .ID_IsAImmeJump(x.ID_IsAImmeJump),
        // .Icache_addr_ok(cpu_ibus.addr_ok),  // 1表示cache空闲 0表示cache miss
        .Icache_data_ok(cpu_ibus.data_ok),
        .Icache_busy(~cpu_ibus.addr_ok),  // addr_ok = 1表示cache空闲
        .Dcache_data_ok(cpu_dbus.data_ok),
        .Dcache_busy(~cpu_dbus.addr_ok),  // addr_ok = 1表示cache空闲
    // output
        .IF_PCWr(IF_PCWr),
        .IF_IDWr(IF_IDWr),
        .ID_EXEWr(ID_EXEWr),
        .EXE_MEMWr(EXE_MEMWr),
        .MEM_WBWr(MEM_WBWr),

        .IFID_Flush(IFID_Flush),
        .IDEXE_Flush(IDEXE_Flush),
        .EXEMEM_Flush(EXEMEM_Flush),
        .MEMWB_Flush(MEMWB_Flush),
        .MEMWB_DisWr(MEMWB_DisWr),
        .HiLo_Not_Flush(HiLo_Not_Flush),
        .IcacheFlush(cpu_ibus.flush),
        .DcacheFlush(cpu_dbus.flush)
    ); 

    // ICache U_ICache(
    //     //input
    //     .IF_PC(x.IF_PC),
    //     //output
    //     .IF_Instr(x.IF_Instr)
    // );
    // always@(posedge clk) begin
    // `ifdef DEBUG
    //     $monitor("PC=%8x ; Instr=%8x",x.IF_PC,x.IF_Instr);
    // `endif 
    
    // end
    /*********************************AXI模块接口的实例化**********************************/
    AXIInteract   AXIInteract_dut (
    .clk (aclk ),
    .resetn (aresetn ),
    .DcacheAXIBus (axi_dbus.slave ),
    .IcacheAXIBus (axi_ibus.slave ),
    .UncacheAXIBus(axi_ubus.slave) ,
    .m_axi_arid (arid ),
    .m_axi_araddr (araddr ),
    .m_axi_arlen (arlen ),
    .m_axi_arsize (arsize ),
    .m_axi_arburst (arburst ),
    .m_axi_arlock (arlock ),
    .m_axi_arcache (arcache ),
    .m_axi_arprot (arprot ),
    .m_axi_arvalid (arvalid ),
    .m_axi_arready (arready ),
    .m_axi_rid (rid ),
    .m_axi_rdata (rdata ),
    .m_axi_rresp (rresp ),
    .m_axi_rlast (rlast ),
    .m_axi_rvalid (rvalid ),
    .m_axi_rready (rready ),
    .m_axi_awid (awid ),
    .m_axi_awaddr (awaddr ),
    .m_axi_awlen (awlen ),
    .m_axi_awsize (awsize ),
    .m_axi_awburst (awburst ),
    .m_axi_awlock (awlock ),
    .m_axi_awcache (awcache ),
    .m_axi_awprot (awprot ),
    .m_axi_awvalid (awvalid ),
    .m_axi_awready (awready ),
    .m_axi_wid (wid ),
    .m_axi_wdata (wdata ),
    .m_axi_wstrb (wstrb ),
    .m_axi_wlast (wlast ),
    .m_axi_wvalid (wvalid ),
    .m_axi_wready (wready ),
    .m_axi_bid (bid ),
    .m_axi_bresp (bresp ),
    .m_axi_bvalid (bvalid ),
    .m_axi_bready  (bready)
  );

    
    /*********************************ICache的实例化**************************************/
    ICache U_ICache(
        .clk(aclk),
        .resetn(aresetn),
        .CPUBus(cpu_ibus.slave),
        .AXIBus(axi_ibus.master)
    );

    /**********************************   Icache接口支持   **********************************/
    assign x.IF_Instr     = cpu_ibus.rdata;
    assign {cpu_ibus.tag,cpu_ibus.index,cpu_ibus.offset}  = x.IF_NPC;    // 如果D$ busy 则将PC送给I$ ,否则送NPC
    assign cpu_ibus.valid = (IFID_Flush_Exception_o)?1'b1:(IDEXE_Flush_DataHazard_o || IF_IDWr == 1'b0)?1'b0:1'b1;
    assign cpu_ibus.op    = 1'b0;
    assign cpu_ibus.wstrb = 'x;
    assign cpu_ibus.wdata = 'x;
    assign cpu_ibus.ready = IF_IDWr;

    HILO U_HILO (
        .clk(aclk),
        .rst(aresetn),
        .MULT_DIV_finish(EXE_Finish & HiLo_Not_Flush),
        .HIWr(x.EXE_RegsWrType.HIWr & HiLo_Not_Flush), //把写HI，LO统一在EXE级
        .LOWr(x.EXE_RegsWrType.LOWr & HiLo_Not_Flush),
        .Data_i(EXE_OutA_o),
        .EXE_MULTDIVtoLO(EXE_MULTDIVtoLO),
        .EXE_MULTDIVtoHI(EXE_MULTDIVtoHI),
        .HI_o(HI_Bus_o),
        .LO_o(LO_Bus_o)
    );

    DataHazard U_DataHazard ( 
        //input
        .ID_rs(x.ID_rs),
        .ID_rt(x.ID_rt),
        .ID_rsrtRead(ID_rsrtRead_o),
        .EXE_rt(x.EXE_rt),
        .EXE_ReadMEM(x.EXE_LoadType.ReadMem),
        .EXE_isStore(x.EXE_StoreType.DMWr),
        .ID_isLoad(x.ID_LoadType.ReadMem),
        //output
        .IF_PCWr(DH_IF_PCWr_o),
        .IF_IDWr(DH_IF_IDWr_o),
        .IDEXE_Flush(IDEXE_Flush_DataHazard_o)
    );
    
    IF_ID_Interface     IIBus();
    ID_EXE_Interface    IEBus();
    EXE_MEM_Interface   EMBus();
    MEM_WB_Interface    MWBus();
    WB_CP0_Interface    WCBus();

    TOP_IF U_TOP_IF ( 
        .clk (clk ),
        .resetn (resetn ),
        .PC_Wr (PC_Wr ),
        .IIBus (IIBus.IF)
    );

    TOP_ID U_TOP_ID ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .ID_Flush (ID_Flush ),
        .ID_Wr (ID_Wr ),
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_RFWr (WB_RFWr ),
        .CP0_Bus (CP0_Bus ),
        .HI_Bus (HI_Bus ),
        .LO_Bus (LO_Bus ),
        .IIBus (IIBus.ID ),
        .IEBus (IEBus.ID ),
        .ID_rsrtRead  (ID_rsrtRead )
    );

    TOP_EXE U_TOP_EXE ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .EXE_Flush (EXE_Flush ),
        .EXE_Wr (EXE_Wr ),
        .WB_RegsWrType (WB_RegsWrType ),
        .WB_Dst (WB_Dst ),
        .WB_Result (WB_Result ),
        .HiLo_Not_Flush (HiLo_Not_Flush ),
        .IEBus (IEBus.EXE ),
        .EMBus (EMBus.EXE ),
        .IFID_Flush_BranchSolvement (IFID_Flush_BranchSolvement ),
        .EXE_Finish (EXE_Finish ),
        .EXE_MULTDIVStall  ( EXE_MULTDIVStall)
    );

    TOP_MEM U_TOP_MEM ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .MEM_Flush (MEM_Flush ),
        .MEM_Wr (MEM_Wr ),
        .CP0Status (CP0Status ),
        .CP0Cause (CP0Cause ),
        .CP0Epc (CP0Epc ),
        .EMBus (EMBus.MEM ),
        .MWBus (MWBus.MEM ),
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_Exception (EXE_Flush_Exception ),
        .MEM_Flush_Exception (MEM_Flush_Exception ),
        .IsExceptionOrEret (IsExceptionOrEret ),
        .Exception_CP0_EPC  ( Exception_CP0_EPC)
    );

    TOP_WB U_TOP_WB ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .WB_Flush (WB_Flush ),
        .MWBus (MWBus.WB ),
        .WCBus (WCBus.WB ),
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_RegsWrType (WB_RegsWrType ),
        .WB_Hi (WB_Hi ),
        .WB_Lo (WB_Lo )
    );



//---------------------------------------------seddon
    ForwardUnit U_ForwardUnit (
        .WB_RegsWrType(x.WB_RegsWrType),
        .MEM_RegsWrType(x.MEM_RegsWrType),
        .EXE_rt(x.EXE_rt),
        .EXE_rs(x.EXE_rs),
        .EXE_rd(x.EXE_rd),
        .MEM_Dst(x.MEM_Dst),
        .WB_Dst(x.WB_Dst),
        .EXE_RegsReadSel(x.EXE_RegsReadSel),
        .EXE_ForwardA(EXE_ForwardA_o),
        .EXE_ForwardB(EXE_ForwardB_o)//该模块已�?�?
    );

    BranchSolve U_BranchSolve(
        .EXE_BranchType(x.EXE_BranchType),     //新定义的信号，得在定义里面新�?
        .EXE_OutA(EXE_OutA_o),
        .EXE_OutB(EXE_OutB_o),//INPUT
        .IFID_Flush(IFID_Flush_BranchSolvement_o)//这个阻塞信号的线没有加，只是定义了一�?
    );

    //用于解决旁路ALUOut和OutB的问题
    assign MEM_Forward_data_sel = (x.MEM_WbSel == `WBSel_OutB)?1'b1:1'b0;

    MUX2to1 U_MUXINMEM ( //选择用于旁路的数据来自ALUOut还是OutB
        .d0(x.MEM_ALUOut),
        .d1(x.MEM_OutB),
        .sel2_to_1(MEM_Forward_data_sel),
        .y(MEM_Result_o)
    );

    MUX3to1 U_MUXA(
        .d0(x.EXE_BusA),
        .d1(MEM_Result_o),
        .d2(WB_Result_o),
        .sel3_to_1(EXE_ForwardA_o),
        .y(EXE_OutA_o)
    );//EXE级旁路
    
    MUX4to1 U_MUXB(
        .d0(x.EXE_BusB),
        .d1(MEM_Result_o),
        .d2(WB_Result_o),
        .sel4_to_1(EXE_ForwardB_o),
        .y(EXE_OutB_o)
    );//EXE级旁路

    MUX2to1 U_MUXSrcA(
        .d0(EXE_OutA_o),
        .d1({27'b0,x.EXE_Shamt}),
        .sel2_to_1(x.EXE_ALUSrcA),
        .y(EXE_ResultA_o)
    );//EXE级三选一A之后的那个二选一

    MUX2to1 U_MUXSrcB(
        .d0(EXE_OutB_o),
        .d1(x.EXE_Imm32),
        .sel2_to_1(x.EXE_ALUSrcB),//
        .y(EXE_ResultB_o)
    );//EXE级四选一B之后的那个二选一

    assign x.EXE_OutB = EXE_OutB_o;

    MUX3to1#(5) U_EXEDstSrc(
        .d0(x.EXE_rd),
        .d1(x.EXE_rt),
        .d2(5'd31),
        .sel3_to_1(x.EXE_DstSel),
        .y(x.EXE_Dst)
    );//EXE级Dst三�?�一
    
    ALU U_ALU(
        .EXE_ExceptType(x.EXE_ExceptType),//input
        .EXE_ResultA(EXE_ResultA_o),
        .EXE_ResultB(EXE_ResultB_o),
        .EXE_ALUOp(x.EXE_ALUOp),
        .EXE_ALUOut(x.EXE_ALUOut),         //output
        .EXE_ExceptType_new(EXE_ExceptType_new)
    );

        DCacheWen U_DCACHEWEN(
        .EXE_ALUOut(x.EXE_ALUOut),
        .EXE_StoreType(x.EXE_StoreType),
        .EXE_LoadType(x.EXE_LoadType),
        .EXE_ExceptType(EXE_ExceptType_new),
        
        .EXE_ExceptType_new(x.EXE_ExceptType_final),
        .cache_wen(cpu_dbus.wstrb)                   //给出dcache的写使能信号，
    );

    MULTDIV U_MULTDIV(
        .aclk(aclk),    
        .rst(aresetn),            
        .EXE_ResultA(EXE_ResultA_o),
        .EXE_ResultB(EXE_ResultB_o),
        .ExceptionAssert(~HiLo_Not_Flush),  // 如果产生flush信号，需要清除状态机
        .EXE_ALUOp(x.EXE_ALUOp),
        .EXE_MULTDIVtoLO(EXE_MULTDIVtoLO),
        .EXE_MULTDIVtoHI(EXE_MULTDIVtoHI),
        .EXE_Finish(EXE_Finish),
        .EXE_MULTDIVStall(EXE_MULTDIVStall)
    );
//---------------------------------------------seddonend
    

    PC U_PC(
        x.PC,
        aresetn
    );

    IFID_Reg U_IFID(
        x.IF_ID,
        aresetn
    );

    IDEXE_Reg U_IDEXE(
        x.ID_EXE,
        aresetn
    );

    EXEMEM_Reg U_EXEMEM(
        x.EXE_MEM,
        aresetn
    );

    MEMWB_Reg U_MEMWB(
        x.MEM_WB,
        aresetn
    );

    //TODO 如果拥堵 需要将整个的访存请求都变为MEM级前的流水线寄存器的
    assign cpu_dbus.wdata = x.EXE_OutB;
    assign cpu_dbus.valid = (MEM_WBWr== 1'b0)?1'b0:((x.EXE_LoadType.ReadMem || x.EXE_StoreType.DMWr )  ? 1 : 0);
    assign {cpu_dbus.tag,cpu_dbus.index,cpu_dbus.offset}  = x.EXE_ALUOut;                 // inst_sram_addr_o 虚拟地址
    assign cpu_dbus.op = (x.EXE_LoadType.ReadMem)? 1'b0
                         :(x.EXE_StoreType.DMWr) ? 1'b1
                         :1'bx;
    assign x.MEM_DMOut = cpu_dbus.rdata;       //读取结果直接放入DMOut
    assign cpu_dbus.ready = MEM_WBWr;
    assign cpu_dbus.storeType = x.EXE_StoreType;
    DCache U_DCACHE(
        .clk(aclk),
        .resetn(aresetn),
        .CPUBus(cpu_dbus.slave),
        .AXIBus(axi_dbus.master),
        .UBus(axi_ubus.master)
    );

    // // Ltype信号 & DMWr 写使能信号才会触发data_ram的使�?
    // DCache U_Dachce(
    //     // input
    //     .clk(clk),
    //     .MEM_ALUOut(x.MEM_ALUOut),
    //     .MEM_OutB(x.MEM_OutB),
    //     .MEM_StoreType(x.MEM_StoreType),
    //     .MEM_LoadType(x.MEM_LoadType),
    //     .MEM_ExceptType(x.MEM_ExceptType),
    //     // output
    //     .MEM_ExceptType_new(MEM_ExceptType_AfterDM_o),      //新的异常信号
    //     .data_sram_wen(data_sram_wen),                      //store类型，写入sram的字节使�?
    //     .MEM_SWData(MEM_SWData_o)                           //StoreType要写入的信号
    // 
    // );
    // /**********************************   SRAM接口支持   **********************************/
    // assign data_sram_en = (
    //     (x.EXE_LoadType.ReadMem || x.MEM_StoreType.DMWr )&&   // Ltype信号 & DMWr 写使能信号
    //     !MEM_ExceptType_AfterDM_o.WrWrongAddressinMEM &&      // WR地址正确 LOAD
    //     !MEM_ExceptType_AfterDM_o.RdWrongAddressinMEM         // RD地址正确 store
    //     )  ? 1 : 0; 
    // assign data_sram_wdata = MEM_SWData_o;                    //store类型写入sram的数据



    // assign data_sram_addr_o =  (data_sram_en & (|data_sram_wen)) ? //data_sram总使能为1&data_sram写使能为1 使用store地址，否则使用load地址 
    //                           x.MEM_ALUOut : (data_sram_en) ? //data_sram总使能为1&data_sram写使能为0 使用Load的地址
    //                           x.EXE_ALUOut : 32'bx;    

    Exception U_Exception(
        // input
        .clk(aclk),
        .rst(aresetn),
        .MEM_RegsWrType(x.MEM_RegsWrType),                //写信号输�?
        .ExceptType(x.MEM_ExceptType),            //将经过DM之后的异常信号做为输�?
        .IsDelaySlot(x.WB_IsABranch || x.WB_IsAImmeJump), //延迟槽（�?查WB级的isbranch信号�?
        .CurrentPC(x.MEM_PCAdd1 -4),
        //.CurrentInstr_i(x.MEM_Instr),                       //指令
        .CP0Status(CP0Status),
        .CP0Cause(CP0Cause),
        .CP0Epc(CP0Epc),
        .WB_CP0RegWr(x.WB_RegsWrType.CP0Wr),              //CP0写使能（用于旁路�?
        .WB_CP0RegWrAddr(x.WB_Dst),                       //CP0写地�?（用于旁路）
        .WB_CP0RegWrData(WB_Result_o),                    //CP0写结果（用于旁路�?
         // output
        .MEM_RegsWrType_o(x.MEM_RegsWrType_new),            //新的写信�?
        .IFID_Flush(IFID_Flush_Exception_o),                //flush
        .IDEXE_Flush(IDEXE_Flush_Exception_o),                        //flush
        .EXEMEM_Flush(EXEMEM_Flush_Exception_o),                      //flush                      
        .IsExceptionorEret(IsExceptionorEret_o),            //传�?�给PCSEL信号
        .ExceptType(x.MEM_ExceptType_final),              //�?终的异常类型
        .IsDelaySlot(x.MEM_IsDelaySlot),                  //访存阶段指令是否是延迟槽指令
        .CP0Epc(MEM_CP0Epc_o)                               //CP0中EPC寄存器的�?新�??
    );
// WB�?   
    EXT2 U_EXT2(
        .WB_DMOut_i(x.WB_DMOut),
        .WB_ALUOut_i(x.WB_ALUOut),
        .WB_LoadType_i(x.WB_LoadType),
        .WB_DMResult_o(WB_DMResult_o)
    );

    MUX4to1 #(32) U_MUXINWB(
        .d0(x.WB_PCAdd1+4),                                 // JAL,JALR等指�? 将PC+8写回RF
        .d1(x.WB_ALUOut),                                   // ALU计算结果
        .d2(x.WB_OutB),                                     // MTC0 MTHI LO等指令需要写寄存器数�?
        .d3(WB_DMResult_o),                                 // DM结果
        .sel4_to_1(x.WB_WbSel),
        .y(WB_Result_o)                                     // �?终写回结�?
    );
    cp0_reg U_CP0(
        //input
        .rst(aresetn),
        .clk(aclk),
        .CP0Wr(WB_Final_Wr.CP0Wr),                    //写使�?
        .CP0WrAddr(x.WB_Dst),                             //写回地址
        .CP0WrDataOut(WB_Result_o),                       //写入数据
        .CP0RdAddr(x.ID_Instr[15:11]),
        .ExceptType(x.WB_ExceptType),                     //异常
        .Interrupt(Interrupt_o),                          //在调试时assign了全零的�?
        .PC(x.WB_PCAdd1),                             //PC+1
        .IsDelaySlot(x.WB_IsDelaySlot),                   //是否延迟�?
        .VirtualAddr(x.WB_ALUOut),                        //读取&写入地址未对齐例�? 访问的虚拟地�?

        // output        
        .CP0RdDataOut(ID_CP0DataOut_o),
        .CP0BadVAddr(CP0BadVAddr),
        .CP0Count(CP0Count),
        .CP0Compare(CP0Compare),
        .CP0Status(CP0Status),
        .CP0Cause(CP0Cause),
        .CP0EPC(CP0Epc),
        .CP0TimerInterrupt(TimerInterrupt_o)              //定时器中�?
        );
    assign WB_Final_Wr = (MEMWB_DisWr)? '0: x.WB_RegsWrType ;  // Dcache 停滞流水线时 wb级数据不能写入RF
    /**********************************   SRAM接口支持   **********************************/
    assign debug_wb_pc = x.WB_PCAdd1-4;                     //写回级的PC,应该是减4
    assign debug_wb_rf_wdata = WB_Result_o;                 //写回�?32位结�?
    assign debug_wb_rf_wen = (WB_Final_Wr.RFWr) ? 4'b1111 : 4'b0000; //4位字节写使能
    assign debug_wb_rf_wnum = x.WB_Dst;                     //写地�?


endmodule

