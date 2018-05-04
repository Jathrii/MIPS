module control_unit(out, half, half_unsigned, op_code);

  input [5:0] op_code;

  // OUTPUT = regDst ALUsrc memtoReg regWrite memRead memWrite branch ALUop[2:0] 

  output reg half, half_unsigned; // signals for lh and lhu
  output reg [9:0] out;

  parameter [9:0] regDst = 10'b1000000000;
  parameter [9:0] ALUsrc = 10'b0100000000;
  parameter [9:0] memtoReg = 10'b0010000000;
  parameter [9:0] regWrite = 10'b0001000000;
  parameter [9:0] memRead = 10'b0000100000;
  parameter [9:0] memWrite = 10'b0000010000;
  parameter [9:0] branch = 10'b0000001000;
  parameter [9:0] R_typeALU = 10'b000000010;
  parameter [9:0] branchALU = 10'b000000001;


  always @(op_code)
  begin
    case(op_code)
      6'b000000 : out <= regDst | regWrite | R_typeALU ; // R-type
    	6'b001000 : out <= ALUsrc | regWrite; // addi
      6'b001100 : out <= ALUsrc | regWrite | 10'b0000000011; // andi
      6'b001101 : out <= ALUsrc | regWrite | 10'b0000000100; // ori                      
    	6'b100011 : out <= ALUsrc | memtoReg | regWrite | memRead; // lw
    	6'b101011 : out <= 10'bx0x0000000 | ALUsrc | memWrite ; // sw
    	6'b000100 : out <= 10'bx0x0000000 | branch | branchALU; // beq
      6'b100001 : out <= ALUsrc | memtoReg | regWrite | memRead; // lh
      6'b100101 : out <= ALUsrc | memtoReg | regWrite | memRead; // lhu
    endcase
    
    if (op_code == 6'b100001) begin // lh
      half <= 1;
      half_unsigned <= 0;
    end
    else if (op_code == 6'b100101) begin // lhu
      half <= 1;
      half_unsigned <= 1;
    end
    else begin
      half <= 0;
      half_unsigned <= 0;
    end
  end

endmodule
