/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-07-31 23:08:35
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\ICache.sv
 */
//重写之后的Cache Icache Dcache复用一个设计
`include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
//`define Dcache  //如果是DCache就在文件中使用这个宏
`define CLOG2(x) \
((x <= 1) || (x > 512)) ? 0 : \
(x <= 2) ? 1 : \
(x <= 4) ? 2 : \
(x <= 8) ? 3 : \
(x <= 16) ? 4 : \
(x <= 32) ? 5 : \
(x <= 64) ? 6 : \
(x <= 128) ? 7: \
(x <= 256) ? 8: \
(x <= 512) ? 9 : 0

module Icache #(
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
    // input  PhysicalAddressType phsy_addr,现在移到cpu_bus中
    // input  logic isCache,


    AXI_UNCACHE_Interface axi_ubus,

    CPU_Bus_Interface  cpu_bus,//slave
    AXI_Bus_Interface  axi_bus //master
    
    
);
//parameters
localparam int unsigned BYTES_PER_WORD = 4;
localparam int unsigned INDEX_WIDTH    = $clog2(SET_NUM) ;
localparam int unsigned OFFSET_WIDTH   = $clog2(LINE_WORD_NUM*BYTES_PER_WORD);//
localparam int unsigned TAG_WIDTH      = 32-INDEX_WIDTH-OFFSET_WIDTH ;


//--definitions
typedef struct packed {
    logic valid;
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



typedef enum logic [3:0] { 
        REQ,
        WAIT,
        UNCACHEDONE,

        LOOKUP,
        MISSCLEAN,
        REFILL,
        REFILLDONE
} state_t;




typedef struct packed {
    logic             valid;
    logic             op;
    tag_t             tag;
    index_t           index;
    offset_t          offset;
    logic             isCache;
} request_t;





//declartion
state_t state,state_next;

logic [31:0] uncache_rdata;

index_t read_addr;//read_addr 既是 查询的地址 又是重填的地址  write_addr是store的地址

tagv_t [ASSOC_NUM-1:0] tagv_rdata;
tagv_t tagv_wdata;
we_t tagv_we;// 重填的时候写使能


line_t [ASSOC_NUM-1:0] data_rdata;
logic [ASSOC_NUM-1:0][31:0] data_rdata_sel;
logic [31:0] data_rdata_final;//

logic data_read_en;//读使能
line_t data_wdata;
we_t  data_we;//数据表的写使能

request_t req_buffer;
logic req_buffer_en;

logic [SET_NUM-1:0][$clog2(ASSOC_NUM)-1:0] lru;
logic [ASSOC_NUM-1:0] hit;
logic cache_hit;

tagv_t [ASSOC_NUM-1:0] pipe_tagv_rdata;
logic pipe_wr;

logic busy_cache;// uncache 直到数据返回
logic busy_uncache;
logic busy;



//连cpu_bus接口
assign cpu_bus.busy   = busy;
assign cpu_bus.rdata  = (req_buffer.valid)?data_rdata_final:'0;

//连axi_bus接口
assign axi_bus.rd_req  = (state == MISSCLEAN) ? 1'b1:1'b0;
assign axi_bus.rd_addr = {req_buffer.tag , req_buffer.index, {OFFSET_WIDTH{1'b0}}};


//连axi_ubus接口
assign axi_ubus.rd_req   = (state == REQ && req_buffer.op==0) ? 1'b1:1'b0;
assign axi_ubus.rd_addr  = {req_buffer.tag , req_buffer.index, req_buffer.offset};

//generate
generate;
    for (genvar i = 0;i<ASSOC_NUM ;i++ ) begin
        simple_port_lutram  #(
            .SIZE(SET_NUM),
            .dtype(tagv_t)
        ) mem_tag(
            .clka(clk),
            .rsta(~resetn),

            //端口信号
            .ena(1'b1),
            .wea(tagv_we[i]),
            .addra(read_addr),
            .dina(tagv_wdata),
            .douta(tagv_rdata[i])
        );
        simple_port_ram #(
            .SIZE(SET_NUM),
            .dtype(line_t)
        )mem_data(
            .clk(clk),
            .rst(~resetn),

            //写端口
            .ena(1'b1),
            .wea(data_we[i]),
            .addra(read_addr),
            .dina(data_wdata),

            //读端口
            .enb(data_read_en),
            .addrb(read_addr),
            .doutb(data_rdata[i])
        );
    end
endgenerate

generate;//PLRU 
    for (genvar  i=0; i<SET_NUM; i++) begin
        PLRU #(
            .ASSOC_NUM(ASSOC_NUM)
        ) plru_reg(
            .clk(clk),
            .resetn(resetn),
            .access(hit),
            .update(req_buffer.valid && i[INDEX_WIDTH-1:0] == req_buffer.index),

            .lru(lru[i])
        );
    end
endgenerate

generate;//判断命中
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign hit[i] = ( pipe_tagv_rdata[i].valid & (req_buffer.tag == pipe_tagv_rdata[i].tag) )  ;
    end
endgenerate

generate;//根据offset片选？
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign data_rdata_sel[i] = data_rdata[i][req_buffer.offset[OFFSET_WIDTH-1:2]];
    end
endgenerate
assign data_read_en     = (state == REFILLDONE) ? 1'b1 : (cpu_bus.stall)? 1'b0:1'b1;
//旁路
                            //
assign data_rdata_final = (req_buffer.valid)?  (state == UNCACHEDONE )? uncache_rdata:data_rdata_sel[`CLOG2(hit)]: '0;
assign cache_hit = |hit;

