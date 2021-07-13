/*
 * @Author: your name
 * @Date: 2021-06-29 23:11:11
 * @LastEditTime: 2021-07-13 20:41:42
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

        MISSDIRTY,
        WRITEBACK,//之后加入fifo就不用这个装态了

        REQ,
        WAIT,
        UNCACHEDONE,

        LOOKUP,
        MISSCLEAN,
        REFILL,
        REFILLDONE
} state_t;


typedef enum logic [2:0] { 
        WB_IDLE,
        WB_STORE
} wb_state_t;


typedef struct packed {
    logic             valid;
    logic             op;
    tag_t             tag;
    index_t           index;
    offset_t          offset;
    logic[3:0]        wstrb; //写使能
    logic[31:0]       wdata; //store数据
    LoadType          loadType;//load类型
    logic             isCache;
} request_t;


typedef struct packed {//store指令在读数的时候根据写使能替换
    logic [ASSOC_NUM-1:0] hit;
    index_t index;
    line_t  wdata;
} store_t;

//
`ifdef Dcache

`endif

//declartion
store_t store_buffer; //如果有写冲突 直接阻塞
line_t store_wdata;
state_t state,state_next;

wb_state_t wb_state,wb_state_next;
 
logic [31:0] uncache_rdata;

index_t read_addr,write_addr;//read_addr 既是 查询的地址 又是重填的地址  write_addr是store的地址

tagv_t [ASSOC_NUM-1:0] tagv_rdata;
tagv_t tagv_wdata;
we_t tagv_we;// 重填的时候写使能

we_t wb_we;//store的写使能

line_t [ASSOC_NUM-1:0] data_rdata;
line_t data_wdata;
we_t  data_we;//数据表的写使能

request_t req_buffer;
logic req_buffer_en;

logic [SET_NUM-1:0][$clog2(ASSOC_NUM)-1:0] lru;
logic [ASSOC_NUM-1:0] hit;
logic cache_hit;

tagv_t pipe_tagv_rdata;
logic pipe_wr;

logic busy_cache;// uncache 直到数据返回
logic busy_uncache;
logic busy_collision;

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
            .addra(write_addr),
            .dina(data_wdata),

            //读端口
            .enb(cpu_bus.valid & (~busy)),
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
            .update(req_buffer.valid),

            .lru(lru[i])
        );
    end
endgenerate

generate;//判断命中
    for (genvar i=0; i<ASSOC_NUM; i++) begin
        assign hit[i] = pipe_tagv_rdata[i].valid & (req_buffer.tag == pipe_tagv_rdata[i].tag);
    end
endgenerate
assign cache_hit = |hit;

assign read_addr      = (state == REFILLDONE)? req_buffer.index : cpu_bus.index;
assign write_addr     = (state == REFILL)?req_buffer.index : store_buffer.index;


assign busy_cache     = (cache_hit & req_buffer.isCache) ? 1'b0:1'b1;
assign busy_uncache   = ( (~req_buffer.isCache) & (state == UNCACHEDONE) ) ?1'b0 :1'b1;
assign busy_collision = (store_buffer.index == read_addr)? 1'b1:1'b0;
assign busy           = busy_cache | busy_uncache | busy_collision;

assign pipe_wr        = (~(busy) | state == REFILLDONE) ? 1'b1:1'b0;

assign req_buffer_en = (busy | cpu_bus.stall)? 1'b0:1'b1 ;

assign data_wdata = (state == REFILL)? axi_bus.ret_data : store_buffer.wdata;
assign tagv_wdata = (state == REFILL)? {1'b1,1'b0,req_buffer.tag} :{1'b1,1'b1,store_buffer.tag};


// always_comb begin : store_wdata_block
//     unique casez(hit)
        


// end

always_comb begin : tagv_we_blockName
    if (state == REFILL) begin
        tagv_we = '0;
        tagv_we[lru[req_buffer.index]] =1'b1;
    end else begin
        tagv_we = store_buffer.hit;
    end
end
always_comb begin : data_we_blockName
    if (state == REFILL) begin
        data_we = '0;
        data_we[lru[req_buffer.index]] =1'b1;
    end else begin
        data_we = store_buffer.hit;
    end    
end
always_ff @( posedge clk ) begin : store_buffer_blockName
    if ((resetn == `RstEnable) ||(cpu_bus.stall | busy) ) begin
        store_buffer <= '0;
    end else if(req_buffer.op & req_buffer.valid & cache_hit) begin//既是写 又是有效的
        store_buffer.hit <= hit;
        store_buffer.index <= req_buffer.index;
        store_buffer.index <= store_wdata;
    end else begin
        store_buffer <= '0;
    end
end

always_ff @(posedge clk) begin : req_buffer_blockName
    if (resetn == `RstEnable || cpu_bus.flush) begin
        req_buffer <='0;
    end else if(req_buffer_en) begin
        req_buffer.valid    <=  cpu_bus.valid;
        req_buffer.op       <=  cpu_bus.op;
        req_buffer.tag      <=  cpu_bus.tag;
        req_buffer.index    <=  cpu_bus.index;
        req_buffer.offset   <=  cpu_bus.offset;
        req_buffer.wstrb    <=  cpu_bus.wstrb;
        req_buffer.wdata    <=  cpu_bus.wdata;
        req_buffer.loadType <=  cpu_bus.loadType;
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

always_ff @( posedge clk ) begin : pipe_tagv_rdata_blockName
    if (pipe_wr) begin
        pipe_tagv_rdata.tag   <= tagv_rdata.tag;
        pipe_tagv_rdata.dirty <= tagv_rdata.dirty ;
        pipe_tagv_rdata.valid <= tagv_rdata.valid ;
    end else begin
        pipe_tagv_rdata.tag   <= pipe_tagv_rdata.tag;
        pipe_tagv_rdata.dirty <= pipe_tagv_rdata.dirty ;
        pipe_tagv_rdata.valid <= pipe_tagv_rdata.valid ;        
    end
end

always_ff @( posedge clk ) begin : state_blockName
    if (resetn == `RstEnable) begin
        state <= LOOKUP;
    end else begin
        state <= state_next;
    end
end

always_comb begin : state_next_blockname
    state =LOOKUP;

    unique case (state)
        LOOKUP:begin
            if (req_buffer.isCache == 1'b0) begin
                state_next = REQ;
            end else begin
            if (cache_hit) begin
                state_next = LOOKUP;
            end else begin
                if (pipe_tagv_rdata.dirty) begin
                    state_next = MISSDIRTY ;
                end else begin
                    state_next = MISSCLEAN ;
                end
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
        MISSDIRTY:begin
            if (axi_bus.wr_rdy) begin
                state_next = WRITEBACK;
            end else begin
                state_next =  MISSDIRTY;
            end
        end
        WRITEBACK:begin
            if (axi_bus.wr_valid) begin
                state_next = MISSCLEAN;
            end else begin
                state_next = WRITEBACK;
            end
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
            state =LOOKUP;
        end
    endcase
end


endmodule