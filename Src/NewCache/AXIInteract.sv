/*
 * @Author: your name
 * @Date: 2021-07-06 19:58:31
 * @LastEditTime: 2021-07-08 11:02:35
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \NewCache\AXI.sv
 */
module AXIInteract #(
    parameter icache_line_size=8,//icache块大小
    parameter dcache_line_size=8 //dcache块大小
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



    cache_rd_t iState,iState_next;
    cache_rd_t dState,dState_next;
    
    cache_wb_t iState_wb,iState_wb_next;
    cache_wb_t dState_wb,dState_wb_next;

    uncache_t iState_uncache,iState_uncache_next;
    uncache_t dState_uncache,dState_uncache_next;

    always_ff @( posedge clk ) begin : iState_block
        iState <= iState_next;
    end
    

endmodule