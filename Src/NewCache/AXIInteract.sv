/*
 * @Author: your name
 * @Date: 2021-07-06 19:58:31
 * @LastEditTime: 2021-07-09 15:37:14
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \NewCache\AXI.sv
 */
`include "Cache_Defines.svh"
`include "CPU_Defines.svh"

module AXIInteract #(
    parameter ICACHE_LINE_SIZE=8,//icache块大小
    parameter DCACHE_LINE_SIZE=8 //dcache块大小
) (
    //external signals
    input logic clk,
    input logic resetn,
    //interface with cache
    AXI_Bus_Interface ibus,
    AXI_Bus_Interface dbus,

    AXI_UNCACHE_Interface uibus,
    AXI_UNCACHE_Interface udbus,


    //signals with axi bus
    output logic [ 3: 0] m_axi_arid,
    output logic [31: 0] m_axi_araddr,
    output logic [ 3: 0] m_axi_arlen,
    output logic [ 2: 0] m_axi_arsize,
    output logic [ 1: 0] m_axi_arburst,
    output logic [ 1: 0] m_axi_arlock,
    output logic [ 3: 0] m_axi_arcache,
    output logic [ 2: 0] m_axi_arprot,
    output logic         m_axi_arvalid,
    input  logic         m_axi_arready,
    input  logic [ 3: 0] m_axi_rid,
    input  logic [31: 0] m_axi_rdata,
    input  logic [ 1: 0] m_axi_rresp,
    input  logic         m_axi_rlast,
    input  logic         m_axi_rvalid,
    output logic         m_axi_rready,
    output logic [ 3: 0] m_axi_awid,
    output logic [31: 0] m_axi_awaddr,
    output logic [ 3: 0] m_axi_awlen,
    output logic [ 2: 0] m_axi_awsize,
    output logic [ 1: 0] m_axi_awburst,
    output logic [ 1: 0] m_axi_awlock,
    output logic [ 3: 0] m_axi_awcache,
    output logic [ 2: 0] m_axi_awprot,
    output logic         m_axi_awvalid,
    input  logic         m_axi_awready,
    output logic [ 3: 0] m_axi_wid,
    output logic [31: 0] m_axi_wdata,
    output logic [ 3: 0] m_axi_wstrb,
    output logic         m_axi_wlast,
    output logic         m_axi_wvalid,
    input  logic         m_axi_wready,
    input  logic [ 3: 0] m_axi_bid,
    input  logic [ 1: 0] m_axi_bresp,
    input  logic         m_axi_bvalid,
    output logic         m_axi_bready
);
// Icache 
    logic [ 3: 0] ibus_arid;
    logic [31: 0] ibus_araddr;
    logic [ 3: 0] ibus_arlen;
    logic [ 2: 0] ibus_arsize;
    logic [ 1: 0] ibus_arburst;
    logic [ 1: 0] ibus_arlock;
    logic [ 3: 0] ibus_arcache;
    logic [ 2: 0] ibus_arprot;
    logic         ibus_arvalid;
    logic         ibus_arready;
    logic [ 3: 0] ibus_rid;
    logic [31: 0] ibus_rdata;
    logic [ 1: 0] ibus_rresp;
    logic         ibus_rlast;
    logic         ibus_rvalid;
    logic         ibus_rready;
    logic [ 3: 0] ibus_awid;
    logic [31: 0] ibus_awaddr;
    logic [ 3: 0] ibus_awlen;
    logic [ 2: 0] ibus_awsize;
    logic [ 1: 0] ibus_awburst;
    logic [ 1: 0] ibus_awlock;
    logic [ 3: 0] ibus_awcache;
    logic [ 2: 0] ibus_awprot;
    logic         ibus_awvalid;
    logic         ibus_awready;
    logic [ 3: 0] ibus_wid;
    logic [31: 0] ibus_wdata;
    logic [ 3: 0] ibus_wstrb;
    logic         ibus_wlast;
    logic         ibus_wvalid;
    logic         ibus_wready;
    logic [ 3: 0] ibus_bid;
    logic [ 1: 0] ibus_bresp;
    logic         ibus_bvalid;
    logic         ibus_bready;

