
`timescale 1 ns / 1 ps

	module AXI_bram_gt_v1_0_S00_AXI #
	(
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	)
	(
		output reg       interrupt,

		input wire       rxclk,
		input wire       rxdv,
		input wire [3:0] rxd,
		output wire      txclk,
		output wire      txen,
		output wire [3:0]txd,
		output wire      led,

		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input wire [2 : 0] S_AXI_AWPROT,
		input wire  S_AXI_AWVALID,
		output wire  S_AXI_AWREADY,
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input wire  S_AXI_WVALID,
		output wire  S_AXI_WREADY,
		output wire [1 : 0] S_AXI_BRESP,
		output wire  S_AXI_BVALID,
		input wire  S_AXI_BREADY,
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input wire [2 : 0] S_AXI_ARPROT,
		input wire  S_AXI_ARVALID,
		output wire  S_AXI_ARREADY,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire  S_AXI_RVALID,
		input wire  S_AXI_RREADY
	);
	localparam RAM_DATA_WIDTH = 8;
	localparam RAM_ADDR_WIDTH = 11;
	//localparam mymac = 48'h0000C0CAC0C01A;
	//localparam my_ip = 32'hC10101F0;

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  							axi_awready;
	reg  							axi_wready;
	reg 				   [1 : 0] 	axi_bresp;
	reg  							axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  							axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg 				   [1 : 0] 	axi_rresp;
	reg  							axi_rvalid;

	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 1;
	
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	reg [7:0]my_mac[5:0];
	reg [7:0]my_ip[3:0];
	reg [7:0]bcast_ip[3:0];

	reg  prev_recv_pack_valid = 1'b0;
	wire recv_pack_valid;
	wire [RAM_ADDR_WIDTH-1:0] recv_pack_addr;
	wire [RAM_ADDR_WIDTH-1:0] recv_pack_size;

	wire [7:0] rddata;
	reg  [RAM_ADDR_WIDTH-1:0] rdaddr;
	reg  [RAM_ADDR_WIDTH-1:0] wraddr;
	reg  [15:0]  wrdata;
	wire txbusy;
	reg [RAM_ADDR_WIDTH-1:0] send_pack_addr;
	reg [RAM_ADDR_WIDTH-1:0] send_pack_size;
	reg send_pack_valid = 1'b0;
	reg send_pack_index = 1'b0;
	reg start_scheduler = 1'b0;

	wire [31:0] fcs;
	wire [15:0] a1;
	wire [15:0] a2;

	wire [47:0] timer;
	
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK ) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
	    	slv_reg0 <= 0;
	    	slv_reg1 <= 0;
	    	slv_reg2 <= 0;
	    	slv_reg3 <= 0;
	  	end 
	  	else begin
	    	if (slv_reg_wren) begin
	      		case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	      		3'h0: begin
	        		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
	   	      			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	       	    			slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	         			end 
					end
				end 
		      	3'h1: begin
	    	    	for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
	        	  		if ( S_AXI_WSTRB[byte_index] == 1 ) begin
		        	    	slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          			end
					end
				end
	    	  	3'h2: begin
	        		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
	          			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
            				slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
		          		end
					end
				end
		      	3'h3: begin
		        	for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
	    	      		if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	        	    		slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          			end  
					end
				end
	      		default : begin
	          		slv_reg0 <= slv_reg0;
		          	slv_reg1 <= slv_reg1;
		          	slv_reg2 <= slv_reg2;
	    	      	slv_reg3 <= slv_reg3;
	        	end
	      		endcase
	    	end
			else begin

				slv_reg1[4:0] <= {slv_reg3[31:30], txbusy, send_pack_valid, recv_pack_valid};

				case(slv_reg3[29+:3])
				3'd0:	begin
							rdaddr <= slv_reg3[16+:RAM_ADDR_WIDTH];
							slv_reg3[29+:3] <= 3'd7;
						end
				3'd1:	begin
							wraddr <= slv_reg3[16+:RAM_ADDR_WIDTH];
							wrdata <= {slv_reg3[8+:RAM_DATA_WIDTH], slv_reg3[0+:RAM_DATA_WIDTH]};
							slv_reg3[29+:3] <= 3'd7;
						end
				3'd2:	begin
							if(txbusy) begin
								send_pack_valid <= 1'b0;
								slv_reg3[29+:3] <= 3'd7;
							end
							else begin
								send_pack_addr <= slv_reg3[16+:RAM_ADDR_WIDTH];
								send_pack_size <= slv_reg3[0+:RAM_ADDR_WIDTH];
								send_pack_valid <= 1'b1;
							end
						end
				3'd3:	begin
							my_mac[slv_reg3[16+:3]] <= slv_reg3[0+:8];
							slv_reg3[29+:3] <= 3'd7;
						end
				3'd4:	begin
							my_ip[slv_reg3[16+:2]] <= slv_reg3[0+:8];
							slv_reg3[29+:3] <= 3'd7;
						end
				3'd5:	begin
							bcast_ip[slv_reg3[16+:3]] <= slv_reg3[0+:8];
							slv_reg3[29+:3] <= 3'd7;
						end
				3'd6:	begin
							start_scheduler <= slv_reg3[0];
							slv_reg3[29+:3] <= 3'd7;
						end
				3'd7:	begin
							rdaddr <= rdaddr;
							wraddr <= wraddr;
							wrdata <= wrdata;
							send_pack_addr <= send_pack_addr;
							send_pack_size <= send_pack_size;
							send_pack_valid <= send_pack_valid;
						end
				endcase
			end
	  	end
	end

	always@(posedge S_AXI_ACLK)begin
		if(prev_recv_pack_valid == 1'b0 && recv_pack_valid == 1'b1)begin
			interrupt <= 1'b1;
		end
		else begin
			interrupt <= 1'b0;
		end

		prev_recv_pack_valid <= recv_pack_valid;
	end

	always @( posedge S_AXI_ACLK ) begin
	  if ( S_AXI_ARESETN == 1'b0 ) begin
	    axi_bvalid  <= 0;
	    axi_bresp   <= 2'b0;
	  end 
	  else begin    
	    if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
	      axi_bvalid <= 1'b1;
	      axi_bresp  <= 2'b0; 
	    end
	    else begin
	      if (S_AXI_BREADY && axi_bvalid) begin
	        axi_bvalid <= 1'b0; 
	      end  
	    end
	  end
	end   

	always @( posedge S_AXI_ACLK ) begin
	  if ( S_AXI_ARESETN == 1'b0 ) begin
	    axi_arready <= 1'b0;
	    axi_araddr  <= 32'b0;
	  end 
	  else begin    
	    if (~axi_arready && S_AXI_ARVALID) begin
	      axi_arready <= 1'b1;
	      axi_araddr  <= S_AXI_ARADDR;
	    end
	    else begin
	      axi_arready <= 1'b0;
	    end
	  end 
	end       

	always @( posedge S_AXI_ACLK ) begin
	  if ( S_AXI_ARESETN == 1'b0 ) begin
	    axi_rvalid <= 0;
	    axi_rresp  <= 0;
	  end 
	  else begin    
	    if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
	      axi_rvalid <= 1'b1;
	      axi_rresp  <= 2'b0; // 'OKAY' response
	    end   
	    else if (axi_rvalid && S_AXI_RREADY) begin
	      axi_rvalid <= 1'b0;
	    end                
	  end
	end    

	always @( posedge S_AXI_ACLK ) begin
	  if ( S_AXI_ARESETN == 1'b0 ) begin
	    axi_rdata  <= 0;
	  end 
	  else begin    
	    if (slv_reg_rden) begin
	       axi_rdata <= reg_data_out;     // register read data
	    end   
	  end
	end    
	
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*) begin
	  	case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	    3'h0    : reg_data_out <= slv_reg0;									// control
	    3'h1    : reg_data_out <= slv_reg1;										// status
	    3'h2    : reg_data_out <= (recv_pack_size << 16) | recv_pack_addr; 		// recv_pack_params
	    3'h3    : reg_data_out <= rddata;										// write addr, read data
	    default : reg_data_out <= timer[31:0];
		endcase
	end

	// Add user logic here
	assign txclk = rxclk;

// 1 hz			1s
// 1 khz		1ms
// 1 mhz 		1mks
// 100 mhz		10ns	1tick
// 39062.5khz	25600ns 1packet	2560ticks

	reg	[3:0] sched_state = 4'd0;
	reg [31:0] ticks_counter;
	reg [1:0] kshu_counter = 2'd0;

	reg nr = 1'b0;
	reg [31:0] nr_counter = 32'h10_00_00_00;

	always@(posedge S_AXI_ACLK) begin
		if(nr_counter == 0) begin
			nr_counter <= 32'h10_00_00_00;
			nr <= 1'b1;
		end
		if(nr_counter == 1'b1) begin
			nr <= 1'b0;
		end
		nr_counter <= nr_counter - 1;
	end

	always@(posedge S_AXI_ACLK)begin
		case(sched_state)
		4'd0: begin
			if(start_scheduler) begin
				kshu_counter <= 2'd3;
				sched_state <= 4'd1;
			end
		end
		4'd1: begin
			if(kshu_counter) begin
				kshu_counter <= kshu_counter - 1;
			end
			else begin
				packet_counter <= 100;
				sched_state <= 4'd2;
			end
		end
		4'd2: begin
			if(packet_counter) begin
				packet_counter <= packet_counter - 1;
			end
			else begin
				pause_counter <= 100;
				sched_state <= 4'd3;
			end
		end
		4'd3: begin
			if(pause_counter) begin
				pause_counter <= pause_counter - 1;
			end
			else begin
				sched_state <= 4'd0;
			end
		end
		endcase

	end

	rxm #(
		.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.RAM_DATA_WIDTH(RAM_DATA_WIDTH)
	)
	rxm_inst(
		.clk(S_AXI_ACLK),
	    .rxclk(rxclk),
    	.rxdv(rxdv),
    	.rxd(rxd),

		.my_mac({my_mac[5], my_mac[4], my_mac[3], my_mac[2], my_mac[1], my_mac[0]}),
		.my_ip({my_ip[3], my_ip[2], my_ip[1], my_ip[0]}),
		.bcast_ip({bcast_ip[3], bcast_ip[2], bcast_ip[1], bcast_ip[0]}),

		.recv_pack_valid(recv_pack_valid),
		.recv_pack_addr(recv_pack_addr),
		.recv_pack_size(recv_pack_size),

		.rdaddr(rdaddr),
    	.rddata(rddata),

		.a1(a1),
		.a2(a2),

		.rx_led(rx_led)
	);

	txm	txm_inst(
    	.clk(S_AXI_ACLK),
		.arst(S_AXI_ARESETN),
    	.txclk(txclk),
    	.txd(txd),
    	.txen(txen),
		.txbusy(txbusy),

		.send_pack_valid(send_pack_valid),
		.send_pack_addr(send_pack_addr),
		.send_pack_size(send_pack_size),
		.send_pack_index(send_pack_index),

		.wraddr(wraddr),
    	.wrdata(wrdata)
    );

	COUNTER_TC_MACRO #(
		.COUNT_BY(48'h000000000001),
		.DEVICE("7SERIES"),
		.DIRECTION("UP"),
		.RESET_UPON_TC("TRUE"),
		.TC_VALUE(48'd50_000),
		.WIDTH_DATA(48)
	) COUNTER_TC_MACRO_inst (
		.Q(timer),
		.TC(),
		.CLK(S_AXI_ACLK),
		.CE(1'b1),
		.RST(1'b0)
	);

//	assign led = tx_led | rx_led;

	// User logic ends

	endmodule
