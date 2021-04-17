/*
 * @Author: Seddon Shen
 * @Date: 2021-04-02 15:03:56
 * @LastEditTime: 2021-04-17 10:01:30
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Code\ForwardUnit.sv
 * 
 */
`include "CommonDefines.svh"
`include "CPU_Defines.svh"
module ForwardUnit (
     EXE_rs,EXE_rt,MEM_Dst ,WB_Dst,
     EXE_ForwardA,EXE_ForwardB,//两个选择信号
     WB_RegsWrType,MEM_RegsWrType,EXE_RegsWrType
);
    input RegsWrType EXE_RegsWrType;
    input RegsWrType WB_RegsWrType;
    input RegsWrType MEM_RegsWrType;
    input [4:0] EXE_rt,EXE_rs;         // 输入五位宽地址信号
    input [4:0] MEM_Dst ,WB_Dst;  //  写回地址
    output [1:0] EXE_ForwardA,EXE_ForwardB;   

    reg [1:0] EXE_ForwardA_r,EXE_ForwardB_r;//临时寄存器

    logic MEM_Wr,WB_Wr;//写使能信号
    
    assign MEM_Wr = MEM_RegsWrType.RFWr | MEM_RegsWrType.CP0Wr | MEM_RegsWrType.HIWr | MEM_RegsWrType.LOWr;
    assign WB_Wr = WB_RegsWrType.RFWr | WB_RegsWrType.CP0Wr | WB_RegsWrType.HIWr | WB_RegsWrType.LOWr;

    // EXE_ForwardA信号选择
    // 0 选择的是 寄存器中的数据
    // 1 选择的是 MEM_ALUOut中的数据
    // 2 选择的是 WB_Result中的数据 
    always_comb begin
        //加入regtype的直接比较
        if ((MEM_Wr) && MEM_Dst  !=5'd0 && EXE_rs == MEM_Dst ) begin
            if (EXE_RegsWrType == MEM_RegsWrType) begin//avoid CP0 and regsfile conflict
                EXE_ForwardA_r = 2'd1;
            end else begin
                EXE_ForwardA_r = 2'd0;
            end
        end
        else if ((WB_Wr) && WB_Dst != 5'd0 && EXE_rs == WB_Dst)  begin
            if (EXE_RegsWrType == WB_RegsWrType) begin
                EXE_ForwardA_r = 2'd2;
            end else begin
                EXE_ForwardA_r = 2'd0;
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
            if (EXE_RegsWrType == MEM_RegsWrType) begin//avoid CP0 and regsfile conflict
                EXE_ForwardB_r = 2'd1;
            end else begin
                EXE_ForwardB_r = 2'd0;
            end
        end
        else if ((WB_Wr) && WB_Dst != 5'd0 && EXE_rt == WB_Dst)  begin
            if (EXE_RegsWrType == WB_RegsWrType) begin//avoid CP0 and regsfile conflict
                EXE_ForwardB_r = 2'd2;
            end else begin
                EXE_ForwardB_r = 2'd0;
            end
        end
        else EXE_ForwardB_r = 2'd0;
    end

    
    assign EXE_ForwardA = EXE_ForwardA_r;
    assign EXE_ForwardB = EXE_ForwardB_r;

endmodule
