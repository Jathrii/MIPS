module alu(output [31:0] out, output zero, input  [31:0] a,input  [31:0] b,input  [2:0] select);
  always @(select)
  begin
    case(select)
    3'b000: out=a&&b;
    3'b001: out=a||b;
    3'b010: out=a+b;
    3'b110: out=a-b;
    3'b111: a<<1;
    endcase
  end
  
  assign zero = ~out;
  
endmodule