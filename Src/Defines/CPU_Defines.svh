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
    logic Interrupt;//中断例外
    logic WrongAddressinIF;//地址错例外——取指
    logic ReservedInstruction;//保留指令例外
    logic Overflow;//整型溢出例外
    logic Syscall;//系统调用例外
    logic Break;//断点例外
    //logic Eret;//异常返回指令 在OpenMips一书的描述中 将eret描述成一种类似异常的指令 但是在大赛的文件中eret不是例外 我认为eret可以像j指令那么做
    logic WrongAddressinMEM;//地址错例外——数据访问
} ExceptType;//事实上，这个应该给MEM_ExceptType信号的数据类型 因为Interrupt是异步的直接拉到异常处理单元，在异常处理单元内部是这个完全体的数据类型

typedef struct packed {
    logic WrongAddressinIF;//地址错例外——取指
    logic ReservedInstruction;//保留指令例外
    logic Overflow;//整型溢出例外
    logic Syscall;//系统调用例外
    logic Break;//断点例外
    logic WrongAddressinMEM;//地址错例外——数据访问
} ExceptinPipeType;//在流水线寄存器之间流动的异常信号

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

interface interfacename;
    
endinterface //interfacename


`endif CPU_Defines_SVH