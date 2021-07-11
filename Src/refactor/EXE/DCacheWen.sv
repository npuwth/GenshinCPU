/*
 * @Author: npuwth
 * @Date: 2021-03-29 15:27:17
 * @LastEditTime: 2021-07-11 18:33:00
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0 
 * @IO PORT:
 * @Description: 改成了组合逻辑
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module DCacheWen(
  input  logic [31:0]       EXE_ALUOut,    // 地址信息
  input  StoreType          EXE_StoreType, // store类型
  input  logic [31:0]       EXE_OutB,      // 即将给cache的写入的数据
  input  LoadType           EXE_LoadType,

  output logic [3:0]        cache_wen,        //字节信号写使能
  output logic [31:0]       DataToDcache
);


  always_comb begin  : Dcahce_Wen_Generate
    if(EXE_StoreType.DMWr) begin
      if(EXE_StoreType.LeftOrRight == 2'b10 ) begin // 10表示swl 
          case (EXE_ALUOut[1:0])
            2'b00   : begin
              cache_wen    = 4'b0001;
              DataToDcache = {24'b0 , EXE_OutB[31:24]};
            end
            2'b01   : begin
              cache_wen    = 4'b0011;
              DataToDcache = {16'b0 , EXE_OutB[31:16]};
            end
            2'b10   : begin
              cache_wen    = 4'b0111;
              DataToDcache = {8'b0 , EXE_OutB[31:8]};
            end
            2'b11   : begin
              cache_wen    = 4'b1111;
              DataToDcache = EXE_OutB[31:0];
            end
            default :begin
              cache_wen    = 4'b0000;
              DataToDcache = 'x;
            end
          endcase
      end
      else if (EXE_StoreType.LeftOrRight == 2'b01 ) begin // 01表示swr
        case (EXE_ALUOut[1:0])
            2'b00   : begin
              cache_wen    = 4'b1111;
              DataToDcache = EXE_OutB [31:0];
            end
            2'b01   : begin
              cache_wen    = 4'b1110;
              DataToDcache = {EXE_OutB[23:0] , 8'b0 };
            end
            2'b10   : begin
              cache_wen    = 4'b1100;
              DataToDcache = {EXE_OutB[15:0] , 16'b0};
            end
            2'b11   : begin
              cache_wen    = 4'b1000;
              DataToDcache = {EXE_OutB[7:0]  , 24'b0};
            end
            default :begin
              cache_wen    = 4'b0000;
              DataToDcache = 'x;
            end
          endcase
      end
      else begin                                      // 其余都是sh sb sw等
        unique case(EXE_StoreType.size)
          `STORETYPE_SW: begin //SW
            cache_wen        = 4'b1111;
            DataToDcache     = EXE_OutB [31:0];
          end
          `STORETYPE_SH: begin //SH
            if(EXE_ALUOut[1] == 1'b0)begin
              cache_wen      = 4'b0011;
              DataToDcache   = {16'b0 , EXE_OutB [15:0]};
            end
            else begin
              cache_wen      = 4'b1100;
              DataToDcache   = {EXE_OutB [15:0] , 16'b0};
            end
          end
          `STORETYPE_SB: begin //SB
            if(EXE_ALUOut[1:0] == 2'b00) begin
              cache_wen      = 4'b0001;
              DataToDcache   = {24'b0 , EXE_OutB [7:0]};
            end
            else if(EXE_ALUOut[1:0] == 2'b01) begin
              cache_wen      = 4'b0010;
              DataToDcache   = {16'b0 , EXE_OutB [7:0] , 8'b0};
            end
            else if(EXE_ALUOut[1:0] == 2'b10) begin
              cache_wen      = 4'b0100;
              DataToDcache   = {8'b0 , EXE_OutB [7:0] , 16'b0};
            end
            else if(EXE_ALUOut[1:0] == 2'b11) begin
              cache_wen      = 4'b1000;
              DataToDcache   = {EXE_OutB [7:0] , 24'b0};
            end
            else begin   // 其实应该不会出现
              cache_wen      = 4'b0000; 
              DataToDcache   = 'x;
            end
          end
          default: begin
              cache_wen      = 4'b0000;
              DataToDcache   = 'x;
          end
        endcase
      end
    end else begin
      cache_wen      = 4'b0000;
      DataToDcache   = 'x;
    end 
  end

endmodule