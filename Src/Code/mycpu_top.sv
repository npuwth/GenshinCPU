/*
 * @Author: Juan Jiang
 * @Date: 2021-04-05 20:20:45
 * @LastEditTime: 2021-04-10 18:15:13
 * @LastEditors: Seddon Shen
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 
 `include "CPU_Defines.svh"

 module mycpu_top(
        clk, resetn, ext_int, 

         inst_sram_rdata,
         data_sram_rdata,

         inst_sram_en,
         inst_sram_wen,
         inst_sram_addr,
         inst_sram_wdata,
         

         data_sram_en,
         data_sram_wen,
         data_sram_addr,
         data_sram_wdata,

         debug_wb_pc,
         debug_wb_rf_wen,
         debug_wb_rf_wnum,
         debug_wb_rf_wdata

 );
   input                clk;
   input                resetn;
   input [5:0]          ext_int;               // 6个硬件中断输入
   input [31:0]         inst_sram_rdata;    // icache读数据
   input [31:0]         data_sram_rdata;    // dcache读数据

   output               inst_sram_en;       // 写使能
   output [3:0]         inst_sram_wen;      // 字节写使能
   output [31:0]        inst_sram_addr;     // 读写地址，字节寻址
   output [31:0]        inst_sram_wdata;    // ram写数据

   output               data_sram_en;       // 写使能
   output [3:0]         data_sram_wen;      // 字节写使能
   output [31:0]        data_sram_addr;     // 读写地址，字节寻址
   output [31:0]        data_sram_wdata;    // ram写数据

   output [31:0]        debug_wb_pc;        // 写回级的PC
   output [31:0]        debug_wb_rf_wdata;  // 写回的数据
   output [3:0]         debug_wb_rf_wen;    // 写回级的写使能
   output [4:0]         debug_wb_rf_wnum;   // 写寄存器的地址（序号）

    logic rst;
    logic [1:0]         isExceptorERET_o;
    logic [2:0]         PCSel_o;

    logic [31:0]        JumpAddr_o;//PCSel多选器
    logic [31:0]        BranchAddr_o;
    logic [31:0]        PC_4_o;
    //logic [31:0]        EPCData_o;

    logic [1:0]         ID_RegsReadSel_o;//由译码产生 作用于ID级别的读取数据
    logic [1:0]         ID_EXTOp_o;
    logic [1:0]         ID_rsrtRead_o;

    logic [31:0]        RF_Bus_o;
    logic [31:0]        HI_Bus_o;
    logic [31:0]        LO_Bus_o;

    //所有与流水线寄存器相关的信号，数据都是x.  *_o后缀的都是其他的一些信号（至少它与流水线寄存器无关，）
// *******************************Johnson Yang & WTH **********/

    ExceptinPipeType    MEM_ExceptType_AfterDM_o; 
    logic               IFID_Flush_Exception_o; 
    logic [1:0]         IsExceptionorEret_o;      //送给PCSEL
    logic               MEM_IsDelaySlot_o;        //访存阶段是否是延迟槽（送给CP0）
    logic [31:0]        MEM_CP0Epc_o;             //送给PC的MUX做为被选择的数据信号
    AsynExceptType      Interrupt_o;              //6个外部硬件中断输入
    logic               CP0TimerInterrupt_o;      //定时器中断
    logic [31:0]        MEM_SWData_o;             //Store类型写入data_sram写数据
    //CP0寄存器的定义
    logic [31:0]        CP0BadVAddr;              //8号寄存器  BadVAddr寄存器的值:最新地址相关例外的出错地址
    logic [31:0]        CP0Count;                 //9号寄存器  Count寄存器的值
    logic [31:0]        CP0Compare;               //11号寄存器 Compare寄存器的值
    logic [31:0]        CP0Status;                //12号寄存器 Status寄存器的值
    logic [31:0]        CP0Cause;                 //13号寄存器 Cause寄存器的值
    logic [31:0]        CP0Epc;                   //14号寄存器 EPC寄存器的值
//---------------------------------------------seddon
    logic [1:0]         EXE_ForwardA_o,EXE_ForwardB_o; 
    logic [31:0]        EXE_OutA_o,EXE_OutB_o;
    logic               IFID_Flush_BranchSolvement_o;
    logic [31:0]        WB_Result_o;
    logic [31:0]        EXE_ResultA_o,EXE_ResultB_o;
