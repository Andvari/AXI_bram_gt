
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
	localparam mymac = 48'h0000C0CAC0C01A;
	localparam my_ip = 32'hC10101F0;

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

	reg  prev_recv_pack_valid = 1'b1;
	wire recv_pack_valid;
	wire [RAM_ADDR_WIDTH-1:0] recv_pack_addr;
	wire [RAM_ADDR_WIDTH-1:0] recv_pack_size;

	wire [31:0] rddata;
	wire [7:0]  wrdata;
	wire txbusy;

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
	      		3'h0:
	        		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	          			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            			slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          			end  
	      		3'h1:
	        		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	          			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            			slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          			end  
	      		3'h2:
	        		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	          			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            			slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	          			end  
	      		3'h3:
	        		for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	          			if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	            			slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
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
				slv_reg1 <= {slv_reg1[31:1], recv_pack_valid};
				if(slv_reg3[31] == 1'b0 ) begin
					rdaddr <= slv_reg3[RAM_ADDR_WIDTH+16-1:16];
				end
				else begin
					wraddr <= slv_reg3[RAM_ADDR_WIDTH+16-1:16];
					wrdata <= slv_reg3[RAM_DATA_WIDTH-1:0];
				end

				send_pack_addr <= slv_reg2[RAM_ADDR_WIDTH-1:0];
				send_pack_size <= slv_reg2[RAM_ADDR_WIDTH+16-1:16];

				if(txbusy) begin
					slv_reg2[31] <= 1'b0';
					send_pack_valid <= 1'b0;
				end
				else begin
					slv_reg2[31] <= slv_reg2[31];
					send_pack_valid <= slv_reg2[31];
				end

				else begin
					
				end
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
	    3'h0    : reg_data_out <= slv_reg0;										// control
	    3'h1    : reg_data_out <= slv_reg1;										// status
	    3'h2    : reg_data_out <= (recv_pack_size << 16) | recv_pack_addr; 		// recv_pack_params
	    3'h3    : reg_data_out <= rddata;										// write addr, read data
	    default : reg_data_out <= timer[31:0];
		endcase
	end

	// Add user logic here
	assign txclk = rxclk;

	//reg [RAM_ADDR_WIDTH-1:0]wraddr = 11'd0;

	rxm #(
		.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.RAM_DATA_WIDTH(RAM_DATA_WIDTH),
    	.my_mac(48'h0000C0CAC01A),
		.my_ip(32'hC10101F0),
    	.my_dst_port(16'h1111)
	)
	rxm_inst(
		.clk(S_AXI_ACLK),
	    .rxclk(rxclk),
    	.rxdv(rxdv),
    	.rxd(rxd),

		.recv_pack_valid(recv_pack_valid),
		.recv_pack_addr(recv_pack_addr),
		.recv_pack_size(recv_pack_size),

		.rdaddr(rdaddr),
    	.rddata(rddata)
	);

	txm #(
		.RAM_ADDR_WIDTH(RAM_ADDR_WIDTH),
		.RAM_DATA_WIDTH(RAM_DATA_WIDTH),
    	.my_mac(48'h0000C0CAC01A),
		.my_ip(32'hC10101F0)
	)
	txm_inst(
    	.clk(S_AXI_ACLK),
    	.txclk(txclk),
    	.txd(txd),
    	.txen(txen),
		.txbusy(txbusy),

    	.send_pack_valid(send_pack_valid),
    	.send_pack_addr(send_pack_addr),
    	.send_pack_size(send_pack_size),

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

	assign led = timer[9];

	// User logic ends

	endmodule
