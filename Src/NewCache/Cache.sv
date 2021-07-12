/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-07-12 11:29:37
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
localparam int unsigned BYTES_PER_WORD = 4;
localparam int unsigned INDEX_WIDTH    = $clog2(SET_NUM) ;
localparam int unsigned OFFSET_WIDTH   = $clog2(LINE_WORD_NUM*BYTES_PER_WORD);//
localparam int unsigned TAG_WIDTH      = 32-INDEX_WIDTH-OFFSET_WIDTH ;



typedef struct packed {
    logic valid;
    logic dirty;
    logic [TAG_WIDTH-1:0] tag;  
} tagv_t; //每一路 一个tag_t变量

typedef logic [TAG_WIDTH-1:0]                     tag_t;
typedef logic [INDEX_WIDTH-1:0]                   index_t;
typedef logic [OFFSET_WIDTH-1:0]                  offset_t;

typedef logic [ASSOC_NUM-1:0]                     we_t;//每一路的写使能
typedef logic [LINE_WORD_NUM-1:0][DATA_WIDTH-1:0] line_t;//每一路一个cache_line

function index_t get_index( input logic [31:0] addr );
    return addr[OFFSET_WIDTH + INDEX_WIDTH - 1 : OFFSET_WIDTH];
endfunction

function tag_t get_tag( input logic [31:0] addr );
    return addr[31 : OFFSET_WIDTH + INDEX_WIDTH];
endfunction

function offset_t get_offset( input logic [31:0] addr );
    return addr[OFFSET_WIDTH - 1 : 0];
endfunction



function logic [31:0] mux_byteenable(
    input logic [31:0] rdata,
    input logic [31:0] wdata,
    input logic [3:0] sel 
);
    return { 
        sel[3] ? wdata[31:24] : rdata[31:24],
        sel[2] ? wdata[23:16] : rdata[23:16],
        sel[1] ? wdata[15:8] : rdata[15:8],
        sel[0] ? wdata[7:0] : rdata[7:0]
    };
endfunction

typedef enum logic [3:0] { 
    `ifdef Dcache

        MISSDIRTY,
        WRITEBACK,//之后加入fifo就不用这个装态了

        REQ，
        WAIT，
    `endif

        LOOKUP,
        MISSCLEAN,
        REFILL
} state_t;

`ifdef Dcache
    typedef enum logic [2:0] { 
        WB_IDLE,
        WB_STORE
    } wb_state_t;
`endif 

state_t state,state_next;
`ifdef Dcache
    wb_state_t wb_state,wb_state_next;
`endif 


endmodule