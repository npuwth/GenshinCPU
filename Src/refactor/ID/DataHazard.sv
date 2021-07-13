/*
 * @Author: 
 * @Date: 2021-06-16 16:07:56
 * @LastEditTime: 2021-07-13 19:19:55
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module DataHazard (
    input logic [4:0]  ID_rs,
    input logic [4:0]  ID_rt,
    input logic [1:0]  ID_rsrtRead,//[1]是rs [0]是rt 1'b1的时候是读
    input logic [4:0]  EXE_rt,
    input logic        EXE_ReadMEM,  // 在EXE的load指令
    input logic [4:0]  MEM_rt,       // load的目标寄存器
    input logic        MEM_ReadMEM,  // 在MEM级的load指令
    input logic [31:0] EXE_Instr,
    //--------------------output-----------------------//
    output logic       DH_Stall      //数据冒险的阻塞
);
    always_comb begin
        if ( EXE_ReadMEM == 1'b1 && ((ID_rs == EXE_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == EXE_rt && ID_rsrtRead[0] == 1'b1))) begin
            DH_Stall = 1'b1;
        end
        else if (MEM_ReadMEM == 1'b1 && ((ID_rs == MEM_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == MEM_rt && ID_rsrtRead[0] == 1'b1))) begin
            DH_Stall = 1'b1;
        end
        else if ( EXE_Instr[31:21] == 11'b010000_00000 && ((ID_rs == EXE_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == EXE_rt && ID_rsrtRead[0] == 1'b1))) begin //MFC0后面存在数据依赖的情况
            DH_Stall = 1'b1;
        end 
        else begin
            DH_Stall = 1'b0;
        end    

    end

endmodule
