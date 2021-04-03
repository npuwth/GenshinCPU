/*
 * @Author: Juan Jiang
 * @Date: 2021-04-03 16:28:13
 * @LastEditTime: 2021-04-03 18:46:02
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
    ports
);
    
endmodule 