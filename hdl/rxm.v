`timescale 1ns / 1ps


module rxm(
    input wire clk,
    input wire rxclk,
    input wire rxdv,
    input wire [3:0]rxd,

	input [47:0]my_mac,
	input [31:0]my_ip,
	input [31:0]bcast_ip,

    output recv_pack_valid,
    output recv_pack_addr,
    output recv_pack_size,

    input rdaddr,
    output rddata,

    output a1,
    output a2,

    output reg rx_led
    );
    parameter RAM_DATA_WIDTH = 8;
    parameter RAM_ADDR_WIDTH = 11;
    
    localparam [47:0]bcast_mac = 48'hFFFFFFFFFFFF;
    localparam [31:0]bcast2_ip = 32'hFFFFFFFF;

    reg recv_pack_valid = 1'b0;
    reg [RAM_ADDR_WIDTH-1:0] recv_pack_addr;
    reg [RAM_ADDR_WIDTH-1:0] recv_pack_size;

    wire [RAM_ADDR_WIDTH-1:0] rdaddr;
    wire [7:0] rddata;

    reg [RAM_DATA_WIDTH-1:0] byte;
    reg [RAM_ADDR_WIDTH-1:0] byte_counter = 0;
    reg [RAM_ADDR_WIDTH-1:0] start_packet = 0;

	BRAM_SDP_MACRO #(
		.BRAM_SIZE("18Kb"),
		.DEVICE("7SERIES"),
		.WRITE_WIDTH(8),
		.READ_WIDTH(8),
		.DO_REG(0),
		.INIT_FILE ("NONE"),
		.SIM_COLLISION_CHECK ("ALL"),
		.SRVAL(8'h00),
		.INIT(8'h00),
		.WRITE_MODE("WRITE_FIRST")
	) rx_packets_ram (
		.RDCLK(clk),
		.RDADDR(rdaddr[RAM_ADDR_WIDTH-1:0]),
		.DO(rddata),
		.RDEN(1'b1),

		.WRCLK(rxclk),
		.WRADDR(start_packet + byte_counter),
		.DI(byte),
		.WREN(1'b1),
		.WE(1'b1),

		.RST(1'b0),
		.REGCE(1'b1)
	);

	reg byte_ready = 1'b1;
    always @(posedge rxclk)begin
        if(rxdv)begin
            case (byte_ready)
            1'b1:   begin
                        byte[3:0] <= {rxd[3], rxd[2], rxd[1], rxd[0]};
                        byte_ready <= 1'b0;
                    end
            1'b0:   begin
                        byte[7:4] <= {rxd[3], rxd[2], rxd[1], rxd[0]};
                        byte_ready <= 1'b1;
                    end
            endcase
        end
    end

    reg [4:0] rxstate = 5'd0;

    reg [47:0] mac_dst;
    reg [47:0] mac_src;
    reg [15:0] eth_type_msb;
    reg [15:0] total_lenght;
    reg [15:0] ipv4_payload_lenght;
    reg [15:0] payload_lenght;
    reg [15:0] padding_lenght;
    reg  [7:0] protocol;
    reg [15:0] ip_hdr_csum;
    reg [31:0] ip_src;
    reg [31:0] ip_dst;
    reg [15:0] src_port;
    reg [15:0] dst_port;
    reg [15:0] udp_len;
    reg [15:0] udp_csum;
    reg [31:0] fcs;

    reg [15:0] arp_oper;
    reg [47:0] sender_mac;
    reg [31:0] sender_ip;
    reg [47:0] target_mac;
    reg [31:0] target_ip;

    reg [15:0] a1;
    reg [15:0] a2;

    always@(posedge rxclk) begin

        if(byte_ready) begin
            byte_counter <= byte_counter + 1;

            case(rxstate)
            5'd0: begin                                                             // receive preamble_1
                if(byte == 8'h55) begin
                    if(byte_counter == 6) begin
                        rxstate <= 5'd1;
                    end
                end
                else begin
                    byte_counter <= 0;
                end
            end

            5'd1: begin                                                             // receive preamble_2
                if(byte == 8'hd5) begin
                    rxstate <= 5'd2;
                    recv_pack_valid <= 1'b0;
                    byte_counter <= 0;
                end
                else begin
                    rxstate <= 5'd0;
                    byte_counter <= 0;
                end
            end

            5'd2: begin     
                mac_dst <= (mac_dst << 8) | byte;                                     // receive mac
                if(byte_counter == 5) begin
                    rxstate <= 5'd3;
                end
            end

            5'd3: begin                                                             // receive mac
                mac_src <= (mac_src << 8) | byte;
                if(byte_counter == 11) begin
                    rxstate <= 5'd4;
                end
            end

            5'd4: begin                    
                eth_type_msb <= byte;                                                   // receive type
                if(byte_counter == 13) begin
                    if(eth_type_msb == 8'h08)begin
                        case(byte)
                        8'h00: begin
                            rxstate <= 5'd5;                                        // eth proto
                        end
                        8'h06: begin
                            rxstate <= 5'd19;                                        // arp proto
                        end
                        default: begin
                            rxstate <= 5'd0;
                            byte_counter <= 0;
                        end
                        endcase
                    end
                    else begin
                        rxstate <= 5'd0;
                        byte_counter <= 0;
                    end
                end
            end

            5'd5: begin                                                             // receive ip version
                if(byte == 8'h45) begin
                    rxstate <= 5'd6;
                end
                else begin
                    rxstate <= 5'd0;
                    byte_counter <= 0;
                end
            end

            5'd6: begin                                                             // receive ip version
                total_lenght <= (total_lenght<<8) | byte;
                if(byte_counter == 17) begin
                    rxstate <= 5'd7;
                end
            end

            5'd7: begin                                                             // receive ip version
                protocol <= byte;
                if(byte_counter == 23) begin
                    ipv4_payload_lenght <= total_lenght - 20;
                    rxstate <= 5'd8;
                end
            end

            5'd8: begin                                                             // receive ip version
                ip_hdr_csum <= (ip_hdr_csum << 8) | byte;
                if(byte_counter == 25) begin
                    rxstate <= 5'd9;
                end
            end

            5'd9: begin                                                             // receive ip version
                ip_src <= (ip_src << 8) | byte;
                if(byte_counter == 29) begin
                    rxstate <= 5'd10;
                end
            end

            5'd10: begin                                                             // receive ip version
                ip_dst <= (ip_dst << 8) | byte;
                if(byte_counter == 33) begin
                    rxstate <= 5'd11;
                end
            end

            5'd11: begin                                                             // receive ip version
                if(ip_dst == my_ip || ip_dst == bcast_ip || ip_dst == bcast2_ip) begin
                    case(protocol)
                    8'h11: begin
                        payload_lenght <= ipv4_payload_lenght - 8;
                        if(total_lenght < 46) begin
                            padding_lenght <= 46 - total_lenght;
                        end
                        else begin
                            padding_lenght <= 0;
                        end
                        rxstate <= 5'd12;
                    end
                    8'h01: begin
                        payload_lenght <= ipv4_payload_lenght - 4;
                        if(total_lenght < 46) begin
                            padding_lenght <= 46 - total_lenght;
                        end
                        else begin
                            padding_lenght <= 0;
                        end
                        rxstate <= 5'd12;
                    end
                    default: begin
                        rxstate <= 5'd0;
                        byte_counter <= 0;
                    end
                    endcase
                end
                else begin
                    rxstate <= 5'd0;
                    byte_counter <= 0;
                end
            end

            5'd12: begin                                                             // receive ipv4 UDP payload
                src_port <= (src_port << 8) | byte;
                if(byte_counter == 35) begin
                    rxstate <= 5'd13;
                end
            end
            
            5'd13: begin                                                             // receive ipv4 UDP payload
                dst_port <= (dst_port << 8) | byte;
                if(byte_counter == 37) begin
                    rxstate <= 5'd14;
                end
            end
            
            5'd14: begin                                                             // receive ipv4 UDP payload
                udp_len <= (udp_len << 8) | byte;
                if(byte_counter == 39) begin
                    rxstate <= 5'd15;
                end
            end
            
            5'd15: begin                                                             // receive ipv4 UDP payload
                udp_csum <= (udp_csum << 8) | byte;
                if(byte_counter == 41) begin
                    rxstate <= 5'd16;
                end
            end
            
            5'd16: begin                                                             // receive ipv4 UDP payload
                if(byte_counter == 42 + payload_lenght + padding_lenght - 1) begin
                    rxstate <= 5'd17;
                end
            end
            
            5'd17: begin
                fcs <= (fcs << 8) | byte;                                           // receive fcs
                if(byte_counter == 46 + payload_lenght + padding_lenght - 1) begin
                    rxstate <= 5'd0;
                    recv_pack_addr <= start_packet;
                    recv_pack_size <= byte_counter + 1;
                    start_packet <= start_packet + byte_counter +1;
                    recv_pack_valid <= 1'b1;
                    byte_counter <= 0;
                end
            end

            5'd19: begin
                arp_oper <= (arp_oper << 8) | byte;
                if(byte_counter == 21) begin
                    rxstate <= 5'd20;
                end
            end

            5'd20: begin
                sender_mac <= (sender_mac << 8) | byte;
                if(byte_counter == 27) begin
                    rxstate <= 5'd21;
                end
            end

            5'd21: begin
                sender_ip <= (sender_ip << 8) | byte;
                if(byte_counter == 31) begin
                    rxstate <= 5'd22;
                end
            end

            5'd22: begin
                target_mac <= (target_mac << 8) | byte;
                if(byte_counter == 37) begin
                    rxstate <= 5'd23;
                end
            end

            5'd23: begin
                target_ip <= (target_ip << 8) | byte;
                if(byte_counter == 41) begin
                    rxstate <= 5'd24;
                end
            end

            5'd24: begin
                fcs <= (fcs << 8) | byte;                                           // receive fcs
                if(byte_counter == 63) begin
                    rxstate <= 5'd0;
                    if(arp_oper == 16'd1 && target_ip == my_ip) begin
                        rx_led <= ~rx_led;
                        recv_pack_addr <= start_packet;
                        recv_pack_size <= byte_counter+1;
                        start_packet <= start_packet + byte_counter +1;
                        recv_pack_valid <= 1'b1;
                    end
                    byte_counter <= 0;
                end
            end
            endcase
        end
    end

    always@(posedge clk)begin
        a1 <= byte_counter;
        a2 <= rxstate;
    end
    
endmodule

