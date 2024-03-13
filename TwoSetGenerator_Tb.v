
//Written by prof. Hyesook Lim at Ewha Womans University (2023.01).
//This testbench generates two sets, Set1.txt and Set2.txt.
//Random numbers are generated by LFSR.
//Set1 is the numbers starting from other than 0 until the size of Set1.
//Set2 is the numbers starting from S1Distinct until the size of Set2.
//Hence, Set1 has distinct elements at the front, and Set2 has distinct elements at the back.

`include "./headers.v"
module TwoSetGenerator_Tb;
reg clk=0, reset = 0;
wire [`KeyField-1:0] Y;

LFSR LFSR (clk, reset, Y);

always #5 clk = ~clk;
initial #20 reset = 1;

integer i=0, j=0, result = 0, result2 = 0, result3 = 0;

//S2 is larger than S1. S1 has `S1Distinct number of unique elements.
always @(negedge clk) begin
	if (reset) begin
		result = $fopen ("Set1.txt");
		if ((i != 0) && (i<=`SetSize)) $fdisplay (result, "%b", Y); //in order to avoid all zero element
		i = i + 1;
	end
end

always @(negedge clk) begin
	if (reset) begin
		result2 = $fopen ("Set2.txt");
		result3 = $fopen ("Set_Difference.txt");
		if ((j!=0) && (j <=`S1Distinct)) $fdisplay (result3, "%b", {1'b1, 1'b0, Y}); //valid, Set1, Y
		else if (j>`Set2Size-`S2Distinct + `S1Distinct ) $fdisplay (result3, "%b", {1'b1, 1'b1, Y});//valid, Set2, Y
		if (j >(`S1Distinct)) $fdisplay (result2, "%b", Y);
		j = j + 1;
	end
	if (j==(`Set2Size +`S1Distinct + 1)) $stop;
end

endmodule