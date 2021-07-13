/*
 * @Author: Johnson Yang
 * @Date: 2021-07-11 19:32:14
 * @LastEditTime: 2021-07-13 15:00:04
 * @LastEditors: Johnson Yang
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Code\EXE\TRAP.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
module Trap(
    input  logic [2:0]     EXE_TrapOp,
    input  logic [31:0]    EXE_ResultA,
    input  logic [31:0]    EXE_ResultB,
    output logic           Trap_valid
);
    always_comb begin : TrapDetectUnit
        case (EXE_TrapOp)
            `TRAP_OP_TEQ   : begin   // TEQ & TEQI
                if ($signed(EXE_ResultA) == $signed(EXE_ResultB))     Trap_valid = 1'b1;
                else Trap_valid = 1'b0;
            end
            `TRAP_OP_TGE   : begin   // TGE & TGEI
                if ($signed(EXE_ResultA) >= $signed(EXE_ResultB))     Trap_valid = 1'b1;
                else Trap_valid = 1'b0;
            end
            `TRAP_OP_TGEIU : begin // TGEI & TGEIU 
                if ($unsigned(EXE_ResultA) >= $unsigned(EXE_ResultB)) Trap_valid = 1'b1;
                else Trap_valid = 1'b0;
            end
            `TRAP_OP_TLT   : begin   // TLT & TLTI
                if ($signed(EXE_ResultA) < $signed(EXE_ResultB))      Trap_valid = 1'b1;
                else Trap_valid = 1'b0;
            end
            `TRAP_OP_TLTIU : begin // TLTIU & TLTU
                if ($unsigned(EXE_ResultA) < $unsigned(EXE_ResultB))  Trap_valid = 1'b1;
                else Trap_valid = 1'b0;
            end
            `TRAP_OP_TNE   : begin
                if ($signed(EXE_ResultA) != $signed(EXE_ResultB))     Trap_valid = 1'b1;
                else Trap_valid = 1'b0;
            end
            default: Trap_valid = 1'b0;
        endcase
    end
    
endmodule