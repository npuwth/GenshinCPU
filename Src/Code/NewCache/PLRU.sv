/*
 * @Author: your name
 * @Date: 2021-06-29 23:14:40
 * @LastEditTime: 2021-06-30 15:16:24
 * @LastEditors: Please set LastEditors
 * @Description: In User Settings Edit
 * @FilePath: \Src\Code\NewCache\plru.sv
 */
 `include "../Cache_Defines.svh"
`include "../CPU_Defines.svh"
module PLRU #(
    parameter int unsigned SET_NUM = 4
) (
    input clk,
    input resetn,

    input [SET_NUM-1:0] access,//表示这次命中了哪一路 这是独热码
    input update,               //表示命中了  不然就没法表示没有访存导致的不需要更新lru的情况

    output [$clog2(SET_NUM)-1:0] lru //表示 这次如果替换 替换哪一路
);

logic [SET_NUM-2:0] state, state_d;

// Assign output
generate
if(SET_NUM == 2) begin
    assign lru = state;
end else begin
    assign lru = state[2] == 1'b0 ? state[2-:2] : {state[2], state[0]};
end
endgenerate

// Update
generate
if(SET_NUM == 2) begin
    always_comb begin
        state_d = state;

        if(update && |access) begin
            if(access[0]) begin
                state_d[0] = 1;//如果这次命中的是第0路 那么下次不命中的时候替换的就是1路
            end else begin
                state_d[0] = 0;
            end
        end
    end
end else if(SET_NUM == 4) begin
    always_comb begin
        state_d = state;//好习惯啊

        casez(access)
            4'b1???: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            4'b01??: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            4'b001?: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            4'b0001: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
        endcase
    end
end else if (SET_NUM == 8) begin
    always_comb begin
        state_d = state;

        casez(access[3:0])
            4'b1???: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            4'b01??: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            4'b001?: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            4'b0001: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
        endcase

        casez(access)
            8'b1???_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            8'b01??_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            8'b001?_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            8'b0001_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
            8'b0000_1???: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            8'b0000_01??: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            8'b0000_001?: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            8'b0000_0001: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end            
        endcase
    end
end else begin //最高支持16
    always_comb begin
        state_d = state;

        casez(access)
            16'b1???_????_????_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            16'b01??_????_????_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            16'b001?_????_????_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            16'b0001_????_????_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
            16'b0000_1???_????_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            16'b0000_01??_????_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            16'b0000_001?_????_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            16'b0000_0001_????_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
            16'b1???_????_1???_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            16'b01??_????_1???_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            16'b001?_????_1???_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            16'b0001_????_1???_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end
            16'b0000_1???_1???_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b0;
            end
            16'b0000_01??_1???_????: begin
                state_d[2] = 1'b0;
                state_d[0] = 1'b1;
            end
            16'b0000_001?_1???_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b0;
            end
            16'b0000_0001_1???_????: begin
                state_d[2] = 1'b1;
                state_d[1] = 1'b1;
            end                     
        endcase
    end
end
endgenerate

always_ff @(posedge clk) begin
    if(resetn == `RstEnable) begin
        state <= '0;
    end else if(update) begin
        state <= state_d;
    end
end

endmodule