// Dcache 
    logic [ 3: 0] dbus_arid;
    logic [31: 0] dbus_araddr;
    logic [ 3: 0] dbus_arlen;
    logic [ 2: 0] dbus_arsize;
    logic [ 1: 0] dbus_arburst;
    logic [ 1: 0] dbus_arlock;
    logic [ 3: 0] dbus_arcache;
    logic [ 2: 0] dbus_arprot;
    logic         dbus_arvalid;
    logic         dbus_arready;
    logic [ 3: 0] dbus_rid;
    logic [31: 0] dbus_rdata;
    logic [ 1: 0] dbus_rresp;
    logic         dbus_rlast;
    logic         dbus_rvalid;
    logic         dbus_rready;
    logic [ 3: 0] dbus_awid;
    logic [31: 0] dbus_awaddr;
    logic [ 3: 0] dbus_awlen;
    logic [ 2: 0] dbus_awsize;
    logic [ 1: 0] dbus_awburst;
    logic [ 1: 0] dbus_awlock;
    logic [ 3: 0] dbus_awcache;
    logic [ 2: 0] dbus_awprot;
    logic         dbus_awvalid;
    logic         dbus_awready;
    logic [ 3: 0] dbus_wid;
    logic [31: 0] dbus_wdata;
    logic [ 3: 0] dbus_wstrb;
    logic         dbus_wlast;
    logic         dbus_wvalid;
    logic         dbus_wready;
    logic [ 3: 0] dbus_bid;
    logic [ 1: 0] dbus_bresp;
    logic         dbus_bvalid;
    logic         dbus_bready;

// Uncache icache
    logic [ 3: 0] uibus_arid;
    logic [31: 0] uibus_araddr;
    logic [ 3: 0] uibus_arlen;
    logic [ 2: 0] uibus_arsize;
    logic [ 1: 0] uibus_arburst;
    logic [ 1: 0] uibus_arlock;
    logic [ 3: 0] uibus_arcache;
    logic [ 2: 0] uibus_arprot;
    logic         uibus_arvalid;
    logic         uibus_arready;
    logic [ 3: 0] uibus_rid;
    logic [31: 0] uibus_rdata;
    logic [ 1: 0] uibus_rresp;
    logic         uibus_rlast;
    logic         uibus_rvalid;
    logic         uibus_rready;
    logic [ 3: 0] uibus_awid;
    logic [31: 0] uibus_awaddr;
    logic [ 3: 0] uibus_awlen;
    logic [ 2: 0] uibus_awsize;
    logic [ 1: 0] uibus_awburst;
    logic [ 1: 0] uibus_awlock;
    logic [ 3: 0] uibus_awcache;
    logic [ 2: 0] uibus_awprot;
    logic         uibus_awvalid;
    logic         uibus_awready;
    logic [ 3: 0] uibus_wid;
    logic [31: 0] uibus_wdata;
    logic [ 3: 0] uibus_wstrb;
    logic         uibus_wlast;
    logic         uibus_wvalid;
    logic         uibus_wready;
    logic [ 3: 0] uibus_bid;
    logic [ 1: 0] uibus_bresp;
    logic         uibus_bvalid;
    logic         uibus_bready;

