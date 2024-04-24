`timescale 1ns / 1ps

module crc32(
    input wire clk,
    input wire [15:0]word,
    input wire reset,
    input wire en,
    output reg [63:0] fcs
    );

    integer i;

    always @(posedge clk) begin
        if (reset)begin
            fcs <= 64'hFFFFFFFF_FFFFFFFF;
        end
        else begin
            if(en) begin
                //fcs <= ~({fcs[i*32+23:0], byte};
                for(i=0; i<2; i = i + 1) begin
                    fcs[i*32+31] <= word[i*16+1] ^ word[i*16+7] ^ fcs[i*32+1] ^ fcs[i*32+7];
                    fcs[i*32+30] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+0] ^ fcs[i*32+1] ^ fcs[i*32+6] ^ fcs[i*32+7];
                    fcs[i*32+29] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+5] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+0] ^ fcs[i*32+1] ^ fcs[i*32+5] ^ fcs[i*32+6] ^ fcs[i*32+7];
                    fcs[i*32+28] <= word[i*16+0] ^ word[i*16+4] ^ word[i*16+5] ^ word[i*16+6] ^ fcs[i*32+0] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+6];
                    fcs[i*32+27] <= word[i*16+1] ^ word[i*16+3] ^ word[i*16+4] ^ word[i*16+5] ^ word[i*16+7] ^ fcs[i*32+1] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+7];
                    fcs[i*32+26] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+2] ^ word[i*16+3] ^ word[i*16+4] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+0] ^ fcs[i*32+1] ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+6] ^ fcs[i*32+7];
                    fcs[i*32+25] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+2] ^ word[i*16+3] ^ word[i*16+5] ^ word[i*16+6] ^ fcs[i*32+0] ^ fcs[i*32+1] ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+5] ^ fcs[i*32+6];
                    fcs[i*32+24] <= word[i*16+0] ^ word[i*16+2] ^ word[i*16+4] ^ word[i*16+5] ^ word[i*16+7] ^ fcs[i*32+0] ^ fcs[i*32+2] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+7];

                    fcs[i*32+23] <= word[i*16+3] ^ word[i*16+4] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+6] ^ fcs[i*32+7] ^ fcs[i*32+31];
                    fcs[i*32+22] <= word[i*16+2] ^ word[i*16+3] ^ word[i*16+5] ^ word[i*16+6] ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+5] ^ fcs[i*32+6] ^ fcs[i*32+30];
                    fcs[i*32+21] <= word[i*16+2] ^ word[i*16+4] ^ word[i*16+5] ^ word[i*16+7] ^ fcs[i*32+2] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+7] ^ fcs[i*32+29];
                    fcs[i*32+20] <= word[i*16+3] ^ word[i*16+4] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+6] ^ fcs[i*32+7] ^ fcs[i*32+28];
                    fcs[i*32+19] <= word[i*16+1] ^ word[i*16+2] ^ word[i*16+3] ^ word[i*16+5] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+1] ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+5] ^ fcs[i*32+6] ^ fcs[i*32+7] ^ fcs[i*32+27];
                    fcs[i*32+18] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+2] ^ word[i*16+4] ^ word[i*16+5] ^ word[i*16+6] ^ fcs ^ fcs[i*32+1] ^ fcs[i*32+2] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+6] ^ fcs[i*32+26];
                    fcs[i*32+17] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+3] ^ word[i*16+4] ^ word[i*16+5] ^ fcs ^ fcs[i*32+1] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+25];
                    fcs[i*32+16] <= word[i*16+0] ^ word[i*16+2] ^ word[i*16+3] ^ word[i*16+4] ^ fcs ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+24];

                    fcs[i*32+15] <= word[i*16+2] ^ word[i*16+3] ^ word[i*16+7] ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+7] ^ fcs[i*32+23];
                    fcs[i*32+14] <= word[i*16+1] ^ word[i*16+2] ^ word[i*16+6] ^ fcs[i*32+1] ^ fcs[i*32+2] ^ fcs[i*32+6] ^ fcs[i*32+22];
                    fcs[i*32+13] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+5] ^ fcs ^ fcs[i*32+1] ^ fcs[i*32+5] ^ fcs[i*32+21];
                    fcs[i*32+12] <= word[i*16+0] ^ word[i*16+4] ^ fcs ^ fcs[i*32+4] ^ fcs[i*32+20];
                    fcs[i*32+11] <= word[i*16+3] ^ fcs[i*32+3] ^ fcs[i*32+19];
                    fcs[i*32+10] <= word[i*16+2] ^ fcs[i*32+2] ^ fcs[i*32+18];
                    fcs[i*32+9] <= word[i*16+7] ^ fcs[i*32+7] ^ fcs[i*32+17];
                    fcs[i*32+8] <= word[i*16+1] ^ word[i*16+6] ^ word[i*16+7] ^ fcs[i*32+1] ^ fcs[i*32+6] ^ fcs[i*32+7] ^ fcs[i*32+16];

                    fcs[i*32+7] <= word[i*16+0] ^ word[i*16+5] ^ word[i*16+6] ^ fcs ^ fcs[i*32+5] ^ fcs[i*32+6] ^ fcs[i*32+15];
                    fcs[i*32+6] <= word[i*16+4] ^ word[i*16+5] ^ fcs[i*32+4] ^ fcs[i*32+5] ^ fcs[i*32+14];
                    fcs[i*32+5] <= word[i*16+1] ^ word[i*16+3] ^ word[i*16+4] ^ word[i*16+7] ^ fcs[i*32+1] ^ fcs[i*32+3] ^ fcs[i*32+4] ^ fcs[i*32+7] ^ fcs[i*32+13];
                    fcs[i*32+4] <= word[i*16+0] ^ word[i*16+2] ^ word[i*16+3] ^ word[i*16+6] ^ fcs ^ fcs[i*32+2] ^ fcs[i*32+3] ^ fcs[i*32+6] ^ fcs[i*32+12];
                    fcs[i*32+3] <= word[i*16+1] ^ word[i*16+2] ^ word[i*16+5] ^ fcs[i*32+1] ^ fcs[i*32+2] ^ fcs[i*32+5] ^ fcs[i*32+11];
                    fcs[i*32+2] <= word[i*16+0] ^ word[i*16+1] ^ word[i*16+4] ^ fcs ^ fcs[i*32+1] ^ fcs[i*32+4] ^ fcs[i*32+10];
                    fcs[i*32+1] <= word[i*16+0] ^ word[i*16+3] ^ fcs ^ fcs[i*32+3] ^ fcs[i*32+9];
                    fcs[i*32+0] <= word[i*16+2] ^ fcs[i*32+2] ^ fcs[i*32+8];
                end
            end
            else begin
                fcs <= fcs;
            end
        end
    end

endmodule
