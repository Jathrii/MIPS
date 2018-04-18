module	alu_control(OUT, AluOp, Funct);
				
  input	[5:0]	Funct;
	input	[1:0]	AluOp;
	output	reg	[2:0]	OUT;	
				
				
  always	@	(Funct,	AluOp)
  begin
	  if	(AluOp	==	0)
		  OUT	=	6'b010;
		else begin
		  if(AluOp == 01)
			  OUT = 110;
			else begin
			  case (Funct)
				  6'b100000	:	OUT	=	6'b010;
				  6'b100010	:	OUT	=	6'b110;
			    6'b100100	:	OUT	=	6'b000;
					6'b100101	:	OUT	=	6'b001;
					6'b101010	:	OUT	=	6'b111;
				endcase
			end
		end
  end
    
endmodule