assign read_addr      = (state == REFILLDONE || state == REFILL )? req_buffer.index : cpu_bus.index;


assign busy_cache     = (req_buffer.valid & ~cache_hit & req_buffer.isCache) ? 1'b1:1'b0;
assign busy_uncache   = (req_buffer.valid & (~req_buffer.isCache) & (state != UNCACHEDONE) ) ?1'b1 :1'b0;

assign busy           = busy_cache | busy_uncache;

assign pipe_wr        = (state == REFILLDONE) ? 1'b1:(cpu_bus.stall)?1'b0:1'b1;

assign req_buffer_en  = (cpu_bus.stall)? 1'b0:1'b1 ;

assign data_wdata =  axi_bus.ret_data ;
assign tagv_wdata =  {1'b1,req_buffer.tag} ;




always_comb begin : tagv_we_blockName
    if (state == REFILL) begin
        tagv_we = '0;
        tagv_we[lru[req_buffer.index]] =1'b1;
    end else begin
        tagv_we = '0;
    end
end
always_comb begin : data_we_blockName
    if (state == REFILL) begin
        data_we = '0;
        data_we[lru[req_buffer.index]] =1'b1;
    end else begin
        data_we = '0;
    end    
end


always_ff @(posedge clk) begin : req_buffer_blockName
    if (resetn == `RstEnable) begin
        req_buffer <='0;
    end else if(req_buffer_en) begin
        req_buffer.valid    <=  cpu_bus.valid;
        req_buffer.op       <=  cpu_bus.op;
        req_buffer.tag      <=  cpu_bus.tag;
        req_buffer.index    <=  cpu_bus.index;
        req_buffer.offset   <=  cpu_bus.offset;
        req_buffer.isCache  <=  cpu_bus.isCache;
    end else begin
        req_buffer <= req_buffer;
    end
end

always_ff @( posedge clk ) begin : uncache_rdata_blockName//更新uncache读出来的值
    if (axi_ubus.ret_valid) begin
        uncache_rdata <= axi_ubus.ret_data;
    end else begin
        uncache_rdata <= uncache_rdata;
    end
end

generate;//锁存读出的tag
    for (genvar  i=0; i<ASSOC_NUM; i++) begin
    always_ff @( posedge clk ) begin : pipe_tagv_rdata_blockName
        if (pipe_wr) begin
            pipe_tagv_rdata[i].tag   <= tagv_rdata[i].tag;
            pipe_tagv_rdata[i].valid <= tagv_rdata[i].valid ;
        end else begin
            pipe_tagv_rdata[i].tag   <= pipe_tagv_rdata[i].tag;
            pipe_tagv_rdata[i].valid <= pipe_tagv_rdata[i].valid ;        
        end
    end        
    end
endgenerate

always_ff @( posedge clk ) begin : state_blockName
    if (resetn == `RstEnable) begin
        state <= LOOKUP;
    end else begin
        state <= state_next;
    end
end

always_comb begin : state_next_blockname
    state_next =LOOKUP;

    unique case (state)
        LOOKUP:begin
            if (req_buffer.isCache == 1'b0 && req_buffer.valid) begin
                state_next = REQ;
            end else begin
            if (~cache_hit & req_buffer.valid) begin
                state_next = MISSCLEAN;
            end else begin
                state_next = LOOKUP ;
            end
            end              
        end
        MISSCLEAN:begin
            if (axi_bus.rd_rdy) begin//可以读
                state_next = REFILL;
            end else begin
                state_next = MISSCLEAN;
            end
        end
        REFILL:begin
            if (axi_bus.ret_valid) begin//值合法
                state_next = REFILLDONE;
            end else begin
                state_next = REFILL;
            end
        end
        REFILLDONE:begin
                state_next = LOOKUP;
            
        end
        REQ:begin
            if (req_buffer.op == 1'b0) begin//uncache读
                if (axi_ubus.rd_rdy) begin
                    state_next = WAIT;
                end else begin
                    state_next = REQ;
                end
            end else begin//uncache写
                if (axi_ubus.wr_rdy) begin
                    state_next = WAIT;
                end else begin
                    state_next = REQ;
                end
            end
        end
        WAIT:begin
            if (req_buffer.op == 1'b0) begin//uncache读
                if (axi_ubus.ret_valid) begin
                    state_next = UNCACHEDONE;
                end else begin
                    state_next = WAIT;
                end
            end else begin//uncache写
                if (axi_ubus.wr_valid) begin
                    state_next = UNCACHEDONE;
                end else begin
                    state_next = WAIT;
                end
            end
        end
        UNCACHEDONE:begin
            if (cpu_bus.stall) begin
                state_next = UNCACHEDONE;
            end else begin
                state_next = LOOKUP;
            end
             
        end
        default: begin
            state_next =LOOKUP;
        end
    endcase
end


endmodule