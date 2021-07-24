/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:25:55
 * @LastEditTime: 2021-07-24 12:22:50
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Coded:\cpu\nontrival-cpu\nontrival-cpu\Src\Code\BranchSolve.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module BranchSolve (
    input BranchType      EXE_BranchType,
    input logic           EXE_IsAJumpCall,
    input logic [31:0]    EXE_OutA,
    input logic [31:0]    EXE_OutB,
    input logic [31:0]    EXE_PC,
    input logic [31:0]    EXE_Instr,
    input logic [31:0]    EXE_Imm32,
    input logic           EXE_Wr,
    input PResult         EXE_PResult,    //随流水线流动的预测结果
    output logic          EXE_Prediction_Failed,//表示预测失败
    output logic [31:0]   EXE_Correction_Vector,//用于校正的地址向量
    output BResult        EXE_BResult     //用于校正BHT查找表的数据
);

    logic                 Branch_IsTaken; //实际是否应该跳转   （方向）
    logic [31:0]          Branch_Target;  //实际应该跳转的地址 （目标）
    logic [1:0]           Branch_Type;    //实际应该跳转的Type（种类）
    
    logic                 Branch_Success;
    logic                 J_Success;
    logic                 JR_Success;
    logic                 PC8_Success;
    logic                 Prediction_Success;//表示预测成功
    logic [31:0]          BranchAddr;        //跳转地址的生成
    logic [31:0]          JumpAddr;          //跳转地址的生成
    logic [31:0]          EXE_PCAdd4;        //跳转地址的生成
    //------------------用于Branch判断是否跳转---------------//
    logic                 equal,not_equal;
    logic                 not_equal_to_zero,equal_to_zero;
    logic                 greater_equal_to_zero;
    logic                 less_than_zero;

    assign equal             = ~(|(EXE_OutA ^ EXE_OutB));
    assign not_equal         = |(EXE_OutA ^ EXE_OutB);
    assign not_equal_to_zero = |EXE_OutA;
    assign equal_to_zero     = ~(|EXE_OutA);
    assign greater_equal_to_zero = ~(EXE_OutA[31]);
    assign less_than_zero    = EXE_OutA[31];

    always_comb begin
        if(EXE_BranchType.isBranch) begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_BEQ:
                Branch_IsTaken = equal;
            `BRANCH_CODE_BNE:
                Branch_IsTaken = not_equal;
            `BRANCH_CODE_BGE:
                Branch_IsTaken = greater_equal_to_zero;
            `BRANCH_CODE_BGT:
                Branch_IsTaken = greater_equal_to_zero & not_equal_to_zero;
            `BRANCH_CODE_BLE:
                Branch_IsTaken = equal_to_zero | less_than_zero;
            `BRANCH_CODE_BLT:
                Branch_IsTaken = less_than_zero;
            default: begin
                Branch_IsTaken = 1'b1; //J，JR型
             end
            endcase
        end
        else begin
            Branch_IsTaken = 1'b0;
        end
    end

    always_comb begin
        if(EXE_BranchType.isBranch) begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_J:begin
                if(EXE_IsAJumpCall) Branch_Type = `BIsCall;
                else                Branch_Type = `BIsImme; 
                Branch_Target                   = JumpAddr;
            end 
            `BRANCH_CODE_JR:begin
                if(EXE_IsAJumpCall) Branch_Type = `BIsCall;
                else                Branch_Type = `BIsRetn;
                Branch_Target                   = EXE_OutA;
            end
            default: begin
                Branch_Type                       = `BIsImme;
                if(Branch_IsTaken)  Branch_Target = BranchAddr;
                else                Branch_Target = EXE_PC + 8; 
            end               
            endcase
        end
        else begin
            Branch_Type   = `BIsNone;
            Branch_Target = EXE_PC + 8;
        end                       
    end 

    assign EXE_BResult.Type         = Branch_Type;
    assign EXE_BResult.IsTaken      = Branch_IsTaken;  
    assign EXE_BResult.Target       = Branch_Target;
    assign EXE_BResult.PC           = EXE_PC;
    assign EXE_BResult.Count        = EXE_PResult.Count;
    assign EXE_BResult.Hit          = EXE_PResult.Hit;
    assign EXE_BResult.Valid        = EXE_PResult.Valid && EXE_Wr;
    assign EXE_Correction_Vector    = Branch_Target;
    assign EXE_BResult.RetnSuccess  = Prediction_Success && (EXE_PResult.Type == `BIsRetn) && EXE_Wr;

    assign EXE_PCAdd4        =   EXE_PC+4;
    assign JumpAddr          =   {EXE_PCAdd4[31:28],EXE_Instr[25:0],2'b0};
    assign BranchAddr        =   EXE_PC+4+{EXE_Imm32[29:0],2'b0};

//---------------------------判断预测是否成功---------------------------//
    assign Branch_Success    =   (EXE_PResult.Target == BranchAddr);
    assign J_Success         =   (EXE_PResult.Target == JumpAddr);
    assign JR_Success        =   (EXE_PResult.Target == EXE_OutA);
    assign PC8_Success       =   (EXE_PResult.Target == EXE_PC+8);

    always_comb begin
        if(EXE_BranchType.isBranch) begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_J:begin
                Prediction_Success = J_Success;
            end 
            `BRANCH_CODE_JR:begin
                Prediction_Success = JR_Success;
            end
            default: begin
                if(Branch_IsTaken)  Prediction_Success = Branch_Success;
                else                Prediction_Success = PC8_Success; 
            end               
            endcase
        end
        else begin
            Prediction_Success = PC8_Success;
        end                       
    end 

    assign EXE_Prediction_Failed = ~Prediction_Success && EXE_PResult.Valid && EXE_Wr;


endmodule