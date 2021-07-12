 /*
 * @Author: Johnson Yang
 * @Date: 2021-03-31 15:22:23
 * @LastEditTime: 2021-07-12 11:18:46
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"  
`include "../CPU_Defines.svh"

 module Exception(
    input RegsWrType           MEM_RegsWrType,  
    input ExceptinPipeType     MEM_ExceptType,        //译码执行阶段收集到的异常信息
    input logic [31:0]         MEM_PC,                //用于判断取指令地址错例外
    input logic [22:22]        CP0_Status_BEV,
    input logic [7:0]          CP0_Status_IM7_0,
    input logic                CP0_Status_EXL,
    input logic                CP0_Status_IE,
    input logic [7:2]          CP0_Cause_IP7_2,
    input logic [1:0]          CP0_Cause_IP1_0,

    output RegsWrType          MEM_RegsWrType_final,  //要向下一级传递的RegsWrType
    output logic               ID_Flush,              //Flush信号
    output logic               EXE_Flush,
    output logic               MEM_Flush,
    output logic [2:0]         EX_Entry_Sel,     //用于生成NPC
    output ExceptinPipeType    MEM_ExceptType_final,   //最终的异常类型
    output logic [31:0]        Exception_Vector     // 异常处理的入口地址
 );
    logic  [31:0]    base;
    logic  [31:0]    offset;
always_comb begin
    if (MEM_ExceptType_final != `ExceptionTypeZero )begin
        if (MEM_ExceptType.Refetch == 1'b1) begin
            EX_Entry_Sel  = `IsRefetch;
        end
        else if(MEM_ExceptType.TLBRefillinIF == 1'b1 || MEM_ExceptType.RdTLBRefillinMEM == 1'b1 || MEM_ExceptType.WrTLBRefillinMEM == 1'b1) begin
            EX_Entry_Sel  = `IsRefill;
        end
        else if (MEM_ExceptType.Eret == 1'b1) begin
            EX_Entry_Sel  = `IsEret;
        end
        else begin
            EX_Entry_Sel  = `IsException;
        end
        ID_Flush               = `FlushEnable;
        EXE_Flush              = `FlushEnable;
        MEM_Flush              = `FlushEnable;
        MEM_RegsWrType_final   = `RegsWrTypeDisable;
    end 
    else begin
        EX_Entry_Sel           = `IsNone;
        ID_Flush               = `FlushDisable;
        EXE_Flush              = `FlushDisable;
        MEM_Flush              = `FlushDisable;
        MEM_RegsWrType_final   = MEM_RegsWrType;                
    end
end
// 产生异常处理的新入口 -- base
always_comb begin : PC_Exception_Ebase_Generate
    if (CP0_Status_BEV == 1'b1) begin
        base = 32'hbfc00200;
    end 
    else if (CP0_Status_BEV == 1'b0) begin
        base = CP0.Ebase;
    end
    else begin
        base = 'x; // 这种情况应该不会出现 
    end
end

// 产生异常处理的新入口 -- offest
always_comb begin : PC_Exception_Offset_Generate
    if ( MEM_ExceptType_final.TLBRefillinIF == 1'b1 || MEM_ExceptType_final.RdTLBRefillinMEM == 1'b1|| MEM_ExceptType_final.WrTLBRefillinMEM == 1'b1 ) begin
        if (CP0_Status_EXL == 1'b1) begin
            offset = 32'h180;
        end 
        else if (CP0_Status_EXL == 1'b0) begin
            offset = 32'h0;
        end 
    end
    else begin
        offset = 32'h180;
    end
end
assign Exception_Vector  = base + offset; 

assign MEM_ExceptType_final.Interrupt           = ( (({CP0_Cause_IP7_2,CP0_Cause_IP1_0} & CP0_Status_IM7_0) != 8'b0) &&
                                                     (CP0_Status_EXL == 1'b0) && (CP0_Status_IE == 1'b1)) ?1'b1:1'b0;
assign MEM_ExceptType_final.WrongAddressinIF    = (MEM_PC[1:0] != 2'b00 )?1'b1:1'b0;
assign MEM_ExceptType_final.ReservedInstruction = MEM_ExceptType.ReservedInstruction;
assign MEM_ExceptType_final.CoprocessorUnusable = MEM_ExceptType.CoprocessorUnusable;
assign MEM_ExceptType_final.Syscall             = MEM_ExceptType.Syscall;
assign MEM_ExceptType_final.Break               = MEM_ExceptType.Break;
assign MEM_ExceptType_final.Eret                = MEM_ExceptType.Eret;
assign MEM_ExceptType_final.WrWrongAddressinMEM = MEM_ExceptType.WrWrongAddressinMEM;
assign MEM_ExceptType_final.RdWrongAddressinMEM = MEM_ExceptType.RdWrongAddressinMEM;
assign MEM_ExceptType_final.Overflow            = MEM_ExceptType.Overflow;
assign MEM_ExceptType_final.TLBRefillinIF       = MEM_ExceptType.TLBRefillinIF;
assign MEM_ExceptType_final.TLBInvalidinIF      = MEM_ExceptType.TLBInvalidinIF;
assign MEM_ExceptType_final.RdTLBRefillinMEM    = MEM_ExceptType.RdTLBRefillinMEM;
assign MEM_ExceptType_final.RdTLBInvalidinMEM   = MEM_ExceptType.RdTLBInvalidinMEM;
assign MEM_ExceptType_final.WrTLBRefillinMEM    = MEM_ExceptType.WrTLBRefillinMEM; 
assign MEM_ExceptType_final.WrTLBInvalidinMEM   = MEM_ExceptType.WrTLBInvalidinMEM;   
assign MEM_ExceptType_final.TLBModified         = MEM_ExceptType.TLBModified;
assign MEM_ExceptType_final.Refetch             = MEM_ExceptType.Refetch;
assign MEM_ExceptType_final.Trap                = MEM_ExceptType.Trap;


endmodule

