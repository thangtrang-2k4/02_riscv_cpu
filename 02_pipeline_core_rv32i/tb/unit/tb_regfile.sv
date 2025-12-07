`timescale 1ns/1ps

module tb_regfile();
	reg clk,rst_n,RegWEn;
	reg [4:0] rsR1, rsR2, rsW;
	reg [31:0] dataW;
	// Outputs
	wire [31:0] dataR1, dataR2; 
  	// Instantiate the Unit Under Test (UUT)
  RegFile #(.WRITE_THROUGH(0)) dut_nwt (
    .clk(clk), 
    .rst_n(rst_n),
    .rsR1(rsR1), 
    .rsR2(rsR2), 
    .rsW(rsW),
    .dataW(dataW), 
    .RegWEn(RegWEn),
    .dataR1(dataR1), 
    .dataR2(dataR2)
  );
    initial begin
        clk = 1;
        forever #10 clk = ~clk; 
    end

    initial begin
    rst_n = 0;#40;
        rst_n = 1;
        rsR1 = 5'd3; rsR2 = 3; rsW = 5'd0;
        dataW = 32'hBABABABA;
        RegWEn = 0; #40;
        
        rsW = 5'd3;#40;
        
        RegWEn = 1;#40;
        
        rsR1 = 5'd4;rsR2 = 5'd5;#40;
        rsW = 5'd4;#20;
        rsW = 5'd5;#20;
        rsR1 = 5'd0;#40;
        rsW = 5'd0;#20;
#50;
$finish;
  
    end
        
endmodule
