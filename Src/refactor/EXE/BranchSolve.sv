/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:25:55
 * @LastEditTime: 2021-07-19 13:57:33
 * @LastEditors: Please set LastEditors
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Coded:\cpu\nontrival-cpu\nontrival-cpu\Src\Code\BranchSolve.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module BranchSolve (
    input BranchType      EXE_BranchType,
    input logic [31:0]    EXE_OutA,
    input logic [31:0]    EXE_OutB,
    output logic          ID_Flush
);

    always_comb begin
        unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_BEQ:
                if ($signed(EXE_OutA) == $signed(EXE_OutB) && EXE_BranchType.isBranch)  begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BNE:
                if ($signed(EXE_OutA) != $signed(EXE_OutB) && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BGE:
                if ($signed(EXE_OutA) >= 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BGT:
                if ($signed(EXE_OutA) > 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BLE:
                if ($signed(EXE_OutA) <= 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_BLT:
                if ($signed(EXE_OutA) < 0 && EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            `BRANCH_CODE_JR:
                if ( EXE_BranchType.isBranch) begin
                    ID_Flush = `FlushEnable;
                end
                else begin
                    ID_Flush = `FlushDisable;
                end
            default: begin
                ID_Flush = `FlushDisable;
             end
        endcase
    end

endmodule

`ifdef NEW_BRANCH
/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:25:55
 * @LastEditTime: 2021-07-19 12:33:18
 * @LastEditors: Please set LastEditors
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Coded:\cpu\nontrival-cpu\nontrival-cpu\Src\Code\BranchSolve.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module BranchSolve (
    input BranchType      EXE_BranchType,
    input logic [31:0]    EXE_OutA,
    input logic [31:0]    EXE_OutB,
    output logic          ID_Flush
);

    logic equal,not_equal;
    logic not_equal_to_zero,equal_to_zero;
    logic greater_than_zero;
    logic less_than_zero;

    assign equal             = ~(|(EXE_OutA ^ EXE_OutB));
    assign not_equal         = |(EXE_OutA ^ EXE_OutB);
    assign not_equal_to_zero = |EXE_OutA;
    assign equal_to_zero     = ~(|EXE_OutA);
    assign greater_than_zero = ~(EXE_OutA[31]);
    assign less_than_zero    = EXE_OutA[31];

    always_comb begin
        if (~EXE_BranchType.isBranch) begin
            ID_Flush = `FlushDisable;
        end else begin
            unique case (EXE_BranchType.branchCode)
            `BRANCH_CODE_BEQ:
                    ID_Flush = equal;
            `BRANCH_CODE_BNE:
                    ID_Flush = not_equal;
            `BRANCH_CODE_BGE:
                    ID_Flush = equal_to_zero | greater_than_zero;
            `BRANCH_CODE_BGT:
                    ID_Flush = greater_than_zero;
            `BRANCH_CODE_BLE:
                    ID_Flush = equal_to_zero | less_than_zero;
            `BRANCH_CODE_BLT:
                    ID_Flush = less_than_zero;
            `BRANCH_CODE_JR:
                    ID_Flush = `FlushEnable;
            default: begin
                ID_Flush = `FlushDisable;
             end
        endcase
        end
        
    end

endmodule
`endif 