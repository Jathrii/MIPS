module alu(output [31:0] out, output zero, input  [31:0] a,input  [31:0] b,input  [3:0] select);
  always @(select)
  begin
    case(select)

      4'b0000: out=a+b;  
      4'b0001: out=a-b;
      4'b0010: out=a*b;
      4'b0010: out=a&&b;
      4'b0011: out=a||b;

      4'b0100: out=!a;
      4'b0101: out=~a;
      4'b0110: out=a&b;
      4'b0111: out=a|b;

      4'b1000: out=a<<1;
      4'b1001: out=a>>1;
      4'b1010: out=a+1;
      4'b1011: out=a-1;
      4'b1100: out=b;
      4'b1101: out=a;

    endcase
  end
  
  assign zero = |out;
  
endmodule