`timescale 1ns / 1ps

module txm(
    input wire clk,
    input wire arst,
    input wire txclk,
    output reg [3:0]txd,
    output reg txen,
    output txbusy,

    input wire send_pack_valid,
    input [10:0] send_pack_addr,
    input [10:0] send_pack_size,
    input wire send_pack_index,

	input wire [10:0]wraddr,
    input wire [15:0]wrdata
    );

    wire [15:0] word;
    reg  [10:0] byte_counter;

	BRAM_SDP_MACRO #(
		.BRAM_SIZE("36Kb"),
		.DEVICE("7SERIES"),
		.WRITE_WIDTH(16),
		.READ_WIDTH(16),
		.DO_REG(0),
		.INIT_FILE ("NONE"),
		.SIM_COLLISION_CHECK ("ALL"),
		.SRVAL(8'h00),
		.INIT(8'h00),
		.WRITE_MODE("WRITE_FIRST")
	) tx_packets_ram (
		.RDCLK(clk),
		.RDADDR(send_pack_addr + byte_counter),
		.DO(word),
		.RDEN(1'b1),

		.WRCLK(clk),
		.WRADDR(wraddr),
		.DI({wrdata}),
		.WREN(1'b1),
		.WE(2'b11),

		.RST(1'b0),
		.REGCE(1'b1)
	);

    reg txbusy;
    reg [3:0]txstate;
    reg reset = 1'b1;
    reg en = 1'b0;
    wire [63:0] fcs;
    reg [27:0] n_fcs;

    always@(posedge txclk)begin
        if(arst == 0) begin
            txstate <= 4'h0;
            reset <= 1'b1;
            en <= 1'b0;
            txbusy = 1'b0;
        end
        else begin
            case (txstate)
            4'd0:   begin
                        if(send_pack_valid) begin
                            txbusy <= 1'b1;
                            byte_counter <= 15;
                            txstate <= 4'd1;
                        end
                    end
            4'd1:   begin
                        txen <= 1'b1;
                        if(byte_counter) begin
                            txd <= 4'h5;
                            byte_counter <= byte_counter - 1;
                        end
                        else begin
                            txd <= 4'hd;
                            reset <= 1'b0;
                            txstate <= 4'd2;
                        end
                    end
            4'd2:   begin
                        if(byte_counter < send_pack_size) begin
                            en <= 1'b1;
                            if(send_pack_index) begin
                                txd <= word[8+3:8+0];
                            end
                            else begin
                                txd <= word[3:0];
                            end
                            txstate <= 4'd3;
                        end
                        else begin
                            en <= 1'b0;
                            if(send_pack_index) begin
                                txd <= ~fcs[32+3:32+0];
                                n_fcs <= ~fcs[32+31:32+4];
                            end
                            else begin
                                txd <= ~fcs[3:0];
                                n_fcs <= ~fcs[31:4];
                            end
                            byte_counter <= 7;
                            txstate <= 4'd4;
                        end
                    end
            4'd3:   begin
                        en <= 1'b0;
                        if(send_pack_index) begin
                            txd <= word[8+7:8+4];
                        end
                        else begin
                            txd <= word[7:4];
                        end
                        byte_counter <= byte_counter + 1;
                        txstate <= 4'd2;
                    end
            4'd4:   begin
                        if(byte_counter) begin
                            txd <= n_fcs[3:0];
                            n_fcs <= n_fcs >> 4;
                            byte_counter <= byte_counter - 1;
                        end
                        else begin
                            txen <= 1'b0;
                            reset <= 1'b1;
                            byte_counter <= 12;
                            txstate <= 4'd5;
                        end
                    end
            4'd5:   begin
                        if(byte_counter) begin
                            byte_counter <= byte_counter - 1;
                        end
                        else begin
                            txbusy <= 1'b0;
                            txstate <= 4'd0;
                        end
                    end
            endcase
        end
    end

	crc32 crc32_inst(
		.clk(txclk),
		.word(word),
        .reset(reset),
        .en(en),
		.fcs(fcs)
	);
endmodule
