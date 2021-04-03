/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:03:56
 * @LastEditTime: 2021-04-03 10:15:06
 * @LastEditors: Seddon Shen
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \undefinedd:\EXE\ForwardUnit.sv
 * 
 */
`include "CommonDefines.svh"
`include "CPU_Defines.svh"
module ForwardUnit (
     EXE_rs,EXE_rt,MEM_Wr,WB_Wr,MEM_Dst ,WB_Dst,
     EXE_ForwardA,EXE_ForwardB,//两个选择信号
     WB_RegsWrType,MEM_RegsWrType
);
    input RegsWrType WB_RegsWrType;
    input RegsWrType MEM_RegsWrType;
    input [4:0] EXE_rt,EXE_rs;         // 输入五位宽地址信号
    input MEM_Wr,WB_Wr;  // 写使能信号
    input [4:0] MEM_Dst ,WB_Dst;  //  写回地址
    output [1:0] EXE_ForwardA,EXE_ForwardB;   

    reg [1:0] EXE_ForwardA_r,EXE_ForwardB_r;//临时寄存器


    // EXE_ForwardA信号选择
    // 0 选择的是 寄存器中的数据
    // 1 选择的是 MEM_ALUOut中的数据
    // 2 选择的是 WB_Result中的数据 
    always_comb begin
        //加入regtype的直接比较
        if ((MEM_Wr) && MEM_Dst  !=5'd0 && EXE_rs == MEM_Dst ) begin
            if (WB_RegsWrType == MEM_RegsWrType) begin//avoid CP0 and regsfile conflict
                EXE_ForwardA_r = 2'd1;
            end
        end
        else if ((WB_Wr) && WB_Dst != 5'd0 && EXE_rs == WB_Dst)  begin
            if (WB_RegsWrType == MEM_RegsWrType) begin
                EXE_ForwardA_r = 2'd2;
            end
        end
        else EXE_ForwardA_r= 2'd0;
    end

    // EXE_ForwardB信号选择
    // 0 选择的是 寄存器中的数据
    // 1 选择的是 MEM_ALUOut中的数据
    // 2 选择的是 WB_Result中的数据 
    
    always_comb begin
        if ((MEM_Wr) && MEM_Dst  !=5'd0 && EXE_rt == MEM_Dst ) begin
            if (WB_RegsWrType == MEM_RegsWrType) begin//avoid CP0 and regsfile conflict
                EXE_ForwardB_r = 2'd1;
            end
        end
        else if ((WB_Wr) && WB_Dst != 5'd0 && EXE_rt == WB_Dst)  begin
            if (WB_RegsWrType == MEM_RegsWrType) begin//avoid CP0 and regsfile conflict
                EXE_ForwardB_r = 2'd2;
            end
        end
        else EXE_ForwardB_r = 2'd0;
    end

    
    assign EXE_ForwardA = EXE_ForwardA_r;
    assign EXE_ForwardB = EXE_ForwardB_r;

endmodule
