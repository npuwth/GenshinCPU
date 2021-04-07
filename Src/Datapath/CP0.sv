//******************************************************************************
//                              协处理器CP0
//  只实现了CP0中的Count、Compare、Status、Cause、EPC、PRId、Config7个寄存器的部分
//功能
//******************************************************************************
// 更改到128行的位置
`include "CommonDefines.svh"
`include "CPU_Defines.svh"
`define ZeroWord 32'h0
module cp0_reg(
    input logic rst_i,
    input logic clk_i,

    // 写CP0数据相关接口
    input logic             CP0Wr_i,          //CP0写使能
    input logic  [4:0]      CP0WrAddr_i,      //写入的CP0寄存器的地址
    input logic  [31:0]     CP0WrDataOut_i,   //要写入CP0中寄存器的数据

    // 读CP0数据相关接口
    input logic  [4:0]      CP0RdAddr_i,      //要读取的CP0寄存器的地址
    output logic [31:0]     CP0RdDataOut_o,   //读出的CP0某个寄存器的值

    // 异常相关输入接口
    input ExceptinPipeType  ExceptType_i,     //最终的异常类型
    input AsynExceptType    Interrupt_i,      //6个外部硬件中断输入
    input logic  [31:0]     PCAdd1_i,         //发生异常的指令地址+1
    input logic             IsDelaySlot_i,    //发生异常的指令是否是延迟槽指令

    // 输出
    output logic   [31:0]   CP0BadVAddr_o,    //8号寄存器  BadVAddr寄存器的值:最新地址相关例外的出错地址
    output logic   [31:0]   CP0Count_o,       //9号寄存器  Count寄存器的值
    output logic   [31:0]   CP0Compare_o,     //11号寄存器 Compare寄存器的值
    output logic   [31:0]   CP0Status_o,      //12号寄存器 Status寄存器的值
    output logic   [31:0]   CP0Cause_o,       //13号寄存器 Cause寄存器的值
    output logic   [31:0]   CP0EPC_o,         //14号寄存器 EPC寄存器的值

    output logic CP0TimerInterrupt_o          //是否有定时中断发生
    );
    logic[5:0] Hardwareint_i;
assign CurrentInstAddr = PCAdd1_i-1;
assign Hardwareint_i = {Interrupt_i.HardwareInterrupt1,Interrupt_i.HardwareInterrupt2,Interrupt_i.HardwareInterrupt3,Interrupt_i.HardwareInterrupt4,Interrupt_i.HardwareInterrupt5};
//******************************************************************************
//                     对CP0中寄存器的写操作：时序逻辑
//  PRId、Config不可以写，Cause寄存器只有其中的IP[1:0]、IV、WP三个字段可写
//******************************************************************************
    always @ ( posedge clk ) begin
        if(rst == 1'b0) begin

            //Count寄存器的初始值
            CP0Count_o <= `ZeroWord;

            //Compare寄存器的初始值
            CP0Compare_o <= `ZeroWord;

            //Status寄存器的初始值：其中CU字段为0001，表示协处理器CP0存在
            CP0Status_o <= 32'b0001_0000_0000_0000_0000_0000_0000_0000;

            //Cause寄存器的初始值
            CP0Cause_o <= `ZeroWord;

            //EPC寄存器的初始值
            CP0EPC_o <= `ZeroWord;
            
            CP0TimerInterrupt_o <= `InterruptNotAssert;

        end 
        else begin

            CP0Count_o <= CP0Count_o + 1;   //Count寄存器的值在每个时钟周期加1
            CP0Cause_o[15:10] <= Hardwareint_i;     //Cause寄存器的10-15位保存6个外部中断状态（1代表有中断需要处理）

            //当Compare寄存器不为0，且Count寄存器的值等于Compare寄存器的值时，
            //将输出信号CP0TimerInterrupt_o置为1，表示时钟中断发生
            if(CP0Compare_o != `ZeroWord && CP0Count_o == CP0Compare_o) begin
                CP0TimerInterrupt_o <= InterruptAssert;;
            end

            if(CP0Wr_i == `WriteEnable) begin
                case(CP0WrAddr_i)
                    `CP0_REG_COUNT:begin            //写Count寄存器
                        CP0Count_o <= CP0WrDataOut_i;
                    end
                    `CP0_REG_COMPARE:begin          //写Compare寄存器
                        CP0Compare_o <= CP0WrDataOut_i;
                        //表示取消时钟中断的声明
                        CP0TimerInterrupt_o <= `InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:begin           //写Status寄存器
                        CP0Status_o <= CP0WrDataOut_i;
                    end
                    `CP0_REG_EPC:begin              //写EPC寄存器
                        CP0EPC_o <= CP0WrDataOut_i;
                    end
                    `CP0_REG_CAUSE:begin            //写Cause寄存器
                        //Cause寄存器只有IP[1:0]、IV、WP字段是可写的
                        CP0Cause_o[9:8] <= CP0WrDataOut_i[9:8];    //IP[1:0]
                        CP0Cause_o[23] <= CP0WrDataOut_i[23];      //IV
                        CP0Cause_o[22] <= CP0WrDataOut_i[22];      //WP
                    end
                endcase
            end//if(we_i == `WriteEnable)

            if (Hardwareint_i != 6'b0) begin   //存在外部中断
                    //已经在访存阶段判断了是否处于异常级
                    if(IsDelaySlot_i == `InDelaySlot) begin
                        CP0EPC_o <= CurrentInstAddr - 4;
                        CP0Cause_o[31] <= 1'b1;        //Cause寄存器的BD字段
                    end else begin
                        CP0EPC_o <= CurrentInstAddr;
                        CP0Cause_o[31] <= 1'b0;
                    end
                    CP0Status_o[1] <= 1'b1;            //Status寄存器的EXL字段
                    CP0Cause_o[6:2] <= 5'b00000;       //Cause寄存器的ExcCode字段
                end
            else if (ExceptType_i.Syscall == 1'b1)  begin     //系统调用异常syscall
                    //Status[1]为EXL字段，表示是否处于异常级
                    if(CP0Status_o[1] == 1'b0) begin  // EXL字段是否有例外发生（为0代表处于正常级）
                        if(IsDelaySlot_i == `InDelaySlot) begin
                            CP0EPC_o <= CurrentInstAddr - 4;
                            CP0Cause_o[31] <= 1'b1;
                        end else begin
                            CP0EPC_o <= CurrentInstAddr;
                            CP0Cause_o[31] <= 1'b0;
                        end
                    end
                    //如果EXL字段为1，表示当前已经处于异常级了，又发生了新的异常，那么
                    //只需要将异常原因保存到Cause寄存器的ExcCode字段
                    ？？？？？ CP0Status_o[1] <= 1'b1;
                    CP0Cause_o[6:2] <= 5'b01000;
                end
                32'h0000_000a:begin                 //无效指令异常
                    if(CP0Status_o[1] == 1'b0) begin
                        if(IsDelaySlot_i == `InDelaySlot) begin
                            CP0EPC_o <= CurrentInstAddr - 4;
                            CP0Cause_o[31] <= 1'b1;
                        end else begin
                            CP0EPC_o <= CurrentInstAddr;
                            CP0Cause_o[31] <= 1'b0;
                        end
                    end
                    CP0Status_o[1] <= 1'b1;
                    CP0Cause_o[6:2] <= 5'b01010;
                end
                32'h0000_000d:begin                 //自陷异常
                    if(CP0Status_o[1] == 1'b0) begin
                        if(IsDelaySlot_i == `InDelaySlot) begin
                            CP0EPC_o <= CurrentInstAddr - 4;
                            CP0Cause_o[31] <= 1'b1;
                        end else begin
                            CP0EPC_o <= CurrentInstAddr;
                            CP0Cause_o[31] <= 1'b0;
                        end
                    end
                    CP0Status_o[1] <= 1'b1;
                    CP0Cause_o[6:2] <= 5'b01101;
                end
                32'h0000_000c:begin                 //溢出异常
                    if(CP0Status_o[1] <= 1'b0) begin
                        if(IsDelaySlot_i == `InDelaySlot) begin
                            CP0EPC_o <= CurrentInstAddr - 4;
                            CP0Cause_o[31] <= 1'b1;
                        end else begin
                            CP0EPC_o <= CurrentInstAddr;
                            CP0Cause_o[31] <= 1'b0;
                        end
                    end
                    CP0Status_o[1] <= 1'b1;
                    CP0Cause_o[6:2] <= 5'b01100;
                end
                32'h0000_000e:begin                 //异常返回指令eret
                    CP0Status_o[1] <= 1'b0;
                end
                default:begin
                end
            endcase
        end//else
    end


//******************************************************************************
//                      对CP0中寄存器的读操作：组合逻辑
//******************************************************************************
    always @ ( * ) begin
        if(rst == `RstEnable) begin
            CP0RdDataOut_o <= `ZeroWord;
        end else begin
            case(CP0RdAddr_i)
                `CP0_REG_COUNT:begin                //读Count寄存器
                    CP0RdDataOut_o <= CP0Count_o;
                end
                `CP0_REG_COMPARE:begin              //读Compare寄存器
                    CP0RdDataOut_o <= CP0Compare_o;
                end
                `CP0_REG_STATUS:begin               //读Status寄存器
                    CP0RdDataOut_o <= CP0Status_o;
                end
                `CP0_REG_CAUSE:begin                //读Cause寄存器
                    CP0RdDataOut_o <= CP0Cause_o;
                end
                `CP0_REG_EPC:begin                  //读EPC寄存器
                    CP0RdDataOut_o <= CP0EPC_o;
                end
                `CP0_REG_PRId:begin                 //读PRId寄存器
                    CP0RdDataOut_o <= prid_o;
                end
                `CP0_REG_CONFIG:begin               //读Config寄存器
                    CP0RdDataOut_o <= config_o;
                end
                default:begin
                end
            endcase
        end//else
    end

endmodule