// Uncache 
    logic [ 3: 0] udbus_arid;
    logic [31: 0] udbus_araddr;
    logic [ 3: 0] udbus_arlen;
    logic [ 2: 0] udbus_arsize;
    logic [ 1: 0] udbus_arburst;
    logic [ 1: 0] udbus_arlock;
    logic [ 3: 0] udbus_arcache;
    logic [ 2: 0] udbus_arprot;
    logic         udbus_arvalid;
    logic         udbus_arready;
    logic [ 3: 0] udbus_rid;
    logic [31: 0] udbus_rdata;
    logic [ 1: 0] udbus_rresp;
    logic         udbus_rlast;
    logic         udbus_rvalid;
    logic         udbus_rready;
    logic [ 3: 0] udbus_awid;
    logic [31: 0] udbus_awaddr;
    logic [ 3: 0] udbus_awlen;
    logic [ 2: 0] udbus_awsize;
    logic [ 1: 0] udbus_awburst;
    logic [ 1: 0] udbus_awlock;
    logic [ 3: 0] udbus_awcache;
    logic [ 2: 0] udbus_awprot;
    logic         udbus_awvalid;
    logic         udbus_awready;
    logic [ 3: 0] udbus_wid;
    logic [31: 0] udbus_wdata;
    logic [ 3: 0] udbus_wstrb;
    logic         udbus_wlast;
    logic         udbus_wvalid;
    logic         udbus_wready;
    logic [ 3: 0] udbus_bid;
    logic [ 1: 0] udbus_bresp;
    logic         udbus_bvalid;
    logic         udbus_bready;
    //cache 状态机
    typedef enum logic[3:0] { 
        IDLE,
        REQ,
        WAIT,
        FINISH
    }cache_rd_t;//通用的cache

    typedef enum logic[3:0] { 
        WB_IDLE,
        WB_REQ,
        WB_WAIT,
        WB_FINISH
    }cache_wb_t;//通用的写回cache 实际上只用dcache使用

    typedef enum logic[3:0] { 
        UNCACHE_IDLE,
        UNCACHE_RD,
        UNCACHE_WB,
        UNCACHE_WAIT,
        UNCACHE_FINISH
    } uncache_t;//通用的uncache机制 icache可能读 dcache会读会写




    localparam int  ICACHE_CNT_WIDTH = $clog2(ICACHE_LINE_SIZE*2);//icache的计数器的位宽
    localparam int  DCACHE_CNT_WIDTH = $clog2(DCACHE_LINE_SIZE*2);//dcache的计数器的位宽

    cache_rd_t istate,istate_next;
    cache_rd_t dstate,dstate_next;
    
//  cache_wb_t istate_wb,istate_wb_next;
    cache_wb_t dstate_wb,dstate_wb_next;

    uncache_t istate_uncache,istate_uncache_next;
    uncache_t dstate_uncache,dstate_uncache_next;

    logic [ICACHE_CNT_WIDTH-1:0] iburst_cnt,iburst_cnt_next;//读计数器
    logic [DCACHE_CNT_WIDTH-1:0] dburst_cnt,dburst_cnt_next;//dcache计数器

    logic [DCACHE_CNT_WIDTH-2:0] wb_dburst_cnt,wb_dburst_cnt_next;//写计数器

    logic [31:0] icache_rd_addr;
    logic [ICACHE_LINE_SIZE*2-1:0][31:0] icache_line_recv;//读的块大小为两倍的cache line size

    logic [31:0] dcache_rd_addr;
    logic [DCACHE_LINE_SIZE*2-1:0][31:0] dcache_line_recv;

    logic [31:0] dcache_wb_addr;
    logic [DCACHE_LINE_SIZE-1:0] dcache_line_wb;

    always_ff @( posedge clk ) begin : istate_block
        if (resetn == `RstEnable) begin
            istate <= IDLE;
        end else begin
            istate <= istate_next;
        end
        
    end
    
    always_comb begin : istate_next_block
        istate_next = IDLE;

        unique case (istate)
            IDLE:begin
                if (ibus.rd_req) begin
                    istate_next = REQ;
                end else begin
                    istate_next = IDLE;
                end
            end
            REQ:begin
                if (ibus_arready) begin
                    istate_next = WAIT;
                end else begin
                    istate_next = REQ;
                end
            end
            WAIT:begin
                if (ibus_rlast &ibus_rvalid) begin
                    istate_next = FINISH;
                end else begin
                    istate_next = WAIT;
                end
            end
            FINISH:begin
                istate_next =IDLE;
            end
        endcase
    end

// icache读计数器  如果不在req状态计数器将清零
    always_ff @(posedge clk ) begin : iburst_cnt_block
        if (resetn == `RstEnable | istate==REQ ) begin
            iburst_cnt <= '0;
        end else begin
            iburst_cnt <= iburst_cnt_next;
        end
    end

    always_comb begin : iburst_cnt_next_block
        if (ibus_rvalid) begin
            iburst_cnt_next = iburst_cnt +1;
        end else begin
            iburst_cnt_next = iburst_cnt;
        end
    end
