
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
`include "../Cache_Defines.svh"

module TOP_MEM (
    input logic                  clk,
    input logic                  resetn,
    input logic                  MEM2_Flush,
    input logic                  MEM2_Wr,
    MEM_MEM2_Interface           MM2Bus,
    MEM2_WB_Interface            M2WBus,
    CPU_Bus_Interface            cpu_dbus,
    //--------------------output--------------------//
    output logic [31:0]          MEM2_Result,
    output logic [4:0]           MEM2_Dst,
    output RegsWrType            MEM2_RegsWrType
);
    logic                        MEM2_Forward_data_sel;
    MEM2_Reg U_MEM2_REG(
    .clk                    (clk ),
    .rst                    (resetn ),
    .MEM2_Flush             (MEM2_Flush ),
    .MEM2_Wr                (MEM2_Wr ),
    .MEM_ALUOut             (MM2Bus.MEM_ALUOut ),
    .MEM_PC                 (MM2Bus.MEM_PC ),
    .MEM_Instr              (MM2Bus.MEM_Instr ),
    .MEM_WbSel              (MM2Bus.MEM_WbSel ),
    .MEM_Dst                (MM2Bus.MEM_Dst ),
    .MEM_LoadType           (MM2Bus.MEM_LoadType ),
    .MEM_OutB               (MM2Bus.MEM_OutB ),
    .MEM_RegsWrType_final   (MM2Bus.MEM_RegsWrType_final ),
    .MEM_ExceptType_final   (MM2Bus.MEM_ExceptType_final ),
    .MEM_IsABranch          (MM2Bus.MEM_IsABranch ),
    .MEM_IsAImmeJump        (MM2Bus.MEM_IsAImmeJump ),
    .MEM_IsInDelaySlot      (MM2Bus.MEM_IsInDelaySlot ),
//-----------------------------output-------------------------------------//
    .MEM2_ALUOut            (M2WBus.MEM2_ALUOut ),
    .MEM2_PC                (M2WBus.MEM2_PC ),
    .MEM2_Instr             (M2WBus.MEM2_Instr ),
    .MEM2_WbSel             (M2WBus.MEM2_WbSel ),
    .MEM2_Dst               (M2WBus.MEM2_Dst ),
    .MEM2_LoadType          (M2WBus.MEM2_LoadType ),
    .MEM2_OutB              (M2WBus.MEM2_OutB ),
    .MEM2_RegsWrType        (M2WBus.MEM2_RegsWrType ),
    .MEM2_ExceptType        (M2WBus.MEM2_ExceptType ),

    .MEM2_IsABranch         (MM2Bus.MEM2_IsABranch ),
    .MEM2_IsAImmeJump       (MM2Bus.MEM2_IsAImmeJump ),
    .MEM2_IsInDelaySlot     (MM2Bus.MEM2_IsInDelaySlot)

    // .MEM2_Reuslt            (MEM2_Result)
    );
    //output for forwarding 
    assign MEM2_Dst              = M2WBus.MEM2_Dst;
    assign MEM2_RegsWrType       = M2WBus.MEM2_RegsWrType;
    // output to MEM
    assign MM2Bus.MEM2_ALUOut    = M2WBus.MEM2_ALUOut;
    assign MM2Bus.MEM2_PC        = M2WBus.MEM2_PC;
    assign MM2Bus.MEM2_ExceptType= M2WBus.MEM2_ExceptType;
    // output to WB
    assign M2WBus.MEM_DMOut      = cpu_dbus.rdata;       //读取结果直接放入DMOut


    
    MUX4to1 #(32) U_MUXINWB(
        .d0                  (M2WBus.MEM2_PC + 8),                                     // JAL,JALR等指令将PC+8写回RF
        .d1                  (M2WBus.MEM2_ALUOut),                                   // ALU计算结果
        .d2                  (M2WBus.MEM2_OutB  ),                                     // MTC0 MTHI LO等指令需要写寄存器
        .d3                  ('x                ),                               
        .sel4_to_1           (M2WBus.MEM2_WbSel ),
        .y                   (MEM2_Result)                                    
    );
    // assign MEM2_Forward_data_sel= (MM2Bus.MEM2_WbSel == `WBSel_PCAdd1)?1'b0:1'b1;

    // MUX2to1 U_MUXINMEM ( //选择用于旁路的数据来自ALUOut还是OutB
    //     .d0                      (MM2Bus.MEM2_PC + 8),
    //     .d1                      (M2WBus.MEM2_Result),
    //     .sel2_to_1               (MEM2_Forward_data_sel),
    //     .y                       (MEM2_Result)
    // );

    // assign M2WBus.MEM2_ALUOut     = MM2Bus.MEM2_ALUOut;
    // assign M2WBus.MEM2_PC		  = MM2Bus.MEM2_PC;
    // assign M2WBus.MEM2_Instr 	  = MM2Bus.MEM2_Instr;
    // assign M2WBus.MEM2_WbSel      = MM2Bus.MEM2_WbSel;
    // assign M2WBus.MEM2_Dst        = MM2Bus.MEM2_Dst;
    // assign M2WBus.MEM2_LoadType   = MM2Bus.MEM2_LoadType;
    // assign M2WBus.MEM2_OutB       = MM2Bus.MEM2_OutB;
    // assign M2WBus.MEM2_RegsWrType = MM2Bus.MEM2_RegsWrType;
    // assign M2WBus.MEM2_ExceptType = MM2Bus.MEM2_ExceptType;
endmodule

