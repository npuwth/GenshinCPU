
///////////////////////////////////////////////////////////////////////////////
// Copyright(C) Team . Open source License: MIT.
// ALL RIGHT RESERVED
// File name   : CPU_Defines.svh
// Author      : Juan Jiang
// Date        : 2021-03-20
// Version     : 0.1
// Description :
// 定义了中断变量类型、指令变量类型、装载指令变量类型、Store指令变量类型和寄存器堆（有RF CP0 HILO）写信号类型
//    
// Parameter   :没有
//    ...
//    ...
// IO Port     :没有
//    ...
//    ...
// Modification History:
//   Date   |   Author   |   Version   |   Change Description
//==============================================================================
// 19-06-02 |    Zion    |     0.1     | Original Version
// ...
////////////////////////////////////////////////////////////////////////////////

`ifndef CPU_Defines_SVH
`define CPU_Defines_SVH
`include "CommonDefines.svh"

typedef struct packed {
    logic HardwareInterrupt1;//硬件中断例外1
    logic HardwareInterrupt2;//硬件中断例外2
    logic HardwareInterrupt3;//硬件中断例外3
    logic HardwareInterrupt4;//硬件中断例外4
    logic HardwareInterrupt5;//硬件中断例外5
    logic HardwareInterrupt6;//硬件中断例外6
    logic SoftwareInterrupt1;//软件中断例外1
    logic SoftwareInterrupt2;//软件中断例外2

} AsynExceptType;//异步信号类型

typedef struct packed {
	logic Interrupt;	 	  	// 中断信号
    logic WrongAddressinIF;   	// 地址错例外——取指
    logic ReservedInstruction;	// 保留指令例外
    logic Overflow;           	// 整型溢出例外
    logic Syscall;            	// 系统调用例外
    logic Break;              	// 断点例外
    logic Eret;               	// 异常返回指令
    logic WrWrongAddressinMEM;  // 地址错例外——数据写入
    logic RdWrongAddressinMEM;  // 地址错例外——数据读取
} ExceptinPipeType;    //在流水线寄存器之间流动的异常信号

typedef enum logic [6:0] {//之所以把OP_SLL的op都大写是因为enum的值某种意义上算是一种常量
	/* shift */
	OP_SLL, OP_SRL, OP_SRA, OP_SLLV, OP_SRLV, OP_SRAV,
	/* unconditional jump (reg) */
	OP_JALR,
	/* conditional move */
	OP_MOVN, OP_MOVZ,
	/* breakpoint and syscall */
	OP_SYSCALL, OP_BREAK,
	/* HI/LO move */
	OP_MFHI, OP_MFLO, OP_MTHI, OP_MTLO,
	/* multiplication and division */
	OP_MULT, OP_MULTU, OP_DIV, OP_DIVU,
	OP_MADD, OP_MADDU, OP_MSUB, OP_MSUBU, OP_MUL,
	/* add and substract */
	OP_ADD, OP_ADDU, OP_SUB, OP_SUBU,
	/* logical */
	OP_AND, OP_OR, OP_XOR, OP_NOR,
	/* compare and set */
	OP_SLT, OP_SLTU,
	/* trap */
	OP_TGE, OP_TGEU, OP_TLT, OP_TLTU, OP_TEQ, OP_TNE,
	/* count bits */
	OP_CLZ, OP_CLO,
	/* branch */
	OP_BLTZ, OP_BGEZ, OP_BLTZAL, OP_BGEZAL,
	OP_BEQ, OP_BNE, OP_BLEZ, OP_BGTZ,
	/* set */
	OP_LUI,
	/* load */
	OP_LB, OP_LH, OP_LWL, OP_LW, OP_LBU, OP_LHU, OP_LWR,
	/* store */
	OP_SB, OP_SH, OP_SWL, OP_SW, OP_SWR,
	/* LL/SC */
	OP_LL, OP_SC,
	/* long jump */
	OP_JAL,
	/* privileged instructions */
	OP_CACHE, OP_ERET, OP_MFC0, OP_MTC0,
	OP_TLBP, OP_TLBR, OP_TLBWI, OP_TLBWR, OP_WAIT,
	/* ASIC */
	`ifdef ENABLE_ASIC
		OP_MFC2, OP_MTC2,
	`endif
	/* FPU */
	`ifdef ENABLE_FPU
		OP_MFC1, OP_MTC1, OP_CFC1, OP_CTC1,
		OP_BC1,
		OP_MOVCI,
		OP_LWC1, OP_SWC1,
		OP_LDC1A, OP_SDC1A, OP_LDC1B, OP_SDC1B,
		OP_FPU_ADD, OP_FPU_SUB, OP_FPU_COND, OP_FPU_NEG,
		OP_FPU_MUL, OP_FPU_DIV, OP_FPU_SQRT, OP_FPU_ABS,
		OP_FPU_CVTW, OP_FPU_CVTS,
		OP_FPU_TRUNC, OP_FPU_ROUND,
		OP_FPU_CEIL, OP_FPU_FLOOR,
		OP_FPU_MOV, OP_FPU_CMOV,
	`endif
	/* invalid */
	OP_INVALID
} InstrType;//一个枚举变量类型 你可以在译码这个过程中使用，这个我是照抄Tsinghua的

typedef struct packed {
    logic sign;//使用0表示unsigned 1表示signed
    logic [1:0] size;//这个表示是 00 byte 01 half  10 word
} LoadType;//

typedef struct packed {
    logic [1:0] size;//这个表示是 00 byte 01 half  10 word
} StoreType;//

typedef struct packed {
    logic RFWr;
    logic CP0Wr;
    logic HILOWr;
} RegsWrType;//三组寄存器的写信号的打包

interface PipeLineRegsInterface (
	input logic clk,
	input logic rst
);
//***** IF Part *****//
	logic [31:0] IF_NPC;//PC模块的信号
	logic        IF_PCWr;
	logic [31:0] IF_PC;

	logic [31:0] IF_Instr;//IF_ID模块的信号
	logic [31:0] IF_PCAdd1;
	logic        ID_Flush;
	logic 		 IF_IDWr;
	logic [31:0] ID_Instr;

	logic [15:0] ID_Imm16;//在指令码中的16位立即数
	logic [2:0]  ID_Sel;
	logic        ID_isJump;//判断是否是j 或者 jal

	modport PC (//PC 的端口
	input IF_NPC , 
	input IF_PCWr,
	output IF_PC
	);

	modport IF_ID (
	input IF_Instr,
	input IF_PCAdd1,
	input ID_Flush,
	input IF_IDWr,
	output ID_Instr,
	output ID_Imm16,
	output ID_PCAdd1,
	output ID_rs,
	output ID_rt,
	output ID_rd,
	output ID_Sel,
	output ID_isJump
	);



//*****   ID_Output   *****//
  	logic [31:0] ID_BusA;    		// RF 中读取到的数据A
  	logic [31:0] ID_BusB;	 		// RF 中读取到的数据B
  	logic [31:0] ID_Imm32;	 		// 符号扩展之后的32位立即数
  	logic [31:0] ID_PCAdd1;  		// PC+1
  	logic [4:0] ID_rs;		 		// rs 
  	logic [4:0] ID_rt;		 		// rt
  	logic [4:0] ID_rd;		 		// rd
  	logic [3:0] ID_ALUOp;	 		// ALUOp ALU符号
  	LoadType ID_LoadType;	 		// Load信号 （用于判断是sw sh sb还是lb lbu lh lhu lw ）
  	StoreType ID_StoreType;  		// Store信号（用于判断是sw sh sb还是sb sbu sh shu sw ）
  	RegsWrType ID_RegsWrType;		// 寄存器写信号打包
  	logic [1:0] ID_WbSel;    		// 写回信号选择
  	logic ID_ReadMem;		 		// LoadType 指令在MEM级，产生数据冒险的指令在MEM级检测
  	logic [1:0] ID_DstSel;   		// 寄存器写回信号选择（Dst）
  	logic ID_DMWr;			 		// DataMemory 写信号
  	ExceptinPipeType ID_ExceptType;	// 异常类型

//*****   EXE_Output   *****//
  	logic [31:0] EXE_BusA;   // RF 中读取到的数据A
  	logic [31:0] EXE_BusB;	 // RF 中读取到的数据B
  	logic [31:0] EXE_Imm32;  // 符号扩展之后的32位立即数
  	logic [31:0] EXE_PCAdd1; // PC+1
  	logic [4:0]  EXE_rs;
  	logic [4:0]  EXE_rt;
  	logic [4:0]  EXE_rd;
  	logic [3:0]  EXE_ALUOp;  // ALUOp ALU符号
  	LoadType EXE_LoadType;   // Load信号 （用于判断是sw sh sb还是lb lbu lh lhu lw ）
  	StoreType EXE_StoreType; // Store信号（用于判断是sw sh sb还是sb sbu sh shu sw ）
  	RegsWrType EXE_RegsWrType;
  	logic [1:0] EXE_WbSel;
  	logic [1:0] EXE_DstSel;
  	logic EXE_ReadMem;
  	logic EXE_DMWr;
  	ExceptinPipeType EXE_ExceptType;
  	logic [4:0] EXE_Shamt;
  	//logic [5:0] EXE_Funct;
    logic [31:0] EXE_ALUOut;			//组合电路传出信号
    logic [31:0] EXE_OutB;				//组合电路来的
    logic [4:0] EXE_Dst;				//组合电路来的
    logic MEM_Flush;					//未知位数 清空流水线寄存器信号

//*****   MEM_OutPut   *****//
    logic MEM_DMWr;						//OK
    StoreType MEM_StoreType;			//OK
    ExceptinPipeType MEM_ExceptType;	//OK
    LoadType MEM_LoadType;				//OK
    logic [31:0] MEM_ALUOut;			//输出信号
    logic [31:0] MEM_PCAdd1;			//OK
    logic [1:0] MEM_WbSel;				//OK
    logic [4:0] MEM_Dst;    			//输出信号
    RegsWrType MEM_RegsWrType;			//OK
    logic [31:0]MEM_OutB;				//输出信号
    logic [31:0]MEM_DMOut;				//输出信号

//*****   WB_OutPut   *****//
	logic [1:0]  WB_WbSel;        	 	// 写回RF的选择信号
	logic [31:0] WB_PCAdd1;      	 	// PC+1
	logic [31:0] WB_ALUOut;      	 	// EXE级输出的ALU结果
	logic [31:0] WB_OutB;        	 	// RF读取的第二个数据值（已经经过旁路），用于MTC0 MTHI MTLO
 	logic [31:0] WB_DMOut;	     	 	// DM读取出来的原始32位数据
	logic [4:0]  WB_Dst;		 	 	// 在WB级写回寄存器的地址
	LoadType WB_LoadType;		 	 	// 送给EXT2进行lw lh lb lbu lhu 等信号的处理
	ExceptinPipeType WB_ExceptType;  	// 异常类型
	RegsWrType WB_RegsWrType;         	// RF+CP0+HILO寄存器的写信号打包 

  modport ID_EXE (	//IDEXE_modport
    input clk,
    input rst,
    input ID_BusA,
    input ID_BusB,
    input ID_Imm32,
    input ID_PCAdd1,
    input ID_rs,
    input ID_rt,
    input ID_rd,
    input ID_ALUOp,
    input ID_LoadType,
    input ID_StoreType,
    input ID_RegsWrType,
    input ID_WbSel,
    input ID_ReadMem,
    input ID_DstSel,
    input ID_DMWr,
    input ID_ExceptType,
  
    output EXE_BusA,
    output EXE_BusB,
    output EXE_Imm32,
    output EXE_PCAdd1,
    output EXE_rs,
    output EXE_rt,
    output EXE_rd,
    output EXE_ALUOp,
    output EXE_LoadType,
    output EXE_StoreType,
    output EXE_RegsWrType,
    output EXE_WbSel,
    output EXE_DstSel,
    output EXE_ReadMem,
    output EXE_DMWr,
    output EXE_ExceptType,
    output EXE_Shamt
    //output EXE_Funct
  );

  modport EXE_MEM (  //EXEMEM_modport
    input EXE_DMWr,
    input WB_RegsWrType,
    input EXE_WbSel,
    input EXE_ALUOut,
    input EXE_OutB,
    input EXE_Dst,
    input EXE_PCAdd1,
    input EXE_StoreType,
    input EXE_LoadType,
    input EXE_ExceptType,
    input MEM_Flush,

    output MEM_DMWr,
    output MEM_StoreType,
    output MEM_ExceptType,
    output MEM_LoadType,
    output MEM_ALUOut,
    output MEM_PCAdd1,
    output MEM_WbSel,
    output MEM_Dst,
    output MEM_RegsWrType,
    output MEM_OutB
  );

  modport MEM_WB (  //MEMWB_modport
	input MEM_ExceptType,
	input MEM_LoadType,
	input MEM_ALUOut,
	input MEM_PCAdd1,
	input MEM_WbSel,
	input MEM_Dst,
	input MEM_RegsWrType,
	input MEM_OutB,
	input MEM_DMOut,

	output WB_WbSel,
	output WB_PCAdd1,
	output WB_ALUOut,
	output WB_OutB,
	output WB_DMOut,
	output WB_Dst,
	output WB_LoadType,
	output WB_ExceptType,
	output WB_RegsWrType
  );

endinterface //interfacename

interface PipeLineStagesInterface;//也就是IF ID EXE MEM 和WB
    
endinterface //interfacename


`endif 