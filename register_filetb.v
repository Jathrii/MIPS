
module	rftb();
			 reg	clk;
			 reg	[4:0]	read_reg_1,	read_reg_2,	write_reg;
			 reg	[31:0]	write_data;
			 reg	regWrite;
			 wire	[31:0]	read_data_1,	read_data_2;
			
			register_file r(read_data_1,	read_data_2, read_reg_1,	read_reg_2,	write_reg,	write_data,	regWrite, clk );
				
    initial	begin
							 clk	=	0;
							 forever	begin
							 #5	clk	=	~clk;
							 end
			 end
							
				initial
			 begin
			 $monitor("%t	%b	%b	%b",	$time,	read_data_1,	read_data_2,	clk);
			 #5	read_reg_1	<=	2'b0;
			 #5	write_reg	<=	2'b01;			 regWrite	<=	1;	write_data<=32'd55;
			 #15	regWrite	=	0;
			 #5	read_reg_2	<=	2'b1;
			 #5	$finish;
			 end
endmodule