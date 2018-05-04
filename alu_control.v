module	alu_control(OUT, AluOp, Funct);
				
  input	[5:0]	Funct;
	input	[2:0]	AluOp;
	output	reg	[2:0]	OUT;	
				
				
  always	@	(Funct,	AluOp)
  begin
	  if	(AluOp	==	3'b000) // lw or sw
		  OUT	=	3'b010;
    else if (AluOp	==	3'b011) // andi
      OUT	=	3'b000;
    else if (AluOp	==	3'b100) // ori
      OUT	=	3'b001;
		else begin
		  if(AluOp == 3'b001) // beq
			  OUT = 3'b110;
			else if (3'b010) begin // R type
			  case (Funct)
          6'b100100	:	OUT	=	3'b000; // and
          6'b100101	:	OUT	=	3'b001; // or
				  6'b100000	:	OUT	=	3'b010; // add
          6'b000000	:	OUT	=	3'b011; // sll
          6'b000010	:	OUT	=	3'b100; // srl
          6'b101011	:	OUT	=	3'b101; // stlu
				  6'b100010	:	OUT	=	3'b110; // sub
					6'b101010	:	OUT	=	3'b111; // slt
				endcase
			end
		end
  end
    
endmodule