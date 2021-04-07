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
        `ifdef DEBUG
            $$display("Registers File:");
            $display("R[00-07]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X",reg_file[0], reg_file[1], reg_file[2], reg_file[3], reg_file[4], reg_file[5], reg_file[6], reg_file[7]);
            $display("R[08-15]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", reg_file[8], reg_file[9], reg_file[10], reg_file[11], reg_file[12], reg_file[13], reg_file[14], reg_file[15]);
            $display("R[16-23]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", reg_file[16], reg_file[17], reg_file[18], reg_file[19], reg_file[20], reg_file[21], reg_file[22], reg_file[23]);
            $display("R[24-31]=%8X, %8X, %8X, %8X, %8X, %8X, %8X, %8X", reg_file[24], reg_file[25], reg_file[26], reg_file[27], reg_file[28], reg_file[29], reg_file[30], reg_file[31]);
        `endif
    end
end



always_comb begin // readData
    ID_BusA = regs[ID_rs];
    ID_BusB = regs[ID_rt];
end
    
endmodule