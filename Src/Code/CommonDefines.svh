/*
 * @Author: Johnson Yang
 * @Date: 2021-03-24 14:40:35
 * @LastEditTime: 2021-03-31 14:46:26
 * @LastEditors: your name
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`ifndef CommonDefines_svh
`define CommonDefines_svh

`define WriteEnable         1'b1     // 打开写使能信号
`define WriteDisable        1'b0     // 关闭写使能信号
`define RstEnable           1'b1     // 打开复位信号(高有效)
`define RstDisable          1'b0     // 关闭复位信号

`define InterruptNotAssert  1'b0     // 取消中断的声明
`define InterruptAssert     1'b1     // 开启中断的声明
`define InDelaySlot         1'b1     // 延迟槽指令
`define ZeroWord            32'h0    // 寄存器32位全0信号

// CP0寄存器的宏定义  （序号定义）
`define CP0_REG_BADVADDR    5'd8
`define CP0_REG_COUNT       5'd9
`define CP0_REG_COMPARE     5'd11
`define CP0_REG_STATUS      5'd12
`define CP0_REG_CAUSE       5'd13
`define CP0_REG_EPC         5'd14

//用于选择storeleefine CP0_REG_EPC         5'd14

//用于选择store类型
`define STORETYPE_SW        2'b00
`define STORETYPE_SH        2'b01
`define STORETYPE_SB        2'b10

//用于选择load类型
`define LOADTYPE_LW         3'b100
`define LOADTYPE_LH         3'b101
`define LOADTYPE_LHU        3'b001
`define LOADTYPE_LB         3'b110
`define LOADTYPE_LBU        3'b010

`endif