//对于icache读地址的控制
    always_ff @(posedge clk ) begin : icache_rd_addr_block
        if (resetn == `RstEnable) begin
            icache_rd_addr <='0;
        end else if (istate == REQ) begin
            icache_rd_addr <= icache_rd_addr;
        end else begin
            icache_rd_addr <= ibus.rd_addr;
        end
    end
//对于icache读出数据的锁存
    always_ff @(posedge clk ) begin : icache_line_recv_block
        if (resetn == `RstEnable) begin
            icache_line_recv <='0;
        end else begin
            icache_line_recv[iburst_cnt] <= ibus_rdata;
        end
    end

    /********************* ibus ******************/
    // master -> slave
    assign ibus_arid      = '0;
    assign ibus_arlen     = ICACHE_LINE_SIZE*2;      // 传输4拍
    assign ibus_arsize    = 3'b010;       // 每次传输4字节
    assign ibus_arburst   = 2'b01;
    assign ibus_arlock    = '0;
    assign ibus_arcache   = '0;
    assign ibus_arprot    = '0;
    

    // master -> slave
    assign ibus_awid      = '0;           
    assign ibus_awlen     = '0;
    assign ibus_awsize    = '0;
    assign ibus_awburst   = '0;
    assign ibus_awlock    = '0;
    assign ibus_awcache   = '0;
    assign ibus_awprot    = '0;
    assign ibus_awvalid   = '0;
    assign ibus_awaddr    = '0;
    // master -> slave
    assign ibus_wid       = '0;
    assign ibus_wdata     = '0;
    assign ibus_wstrb     = '0;
    assign ibus_wlast     = '0;
    assign ibus_wvalid    = '0;
    assign ibus_bready    = '0;
    //发送命令
    assign ibus_arvalid   = (istate == REQ) ? 1'b1 : 1'b0;
    assign ibus_araddr    = icache_rd_addr;
    assign ibus_rready    = (istate == WAIT) ? 1'b1 : 1'b0;

    //ibus上的赋值
    assign ibus.ret_valid = (istate == FINISH) ? 1'b1 : 1'b0;
    assign ibus.ret_data  = icache_line_recv;


//dcache读状态机
     always_ff @( posedge clk ) begin : dstate_block
        if (resetn == `RstEnable) begin
            dstate <= IDLE;
        end else begin
            dstate <= dstate_next;
        end
        
    end
    
    always_comb begin : dstate_next_block
        dstate_next = IDLE;

        unique case (dstate)
            IDLE:begin
                if (dbus.rd_req) begin
                    dstate_next = REQ;
                end else begin
                    dstate_next = IDLE;
                end
            end
            REQ:begin
                if (dbus_arready) begin
                    dstate_next = WAIT;
                end else begin
                    dstate_next = REQ;
                end
            end
            WAIT:begin
                if (dbus_rlast &dbus_rvalid) begin
                    dstate_next = FINISH;
                end else begin
                    dstate_next = WAIT;
                end
            end
            FINISH:begin
                dstate_next =IDLE;
            end
        endcase
    end

// icache读计数器  如果不在req状态计数器将清零
    always_ff @(posedge clk ) begin : dburst_cnt_block
        if (resetn == `RstEnable | dstate==REQ ) begin
            dburst_cnt <= '0;
        end else begin
            dburst_cnt <= dburst_cnt_next;
        end
    end

    always_comb begin : dburst_cnt_next_block
        if (dbus_rvalid) begin
            dburst_cnt_next = dburst_cnt +1;
        end else begin
            dburst_cnt_next = dburst_cnt;
        end
    end
