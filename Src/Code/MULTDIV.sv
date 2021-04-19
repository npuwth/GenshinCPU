/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-04-19 15:03:47
 * @LastEditors: Seddon Shen
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\Code\MULTDIV.sv
 * 
 */
`include "CommonDefines.svh"
`include "CPU_Defines.svh"
module MULTDIV(EXE_ResultA,EXE_ResultB,EXE_ALUOp,EXE_MULTDIVOut,EXE_Finish);
input logic[31:0] EXE_ResultA,EXE_ResultB;
input logic[4:0] EXE_ALUOp;
//output logic [31:0] EXE_ALUOut;TODO:流水线寄存器中修改
output logic [63:0] EXE_MULTDIVOut;
output logic EXE_Finish;
logic [32:0] Result_A33;
logic [32:0] Result_B33;
logic [65:0] Prod;
always_comb begin
    unique case (EXE_ALUOp)
        `EXE_ALUOp_MULT , `EXE_ALUOp_MULTU:begin
            if(EXE_ALUOp == `EXE_ALUOp_MULT)begin
                Result_A33 = {EXE_ResultA[31],EXE_ResultA};
                Result_B33 = {EXE_ResultB[31],EXE_ResultB};
            end
            else begin
                Result_A33 = {1'b0,EXE_ResultA};
                Result_B33 = {1'b0,EXE_ResultB};
            end
            Prod = Result_A33 * Result_B33;
        end
        `EXE_ALUOp_DIV:begin
            
        end
        `EXE_ALUOp_DIVU:begin
            
        end
        default: Prod = 'x;//Do nothing
    endcase
    
end 


// always_comb begin 
//     EXE_ExceptType_new = EXE_ExceptType;
//     EXE_ExceptType_new.Overflow = ((!EXE_ResultA[31] && !EXE_ResultB[31]) && (EXE_ALUOut_r[31]))||((EXE_ResultA[31] && EXE_ResultB[31]) && (!EXE_ALUOut_r[31]));
// end
    //assign EXE_ALUOut = EXE_ALUOut_r;
    //assign EXE_ALUOut = Prod[63:0];
    assign EXE_Finish = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU) ? 1 : 0;//TODO:除法的Finish还没有写
    assign EXE_MULTDIVOut = Prod[63:0];
    //assign EXE_ALUOut = ;
    
endmodule