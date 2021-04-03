///////////////////////////////////////////////////////////////////////////////
// Copyright(C) Team Genshin. Open source License: MIT.
// ALL RIGHT RESERVED
// File name   : RF.sv
// Author      : Juan Jiang
// Date        : 2021-03-29
// Version     : 0.1
// Description :
// 
//    
// Parameter   :没有
//    ...
//    ...
// IO Port     :没有
//    ...
//    ...
// Modification History:
//   Date   |   Author   |   Version   |   Change Description
//==============================================================================
// 19-06-02 |    Zion    |     0.1     | Original Version
// ...
////////////////////////////////////////////////////////////////////////////////

`include "CPU_Defines.svh"

module RF (
    input logic clk,
    input logic rst,

    input logic[4:0] WB_Dst,
    input logic[31:0] WB_Result,
    input logic RFWr,// to write the RF

    input logic[4:0] ID_rs,
    input logic[4:0] ID_rt,
    output logic[31:0] ID_BusA,
    output logic[31:0] ID_BusB//to read the RF
);

logic [31:0][31:0] regs;



always_ff @(posedge clk) begin// write the RF
    if (rst) begin
        regs <= '0;
    end
    else begin
        if (RFWr==1'b1) begin
            regs[WB_Dst] <= WB_Result;
        end
        else begin
            regs <= regs;
        end
        
    end
end



always_comb begin // readData
    ID_BusA = regs[ID_rs];
    ID_BusB = regs[ID_rt];
end
    
endmodule