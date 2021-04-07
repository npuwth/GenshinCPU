/*
 * @Author: Juan Jiang
 * @Date: 2021-04-03 16:28:13
 * @LastEditTime: 2021-04-07 14:20:59
 * @LastEditors: Juan Jiang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: this is a module to produce the signal to choose which is the next PC
 */


module moduleName #(
    parameter PCSel_PC4      = 3'b000,
    parameter PCSel_ImmeJump = 3'b001,
    parameter PCSel_EPC      = 3'b010,
    parameter PCSel_Except   = 3'b011,
    parameter PCSel_Branch   = 3'b100     
) (
    input logic         isBranch,
    input logic         isImmeJump,
    input logic[1:0]    isExceptorERET,

    output logic[2:0]   PCSel
);

    always_comb begin 
        if(isExceptorERET == `IsNone)begin
            if (isImmeJump == 1'b1) begin
                PCSel = PCSel_ImmeJump;
            end
            else if (isBranch == 1'b1) begin
                PCSel = PCSel_Branch;
            end
            else PCSel = PCSel_PC4;
        end
        else if (isExceptorERET == `IsEret) begin
            PCSel = PCSel_EPC;
        end
        else if (isExceptorERET == `IsException)begin
            PCSel = PCSel_Except;
        end
        else begin
            PCSel = 3'bxxx;
        end
    end


    
endmodule 