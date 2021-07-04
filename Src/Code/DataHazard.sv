/*
 * @Author: 
 * @Date: 2021-06-16 16:07:56
 * @LastEditTime: 2021-07-04 15:50:18
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module DataHazard (
    input logic [4:0]  ID_rs,//ok
    input logic [4:0]  ID_rt,//ok
    input logic [1:0]  ID_rsrtRead,//[1]是rs [0]是rt 1'b1的时候是读
    input logic [31:0] ID_Instr,
    input logic [4:0]  EXE_rt,
    input logic        EXE_ReadMEM,
    input logic [31:0] EXE_Instr,
    input logic [31:0] MEM_Instr,
    input logic [31:0] ID_IsTLBP,
    //--------------------output-----------------------//
    output logic PC_Wr,
    output logic ID_Wr,
    output logic EXE_Flush,
    output logic EXE_Wr,
    output logic MEM_Flush
);
    always_comb begin
        if ( EXE_ReadMEM == 1'b1 && ((ID_rs == EXE_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == EXE_rt && ID_rsrtRead[0] == 1'b1))) begin
            ID_Wr=1'b0;  // 产生阻塞
            PC_Wr=1'b0;
            EXE_Flush=1'b1;
            EXE_Wr = 1'b1;
            MEM_Flush= 1'b0;
        end
        // else if ( (EXE_Instr[31:21] == 11'b010000_00100) && ID_IsTLBP == 1'b1) begin //为了应对MTC0后面跟TLBP的情况
        //     ID_Wr=1'b0;  // 产生阻塞
        //     PC_Wr=1'b0;
        //     EXE_Flush=1'b1;
        //     EXE_Wr = 1'b1;
        //     MEM_Flush= 1'b0;
        // end
        else if ((EXE_Instr[31:21] == 11'b010000_00100) && (ID_Instr[31:21] == 11'b010000_00000)) begin //MTC0后跟MFC0的情况
            ID_Wr=1'b0;  // 产生阻塞
            PC_Wr=1'b0;
            EXE_Flush=1'b1;
            EXE_Wr = 1'b1;
            MEM_Flush= 1'b0;
        end 
        else if ((MEM_Instr[31:21] == 11'b010000_00100) && (ID_Instr[31:21] == 11'b010000_00000)) begin //MTC0后面的后面跟MFC0的情况
            ID_Wr=1'b0;  // 产生阻塞但不清空EXE寄存器，要清空MEM寄存器
            PC_Wr=1'b0;
            EXE_Flush=1'b0;
            EXE_Wr = 1'b0;
            MEM_Flush= 1'b1;
        end
        else begin
            ID_Wr=1'b1;  // 1的时候可以写
            PC_Wr=1'b1;
            EXE_Flush=1'b0;
            EXE_Wr = 1'b1;
            MEM_Flush= 1'b0;
        end    

    end


endmodule
