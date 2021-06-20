/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-20 16:45:42
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_MEM (
    input logic            clk,
    input logic            resetn,
    input logic            MEM_Flush,
    input logic            MEM_Wr,
    input logic  [31:0]    CP0Status,
    input logic  [31:0]    CP0Cause,
    input logic  [31:0]    CP0Epc,
    EXE_MEM_Interface      EMBus,
    MEM_WB_Interface       MWBus,
    output logic           ID_Flush_Exception,
    output logic           EXE_Flush_Exception,
    output logic           MEM_Flush_Exception,
    output logic           IsExceptionOrEret,
    output logic [31:0]    Exception_CP0_EPC,
    output logic [4:0]     MEM_Dst,                 //用于MEM级旁路的地址
    output logic [31:0]    MEM_Result               //用于MEM级旁路的数据
);

	StoreType     		   MEM_StoreType;
	RegsWrType             MEM_RegsWrType;
	ExceptinPipeType 	   MEM_ExceptType_AfterDM;
    
    //表示当前指令是否在延迟槽中，通过判断上一条指令是否是branch或jump实现
    assign MWBus.IsInDelaySlot = MWBus.WB_IsABranch || MWBus.WB_IsAImmeJump; 

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
        .EXE_Hi                  (EMBus.EXE_Hi ),
        .EXE_Lo                  (EMBus.EXE_Lo ),
    //------------------------out--------------------------------------------------//
        .MEM_ALUOut              (MWBus.MEM_ALUOut ),
        .MEM_OutB                (MWBus.MEM_OutB ),
        .MEM_PC                  (MWBus.MEM_PC ),
        .MEM_Instr               (MWBus.MEM_Instr ),
        .MEM_IsABranch           (MWBus.MEM_IsABranch ),
        .MEM_IsAImmeJump         (MWBus.MEM_IsAImmeJump ),
        .MEM_LoadType            (MWBus.MEM_LoadType ),
        .MEM_StoreType           (MEM_StoreType),
        .MEM_Dst                 (MWBus.MEM_Dst ),
        .MEM_RegsWrType          (MEM_RegsWrType ),
        .MEM_WbSel               (MWBus.MEM_WbSel ),
        .MEM_ExceptType          (MEM_ExceptType ),
        .MEM_Hi                  (MWBus.MEM_Hi ),
        .MEM_Lo                  (MWBus.MEM_Lo )
    );

    Exception U_Exception(
        .clk                     (clk),
        .rst                     (resetn),
        .MEM_RegsWrType_i        (MEM_RegsWrType),              
        .ExceptType_i            (MEM_ExceptType),            
        .CurrentPC_i             (MWBus.MEM_PC),                     
        .CP0Status_i             (CP0Status),
        .CP0Cause_i              (CP0Cause),
        .CP0Epc_i                (CP0Epc),
        .WB_CP0RegWr_i           (MWBus.WB_RegsWrType.CP0Wr),             
        .WB_CP0RegWrAddr_i       (MWBus.WB_Dst),                     
        .WB_CP0RegWrData_i       (MWBus.WB_Result),                    
    //------------------------------out--------------------------------------------//
        .MEM_RegsWrType_o        (MWBus.MEM_RegsWrType_final),            
        .IFID_Flush              (ID_Flush_Exception),                
        .IDEXE_Flush             (EXE_Flush_Exception),                       
        .EXEMEM_Flush            (MEM_Flush_Exception),                           
        .IsExceptionorEret       (IsExceptionOrEret),            
        .ExceptType_o            (MWBus.MEM_ExceptType_final),          
        .CP0Epc_o                (Exception_CP0_EPC)                        
    );
    
    //------------------------------用于旁路的多选器-------------------------------//
    assign MEM_Forward_data_sel= (MWBus.MEM_WbSel == `WBSel_OutB)?1'b1:1'b0;

    MUX2to1 U_MUXINMEM ( //选择用于旁路的数据来自ALUOut还是OutB
        .d0                      (MWBus.MEM_ALUOut),
        .d1                      (MWBus.MEM_OutB),
        .sel2_to_1               (MEM_Forward_data_sel),
        .y                       (MEM_Result)
    );
    //---------------------------------------------------------------------------//
    

endmodule