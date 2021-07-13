/*
 * @Author: Johnson Yang
 * @Date: 2021-07-12 18:10:55
 * @LastEditTime: 2021-07-13 15:36:14
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_PREIF ( 
    input logic                 clk,
    input logic                 resetn,
    input logic                 PREIF_Wr,

    input logic [31:0]          MEM_CP0Epc,
    input logic [31:0]          EXE_BusA_L1,
    input logic                 ID_Flush_BranchSolvement,
    input logic                 ID_IsAImmeJump,
    input logic [2:0]           EX_Entry_Sel,
    input BranchType            EXE_BranchType,
    input logic [31:0]          ID_PC,
    input logic [31:0]          ID_Instr,
    input logic [31:0]          EXE_PC,
    input logic [31:0]          EXE_Imm32,
    input logic [31:0]          Phsy_Iaddr,
    input logic                 I_IsCached,
    input logic [31:0]          MEM_PC,
    input logic [31:0]          Exception_Vector,
    CPU_Bus_Interface           cpu_ibus,
    AXI_Bus_Interface           axi_ibus,
//---------------------------output----------------------------------//
    output logic [31:0]         Virt_Iaddr,          //  输出给TLB
    output logic [31:0]         PREIF_PC,            //  输出到下一级
    output ExceptinPipeType     PREIF_ExceptType     //  输出给TLB 
);

    logic   [31:0]              PREIF_NPC;
    logic   [2:0]               PCSel;
    logic   [31:0]              ID_PCAdd4;
    logic   [31:0]              PC_4;
    logic   [31:0]              JumpAddr;
    logic   [31:0]              BranchAddr;

    assign PC_4              =   PREIF_PC + 4;
    assign ID_PCAdd4         =   ID_PC+4;
    assign JumpAddr          =   {ID_PCAdd4[31:28],ID_Instr[25:0],2'b0};
    assign BranchAddr        =   EXE_PC+4+{EXE_Imm32[29:0],2'b0};

    assign PREIF_ExceptType  =   '0;   //  输出给TLB 

    PC U_PC ( 
        .clk            (clk),
        .rst            (resetn),
        .PREIF_Wr       (PREIF_Wr),
        .PREIF_NPC      (PREIF_NPC),
        //---------------output----------------//
        .PREIF_PC       (PREIF_PC)
    );

    MUX8to1 U_PCMUX (
        .d0             (PC_4),
        .d1             (JumpAddr),
        .d2             (MEM_CP0Epc),
        .d3             (Exception_Vector),    // 异常处理的地址
        .d4             (BranchAddr),
        .d5             (EXE_BusA_L1),         // JR
        .d6             (MEM_PC),
        .sel8_to_1      (PCSel),
        //---------------output----------------//
        .y              (PREIF_NPC)
    );

    PCSEL U_PCSEL(
        .isBranch       (ID_Flush_BranchSolvement),
        .isImmeJump     (ID_IsAImmeJump),
        .EX_Entry_Sel   (EX_Entry_Sel),
        .EXE_BranchType (EXE_BranchType),
        //---------------output-------------------//
        .PCSel          (PCSel)
    );

    //---------------------------------cache--------------------------------//
    // assign IIBus.IF_Instr = cpu_ibus.rdata;  
    assign {cpu_ibus.tag,cpu_ibus.index,cpu_ibus.offset} = PREIF_PC;    // 如果D$ busy 则将PC送给I$ ,否则送NPC
    assign cpu_ibus.valid     = 1'b1;   // TODO:  Valid位需要控制
    assign cpu_ibus.op        = 1'b0;
    assign cpu_ibus.wstrb     = '0;
    assign cpu_ibus.wdata     = 'x;
    assign cpu_ibus.storeType = '0;
    assign Virt_Iaddr         = PREIF_PC;
    
    // ICache U_ICache(   // TODO: cache的接口没确定
    //     .clk            (clk),
    //     .resetn         (resetn),  
    //     .Phsy_Iaddr     (Phsy_Iaddr),
    //     .I_IsCached     (I_IsCached),
    //     .PREIF_Wr       (PREIF_Wr),
    //     .CPUBus         (cpu_ibus.slave),
    //     .AXIBus         (axi_ibus.master),
    //     .Virt_Iaddr     (Virt_Iaddr)
    // );

endmodule