//------------------------seddonend

    logic [31:0]        ID_CP0DataOut_o;

    assign Interrupt_o =  {ext_int[0],ext_int[1],ext_int[2],ext_int[3],ext_int[4],ext_int[5]};  //硬件中断信号
    assign rst       =  ~resetn;                         //高电平有效的复位信号
    assign x.IFID_Flush = IFID_Flush_Exception_o | 
                          IFID_Flush_BranchSolvement_o;  // 在branch solvement级和 exception级 都会产生IFID_Flush信号


    PipeLineRegsInterface x(
        //input
        .clk(clk),
        .rst(rst)
    );

    MUX8to1 U_PCMUX(
        //input
        .d0(PC_4_o),
        .d1(JumpAddr_o),
        .d2(MEM_CP0Epc_o),
        .d3(32'hBFC00380),
        .d4(BranchAddr_o),
        .sel8_to_1(PCSel_o),
        //output
        .y(x.IF_NPC)
    );
    assign PC_4_o = x.IF_PC + 4;

    assign JumpAddr_o = {x.ID_PCAdd1[31:28],x.ID_Instr[25:0],2'b0};

    assign BranchAddr_o = x.EXE_PCAdd1+{x.EXE_Imm32[29:0],2'b0};

    PCSEL U_PCSEL(
        //input
        .isBranch(IFID_Flush_BranchSolvement_o),//
        .isImmeJump(x.ID_IsAImmeJump),
        .isExceptorERET(isExceptorERET_o),
        //output
        .PCSel(PCSel_o)
    );


    // ICache U_ICache(
    //     //input
    //     .IF_PC(x.IF_PC),
    //     //output
    //     .IF_Instr(x.IF_Instr)
    // );
    always@(posedge clk) begin
    `ifdef DEBUG
        $monitor("PC=%8x ; Instr=%8x",x.IF_PC,x.IF_Instr);
    `endif 
    end

    /**********************************   SRAM接口支持   **********************************/
    assign x.IF_Instr      = inst_sram_rdata;
    assign inst_sram_addr  = x.IF_PC;                // TODO: 可能需要限制地址？
    assign inst_sram_en    = resetn ? x.IF_PCWr : 0; //resten高电平 & IF_PCWr为1 读取数据
    assign inst_sram_wen   = 4'b0000;
    assign inst_sram_wdata = 32'b0;
   
   // TODO: 目前没有加入取指地址异常的检测

    Control U_Control(
        //input
        .ID_Instr(x.ID_Instr),
        //output
        .ID_ALUOp(x.ID_ALUOp),
        .ID_LoadType(x.ID_LoadType),
        .ID_StoreType(x.ID_StoreType),
        .ID_RegsWrType(x.ID_RegsWrType),
        .ID_WbSel(x.ID_WbSel),
        .ID_DstSel(x.ID_DstSel),
        .ID_ExceptType(x.ID_ExceptType),
        .ID_ALUSrcA(x.ID_ALUSrcA),
        .ID_ALUSrcB(x.ID_ALUSrcB),
        .ID_RegsReadSel(ID_RegsReadSel_o),
        .ID_EXTOp(ID_EXTOp_o),
        .ID_isImmeJump(x.ID_IsAImmeJump),
        .ID_BranchType(x.ID_BranchType),
        .ID_shamt(x.ID_shamt),
        .ID_rsrtRead(ID_rsrtRead_o)
    );

    RF U_RF (
        .clk(clk),
        .rst(rst),
        .WB_Dst(x.WB_Dst),
        .WB_Result(WB_Result_o),
        .RFWr(x.WB_RegsWrType.RFWr),
        .ID_rs(x.ID_rs),
        .ID_rt(x.ID_rt),
        .ID_BusA(x.ID_BusA),
        .ID_BusB(RF_Bus_o)
    );

    HILO U_HILO (
        .clk(clk),
        .rst(rst),
        .HIWr(x.WB_RegsWrType.HIWr),
        .LOWr(x.WB_RegsWrType.LOWr),
        .Data_i(x.WB_OutB),
        .HI_o(HI_Bus_o),
        .LO_o(LO_Bus_o)
    );

    MUX4to1 U_MUXBUSB ( 
        .d0(RF_Bus_o),
        .d1(HI_Bus_o),
        .d2(LO_Bus_o),
        .d3(ID_CP0DataOut_o),
        .sel4_to_1(ID_RegsReadSel_o),
        .y(x.ID_BusB)
    );

    DataHazard U_DataHazard ( 
        .ID_rs(x.ID_rs),
        .ID_rt(x.ID_rt),
        .ID_rsrtRead(ID_rsrtRead_o),
        .EXE_rt(x.EXE_rt),
        .EXE_ReadMEM(x.EXE_LoadType.ReadMem),
        .IF_PCWr(x.IF_PCWr),
        .IF_IDWr(x.IF_IDWr)
    );
    
//---------------------------------------------seddon
    ForwardUnit U_ForwardUnit (
        .WB_RegsWrType(x.WB_RegsWrType),
        .MEM_RegsWrType(x.MEM_RegsWrType),
        .EXE_rt(x.EXE_rt),
        .EXE_rs(x.EXE_rs),
        .MEM_Dst(x.MEM_Dst),
        .WB_Dst(x.WB_Dst),
        .EXE_ForwardA(EXE_ForwardA_o),
        .EXE_ForwardB(EXE_ForwardB_o)//该模块已检查
    );

    BranchSolve U_BranchSolve(
        .EXE_BranchType(x.EXE_BranchType),     //新定义的信号，得在定义里面新加
        .EXE_OutA(EXE_OutA_o),
        .EXE_OutB(EXE_OutB_o),//INPUT
        .IFID_Flush(IFID_Flush_BranchSolvement_o)//这个阻塞信号的线没有加，只是定义了一个
    );
    
    MUX3to1 U_MUXA(
        .d0(x.EXE_BusA),
        .d1(x.MEM_ALUOut),
        .d2(WB_Result_o),
        .sel3_to_1(EXE_ForwardA_o),
        .y(EXE_OutA_o)
    );//EXE级组合逻辑三选一A
    
    MUX3to1 U_MUXB(
        .d0(x.EXE_BusB),
        .d1(x.MEM_ALUOut),
        .d2(WB_Result_o),
        .sel3_to_1(EXE_ForwardB_o),
        .y(EXE_OutB_o)
    );//EXE级组合逻辑三选一B

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
    );//EXE级三选一B之后的那个二选一

    MUX3to1 U_EXEDstSrc(
        .d0(x.EXE_rd),
        .d1(x.EXE_rt),
        .d2(32'd31),
        .sel3_to_1(x.EXE_DstSel),
        .y(x.EXE_Dst)
    );//EXE级Dst三选一
    
    ALU U_ALU(
        .EXE_ExceptType(x.EXE_ExceptType),
        .EXE_ResultA(EXE_ResultA_o),
        .EXE_ResultB(EXE_ResultB_o),
        .EXE_ALUOp(x.EXE_ALUOp),
        .EXE_ALUOut(x.EXE_ALUOut),
        .EXE_ExceptType_new(x.EXE_ExceptType_final)//input
    );
//---------------------------------------------seddonend
    

    PC U_PC(
        x
    );

    IFID_Reg U_IFID(
        x
    );

    IDEXE_Reg U_IDEXE(
        x
    );

    EXEMEM_Reg U_EXEMEM(
        x
    );

    MEMWB_Reg U_MEMWB(
        x
    );

    // Ltype信号 & DMWr 写使能信号才会触发data_ram的使能
    DCache U_Dachce(
        // input
        .clk(clk),
        .MEM_ALUOut(x.MEM_ALUOut),
        .MEM_OutB(x.MEM_OutB),
        .MEM_StoreType(x.MEM_StoreType),
        .MEM_LoadType(x.MEM_LoadType),
        .MEM_ExceptType(x.MEM_ExceptType),
        // output
        .MEM_ExceptType_new(MEM_ExceptType_AfterDM_o),      //新的异常信号
        .data_sram_wen(data_sram_wen),                      //store类型，写入sram的字节使能
        .MEM_SWData(MEM_SWData_o)                           //StoreType要写入的信号

    );
    /**********************************   SRAM接口支持   **********************************/
    assign data_sram_en = (
        (x.MEM_LoadType.ReadMem || x.MEM_StoreType.DMWr )&&   // Ltype信号 & DMWr 写使能信号
        !MEM_ExceptType_AfterDM_o.WrWrongAddressinMEM &&    // WR地址正确
        !MEM_ExceptType_AfterDM_o.RdWrongAddressinMEM       // RD地址正确
        )  ? 1 : 0;
    assign data_sram_wdata = MEM_SWData_o;                  //store类型写入sram的数据
    assign data_sram_addr = x.MEM_ALUOut;                   //data_sram写入，输出数据地址 TODO: 对地址上限作出限制
    assign x.MEM_DMOut = data_sram_rdata;                   //读取结果直接放入DMOut

    Exception U_Exception(
        // input
        .clk(x.clk),
        .rst(x.rst),
        .MEM_RegsWrType_i(x.MEM_RegsWrType),                //写信号输入
        .ExceptType_i(MEM_ExceptType_AfterDM_o),            //将经过DM之后的异常信号做为输入
        .IsDelaySlot_i(x.WB_IsABranch || x.WB_IsAImmeJump),                     //延迟槽（检查WB级的isbranch信号）
        .CurrentInstr_i(x.MEM_Instr),                       //指令
        .CP0Status_i(CP0Status),
        .CP0Cause_i(CP0Cause),
        .CP0Epc_i(CP0Epc),
        .WB_CP0RegWr_i(x.WB_RegsWrType.CP0Wr),              //CP0写使能（用于旁路）
        .WB_CP0RegWrAddr_i(x.WB_Dst),                       //CP0写地址（用于旁路）
        .WB_CP0RegWrData_i(WB_Result_o),                    //CP0写结果（用于旁路）
         // output
        .MEM_RegsWrType_o(x.MEM_RegsWrType_new),            //新的写信号
        .IFID_Flush(IFID_Flush_Exception_o),                //flush
        .IDEXE_Flush(x.IDEXE_Flush),                        //flush
        .EXEMEM_Flush(x.EXEMEM_Flush),                      //flush                      
        .IsExceptionorEret(IsExceptionorEret_o),            //传递给PCSEL信号
        .ExceptType_o(x.MEM_ExceptType_final),              //最终的异常类型
        .IsDelaySlot_o(x.MEM_IsDelaySlot),                  //访存阶段指令是否是延迟槽指令
        .CP0Epc_o(MEM_CP0Epc_o)                               //CP0中EPC寄存器的最新值
    );
// WB级   
    EXT2 U_EXT2(
        .WB_DMOut_i(x.WB_DMOut),
        .WB_ALUOut_i(x.WB_ALUOut),
        .WB_LoadType_i(x.WB_LoadType),
        .WB_DMResult_o(WB_DMResult_o)
    );

    MUX4to1 #(32) U_MUXINWB(
        .d0(x.WB_PCAdd1),                                   // JAL,JALR等指令 将PC写回RF
        .d1(x.WB_ALUOut),                                   // ALU计算结果
        .d2(x.WB_OutB),                                     // MTC0 MTHI LO等指令需要写寄存器数据
        .d3(WB_DMResult_o),                                 // DM结果
        .sel4_to_1(x.WB_WbSel),
        .y(WB_Result_o)                                     // 最终写回结果
    );
    cp0_reg U_CP0(
        //input
        .rst(x.rst),
        .clk(x.clk),
        .CP0Wr_i(x.WB_RegsWrType.CP0Wr),                    //写使能
        .CP0WrAddr_i(x.WB_Dst),                             //写回地址
        .CP0WrDataOut_i(WB_Result_o),                       //写入数据
        .CP0RdAddr_i(x.ID_Instr[15:11]),
        .ExceptType_i(x.WB_ExceptType),                     //异常
        .Interrupt_i(Interrupt_o),                          //在调试时assign了全零的值
        .PCAdd1_i(x.WB_PCAdd1),                             //PC+1
        .IsDelaySlot_i(x.WB_IsDelaySlot),                   //是否延迟槽
        .VirtualAddr_i(x.WB_ALUOut),                        //读取&写入地址未对齐例外 访问的虚拟地址

        // output        
        .CP0RdDataOut_o(ID_CP0DataOut_o),
        .CP0BadVAddr_o(CP0BadVAddr),
        .CP0Count_o(CP0Count),
        .CP0Compare_o(CP0Compare),
        .CP0Status_o(CP0Status),
        .CP0Cause_o(CP0Cause),
        .CP0EPC_o(CP0EPC),
        .CP0TimerInterrupt_o(TimerInterrupt_o)              //定时器中断
        );

    /**********************************   SRAM接口支持   **********************************/
    assign debug_wb_pc = x.WB_PCAdd1-4;                     //写回级的PC,应该是减4
    assign debug_wb_rf_wdata = WB_Result_o;                 //写回的32位结果
    assign debug_wb_rf_wen = (x.WB_RegsWrType.RFWr) ? 4'b1111 : 4'b0000; //4位字节写使能
    assign debug_wb_rf_wnum = x.WB_Dst;                     //写地址


 

 endmodule

