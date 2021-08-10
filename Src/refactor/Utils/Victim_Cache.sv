// /*
//  * @Author: your name
//  * @Date: 2021-08-08 11:23:21
//  * @LastEditTime: 2021-08-10 10:09:48
//  * @LastEditors: Please set LastEditors
//  * @Description: In User Settings Edit
//  * @FilePath: \gitlab\Src\refactor\Utils\Victim_Cache.sv
//  */ 
// module Victim_Cache #(
//     parameter SIZE = 4,
//     parameter INDEX_WIDTH = 6,
//     parameter TAG_WIDTH  = 20,
//     parameter ASSOC_NUM = 2,
//     parameter LINE = ;
// ) (
//     input logic clk,
//     input logic resetn,
//     input logic[INDEX_WIDTH-1:0] index,
//     input logic we,
//     input logic[TAG_WIDTH+1-1:0] tagv_wdata,
//     input logic []
//     output logic[TAG_WIDTH+1-1:0] tagv_rdata
// );
    
// typedef struct packed {
//     logic valid;
//     logic [TAG_WIDTH-1:0] tag;  
// } tagv_t; //每一路 一个tag_t变量

// //
// simple_port_lutram  #(
//     .SIZE(SIZE),
//     .dtype(tagv_t)
// ) mem_tag(
//     .clka(clk),
//     .rsta(~resetn),

//     //端口信号
//     .ena(1'b1),
//     .wea(we),
//     .addra(index[$clog2(SIZE)-1:0]),
//     .dina(tagv_wdata),
//     .douta(tagv_rdata)
// );

//     simple_port_ram #(
//         .SIZE(SET_NUM)
//     )mem_data(
//         .clk(clk),
//         .rst(~resetn),

//         //写端�?
//         .ena(1'b1),
//         .wea(data_we[i][j]),
//         .addra(write_addr),
//         .dina(data_wdata[j]),

//         //读端�?
//         .enb(data_read_en),
//         .addrb(read_addr),
//         .doutb(data_rdata[i][j])
//     );

// endmodule