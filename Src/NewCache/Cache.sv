/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-07-11 20:27:53
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\ICache.sv
 */
//重写之后的Cache Icache Dcache复用一个设计
`include "Cache_Defines.svh"
`include "CPU_Defines.svh"
//`define Dcache  //如果是DCache就在文件中使用这个宏
module Cache #(
    //parameter bus_width = 4,//axi总线的id域有bus_width位
    parameter DATA_WIDTH    = 32,//cache和cpu 总线数据位宽为data_width
    parameter LINE_WORD_NUM = 4,//cache line大小 一块的字数
    parameter ASSOC_NUM     = 4,//assoc_num组相连
    parameter WAY_SIZE      = 4*1024*8,//一路cache 容量大小为way_size bit
    parameter SET_NUM       = WAY_SIZE/(LINE_WORD_NUM*DATA_WIDTH) //

) (
    //external signals
    input logic clk,
    input logic resetn,

    //with TLBMMU
    //output VirtualAddressType virt_addr,
    input  PhysicalAddressType phsy_addr,
    input  logic isCache,

    `ifdef Dcache
    AXI_UNCACHE_Interface axi_ubus,
    `endif 
    CPU_Bus_Interface  cpu_bus,//slave
    AXI_Bus_Interface  axi_bus //master
    
    
);
localparam int unsigned INDEX_WIDTH  = $clog2(SET_NUM) ;
localparam int unsigned OFFSET_WIDTH = $clog2(LINE_WORD_NUM*4);
localparam int unsigned TAG_WIDTH    = 32-INDEX_WIDTH-OFFSET_WIDTH ;



typedef struct packed {
    logic valid;
    logic dirty;
    logic [`TAGBITNUM-1:0] tag;  
} tag_t; //每一路 一个tag_t变量

typedef logic [LINE_WORD_NUM-1:0][DATA_WIDTH-1:0] lint_t;//每一路一个cache_line
typedef logic [INDEX_WIDTH-1:0]                   index_t;
typedef logic [OFFSET_WIDTH-1]
    
endmodule