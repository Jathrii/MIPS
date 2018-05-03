module	register_file(read_data_1, read_data_2, read_reg_1, read_reg_2, write_reg, write_data, regWrite, clk);

  input	clk;
  input	[4:0]	read_reg_1,	read_reg_2,	write_reg;
  input	[31:0] write_data;
  input	regWrite;
  output [31:0]	read_data_1, read_data_2;
  reg	[31:0]	registers[31:0];	
  
  assign read_data_1 = (read_reg_1 == 0) ? 32'b0 : registers[read_reg_1];
  assign read_data_2 = (read_reg_2 == 0) ? 32'b0 : registers[read_reg_2];
    
  always @(posedge	clk)
	  if(regWrite && write_reg)	
		  registers[write_reg] <= write_data;
    
endmodule