/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-07-06 18:26:22
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\ICache.sv
 */
//重写之后的Cache Icache Dcache复用一个设计
`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
module Cache #(
    //parameter bus_width = 4,//axi总线的id域有bus_width位
    parameter data_width = 32,//cache和cpu 总线数据位宽为data_width
    parameter line_width = 256,//cache line大小位宽line_width
    parameter set_num = 4,//set_num组相连
    parameter way_size = 4*1024*8//一路cache 容量大小为way_size bit
) (
    //external signals
    input logic clk,
    input logic resetn,

    //with TLBMMU
    output VirtualAddressType virt_addr,
    input  PhysicalAddressType phsy_addr,

    CPU_Bus_Interface  cpu_bus,//slave
    AXI_Bus_Interface  axi_bus //master
    
);
    
endmodule