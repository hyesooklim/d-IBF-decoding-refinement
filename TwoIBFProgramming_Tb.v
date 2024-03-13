
//Written by prof. Hyesook Lim at Ewha Womans University (2023.01).
//This code programs two IBFs by calling IBF_Programming twice for "Set1.txt" and "Set2.txt".

`include "headers.v"
module TwoIBFProgramming_Tb;

reg clk = 0, reset = 1;
reg simStart = 1, Start = 0;
reg insertDone;

reg [`KeyField-1:0] LUT1 [`SetSize - 1: 0];
reg [`KeyField-1:0] LUT2 [`Set2Size - 1: 0];
reg [`SetLen:0] memAddr;
wire [`KeyField-1:0]  inValue1, inValue2;
reg no1=1'b0, no2=1'b1;

IBF_Programming IBF1 (clk, reset, Start, insertDone, no1, inValue1, Done);
IBF_Programming IBF2 (clk, reset, Start, insertDone, no2, inValue2, Done);

initial $readmemb ("Set1.txt", LUT1);
initial $readmemb ("Set2.txt", LUT2);

always #5 clk = ~clk; //clock generation
initial #10 reset = 0; //reset de-activation

initial begin
	#10 simStart = 1;
	#10 simStart = 0;
end

always @(negedge clk)
	if (reset) Start <= 0;
	else if (simStart ) Start <= 1;
	else if (Done) Start <= 1;
	else Start <= 0; 

assign inValue1 = LUT1[memAddr];
assign inValue2 = LUT2[memAddr];

always @(negedge clk)
	if (reset) memAddr <= 0;
	else if (Done) begin
		 memAddr <= memAddr + 1;
	end

always @(negedge clk)
	if (reset) insertDone <= 0;
	else insertDone <= (memAddr == `Set2Size) ? 1: 0;

always @(posedge insertDone) begin
		$display ("Programming Complete");
		#20 $stop;
end

endmodule