//对于dcache读地址的控制
    always_ff @(posedge clk ) begin : dcache_rd_addr_block
        if (resetn == `RstEnable) begin
            dcache_rd_addr <='0;
        end else if (dstate == REQ) begin
            dcache_rd_addr <= dcache_rd_addr;
        end else begin
            dcache_rd_addr <= dbus.rd_addr;
        end
    end
//对于dcache读出数据的锁存
    always_ff @(posedge clk ) begin : dcache_line_recv_block
        if (resetn == `RstEnable) begin
            dcache_line_recv <='0;
        end else begin
            dcache_line_recv[dburst_cnt] <= dbus_rdata;
        end
    end
/********************* dbus ******************/
    assign dbus_arid      = 4'b0001;
    assign dbus_arlen     = DCACHE_LINE_SIZE*2;//一次读两个cache line
    assign dbus_arsize    = 3'b010;
    assign dbus_arburst   = 2'b01;
    assign dbus_arlock    = '0;
    assign dbus_arcache   = '0;
    assign dbus_arprot    = '0;


    assign dbus_awid      = 4'b0001;
    assign dbus_awlen     = DCACHE_LINE_SIZE;        // 写的话还是一块一块写
    assign dbus_awsize    = 3'b010;         // 传输32bit 
    assign dbus_awburst   = 2'b01;          // increase模式
    assign dbus_awlock    = '0;
    assign dbus_awcache   = '0;
    assign dbus_awprot    = '0;


    assign dbus_wid       = 4'b0001;
    assign dbus_wstrb     = 4'b1111;
    assign dbus_bready    = 1'b1;

    //发送命令
    assign dbus_arvalid   = (dstate == REQ) ? 1'b1 :1'b0;
    assign dbus_araddr    = dcache_rd_addr;
    assign dbus_rready    = (dstate == WAIT) ? 1'b1 : 1'b0;
    assign dbus_wdata     = dcache_line_wb[wb_dburst_cnt];
    assign dbus_wlast     = (wb_dburst_cnt == { (DCACHE_CNT_WIDTH/2) {1'b1} } ) ? 1'b1 : 1'b0;
    //dbus上的赋值
    assign dbus.ret_valid = (dstate == FINISH)? 1'b1:1'b0;
    assign dbus.ret_data  = dcache_line_recv;

//dcache写状态机 因为write buffer的存在 所以没法和uncache共用一个通道
    always_ff @( posedge clk ) begin : dstate_wb_block
        if (resetn == `RstEnable) begin
            dstate_wb <=  WB_IDLE;
        end else begin
            dstate_wb <= dstate_wb_next;
        end
    end

    always_comb begin : dstate_wb_next_block
        dstate_wb_next = WB_IDLE;

        unique case (dstate_wb)
            WB_IDLE:begin
                if (dbus.wr_req) begin
                    dstate_wb_next = WB_REQ;
                end else begin
                    dstate_wb_next = WB_IDLE;
                end
            end
            WB_REQ:begin
                if (dbus_awready ) begin
                    dstate_wb_next = WB_WAIT;
                end else begin
                    dstate_wb_next = WB_REQ;
                end
            end
            WB_WAIT:begin
                if (dbus_wready == 1'b1 && dbus_wlast == 1'b1 ) begin
                    dstate_wb_next = WB_FINISH;
                end else begin
                    dstate_wb_next = WB_WAIT;
                end
            end
            WB_FINISH:begin
                if (dbus_bvalid) begin
                    dstate_wb_next = WB_IDLE;
                end else begin
                    dstate_wb_next = WB_FINISH;
                end
            end
        endcase
    end

//dcache 写计数器 如果不在req状态 计数器将被清零
    always_ff @( posedge clk ) begin : wb_dburst_cnt_block
        if (resetn == `RstEnable | dstate_wb==WB_REQ) begin
            wb_dburst_cnt <= '0;
        end else begin
            wb_dburst_cnt <= wb_dburst_cnt_next;
        end
    end

    always_comb begin : wb_dburst_cnt_next_block
        if (dbus_wready) begin
            wb_dburst_cnt_next = wb_dburst_cnt + 1;
        end else begin
            wb_dburst_cnt_next = wb_dburst_cnt;
        end
    end
//对dcache写地址的控制
    always_ff @( posedge clk ) begin : dcache_wb_addr_block
        if (resetn == `RstEnable) begin
            dcache_wb_addr <='0;
        end else if(dstate_wb == WB_REQ) begin
            dcache_wb_addr <= dcache_wb_addr;
        end else begin
            dcache_wb_addr <= dbus.wr_addr;
        end
    end

    always_ff @(posedge clk ) begin
        if (resetn == `RstEnable) begin
            dcache_line_wb <= '0;
        end else if(dstate_wb == WB_WAIT) begin
            dcache_line_wb <= dcache_line_wb;
        end else begin
            dcache_line_wb <= dbus.wr_data;
        end
    end


















    axi_crossbar_cache biu (//TODO: ICACHE 的UNCACHE尚未实现
        .aclk             ( clk     ),
        .aresetn          ( resetn        ),
        
        .s_axi_arid       ( {ibus_arid   ,dbus_arid    ,ubus_arid   } ),
        .s_axi_araddr     ( {ibus_araddr ,dbus_araddr  ,ubus_araddr } ),
        .s_axi_arlen      ( {ibus_arlen  ,dbus_arlen   ,ubus_arlen  } ),
        .s_axi_arsize     ( {ibus_arsize ,dbus_arsize  ,ubus_arsize } ),
        .s_axi_arburst    ( {ibus_arburst,dbus_arburst ,ubus_arburst} ),
        .s_axi_arlock     ( {ibus_arlock ,dbus_arlock  ,ubus_arlock } ),
        .s_axi_arcache    ( {ibus_arcache,dbus_arcache ,ubus_arcache} ),
        .s_axi_arprot     ( {ibus_arprot ,dbus_arprot  ,ubus_arprot } ),
        .s_axi_arqos      ( 0                                         ),
        .s_axi_arvalid    ( {ibus_arvalid,dbus_arvalid ,ubus_arvalid} ),
        .s_axi_arready    ( {ibus_arready,dbus_arready ,ubus_arready} ),
        .s_axi_rid        ( {ibus_rid    ,dbus_rid     ,ubus_rid    } ),
        .s_axi_rdata      ( {ibus_rdata  ,dbus_rdata   ,ubus_rdata  } ),
        .s_axi_rresp      ( {ibus_rresp  ,dbus_rresp   ,ubus_rresp  } ),
        .s_axi_rlast      ( {ibus_rlast  ,dbus_rlast   ,ubus_rlast  } ),
        .s_axi_rvalid     ( {ibus_rvalid ,dbus_rvalid  ,ubus_rvalid } ),
        .s_axi_rready     ( {ibus_rready ,dbus_rready  ,ubus_rready } ),
        .s_axi_awid       ( {ibus_awid   ,dbus_awid    ,ubus_awid   } ),
        .s_axi_awaddr     ( {ibus_awaddr ,dbus_awaddr  ,ubus_awaddr } ),
        .s_axi_awlen      ( {ibus_awlen  ,dbus_awlen   ,ubus_awlen  } ),
        .s_axi_awsize     ( {ibus_awsize ,dbus_awsize  ,ubus_awsize } ),
        .s_axi_awburst    ( {ibus_awburst,dbus_awburst ,ubus_awburst} ),
        .s_axi_awlock     ( {ibus_awlock ,dbus_awlock  ,ubus_awlock } ),
        .s_axi_awcache    ( {ibus_awcache,dbus_awcache ,ubus_awcache} ),
        .s_axi_awprot     ( {ibus_awprot ,dbus_awprot  ,ubus_awprot } ),
        .s_axi_awqos      ( 0                                         ),
        .s_axi_awvalid    ( {ibus_awvalid,dbus_awvalid ,ubus_awvalid} ),
        .s_axi_awready    ( {ibus_awready,dbus_awready ,ubus_awready} ),
        .s_axi_wid        ( {ibus_wid    ,dbus_wid     ,ubus_wid    } ),
        .s_axi_wdata      ( {ibus_wdata  ,dbus_wdata   ,ubus_wdata  } ),
        .s_axi_wstrb      ( {ibus_wstrb  ,dbus_wstrb   ,ubus_wstrb  } ),
        .s_axi_wlast      ( {ibus_wlast  ,dbus_wlast   ,ubus_wlast  } ),
        .s_axi_wvalid     ( {ibus_wvalid ,dbus_wvalid  ,ubus_wvalid } ),
        .s_axi_wready     ( {ibus_wready ,dbus_wready  ,ubus_wready } ),
        .s_axi_bid        ( {ibus_bid    ,dbus_bid     ,ubus_bid    } ),
        .s_axi_bresp      ( {ibus_bresp  ,dbus_bresp   ,ubus_bresp  } ),
        .s_axi_bvalid     ( {ibus_bvalid ,dbus_bvalid  ,ubus_bvalid } ),
        .s_axi_bready     ( {ibus_bready ,dbus_bready  ,ubus_bready } ),
        
        .m_axi_arid       ( m_axi_arid          ),
        .m_axi_araddr     ( m_axi_araddr        ),
        .m_axi_arlen      ( m_axi_arlen         ),
        .m_axi_arsize     ( m_axi_arsize        ),
        .m_axi_arburst    ( m_axi_arburst       ),
        .m_axi_arlock     ( m_axi_arlock        ),
        .m_axi_arcache    ( m_axi_arcache       ),
        .m_axi_arprot     ( m_axi_arprot        ),
        .m_axi_arqos      (                     ),
        .m_axi_arvalid    ( m_axi_arvalid       ),
        .m_axi_arready    ( m_axi_arready       ),
        .m_axi_rid        ( m_axi_rid           ),
        .m_axi_rdata      ( m_axi_rdata         ),
        .m_axi_rresp      ( m_axi_rresp         ),
        .m_axi_rlast      ( m_axi_rlast         ),
        .m_axi_rvalid     ( m_axi_rvalid        ),
        .m_axi_rready     ( m_axi_rready        ),
        .m_axi_awid       ( m_axi_awid          ),
        .m_axi_awaddr     ( m_axi_awaddr        ),
        .m_axi_awlen      ( m_axi_awlen         ),
        .m_axi_awsize     ( m_axi_awsize        ),
        .m_axi_awburst    ( m_axi_awburst       ),
        .m_axi_awlock     ( m_axi_awlock        ),
        .m_axi_awcache    ( m_axi_awcache       ),
        .m_axi_awprot     ( m_axi_awprot        ),
        .m_axi_awqos      (                     ),
        .m_axi_awvalid    ( m_axi_awvalid       ),
        .m_axi_awready    ( m_axi_awready       ),
        .m_axi_wid        ( m_axi_wid           ),
        .m_axi_wdata      ( m_axi_wdata         ),
        .m_axi_wstrb      ( m_axi_wstrb         ),
        .m_axi_wlast      ( m_axi_wlast         ),
        .m_axi_wvalid     ( m_axi_wvalid        ),
        .m_axi_wready     ( m_axi_wready        ),
        .m_axi_bid        ( m_axi_bid           ),
        .m_axi_bresp      ( m_axi_bresp         ),
        .m_axi_bvalid     ( m_axi_bvalid        ),
        .m_axi_bready     ( m_axi_bready        )
    );


endmodule