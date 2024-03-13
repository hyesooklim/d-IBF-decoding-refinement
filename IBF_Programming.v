
//Written by prof. Hyesook Lim at Ewha Womans University (2023.01).
//This code programs an IBF.
//Since 2-d memory is not returned, the programmed IBF is written to a file, "IBF1.txt" or "IBF2.txt" depending in input "no".
//The TwoIBFProgramming_Tb.v has two instantiations of this code to generate two IBFs.

`include "headers.v"
module IBF_Programming(input clk, reset, Start, insertDone, input no, input [`KeyField-1: 0] inValue, output wire Done);

reg [`CellSize-1:0] IBF1 [0: `IBFSize-1];
reg [`CellSize-1:0] IBF1_comb_h1, IBF1_comb_h2, IBF1_comb_h3;

wire [`KeyField-1: 0] A;
//wire [`Len-1:0] Length;
wire [`CRCLength-1: 0] CRC_code;
wire [`IndexSize-1:0] h1_index, h2_index, h3_index;
reg [`KeyField-1: 0] keyValue;
wire [`SigField-1:0] inSig;
reg [`SetLen - 1: 0] programmedNo;
wire crcDone;

assign A = inValue;
assign Done = crcDone;

CRCgenerator CRC (clk, reset, Start, A, crcDone, CRC_code);

assign h1_index = (crcDone) ? CRC_code[`CRCLength-1: `CRCLength-`IndexSize] % `IBFSize : 'bz;
assign h2_index = (crcDone) ? CRC_code[`CRCLength-`NextIndexStart-1: `CRCLength-`NextIndexStart-`IndexSize] % `IBFSize : 'bz;
assign h3_index = (crcDone) ? CRC_code[`IndexSize-1: 0] % `IBFSize : 'bz;
//assign inSig = keyValue[`KeyField-1:`KeyField-`SigField];

assign inSig = CRC_code[`CRCLength-`IndexSize-1: `CRCLength-`IndexSize-`SigField];

always @(posedge clk)
	if (reset) keyValue <= 0;
	else keyValue <= (Start) ? inValue: keyValue;

always @(posedge clk)
	if (reset) programmedNo <= 0;
	else if (crcDone) programmedNo <= programmedNo + 1;

/*
//for debugging
integer file1 = 0;
always @(*) begin
	file1 = $fopen ("programmedIBF_debug.txt");
	if ((h1_index == 4200) || (h2_index == 4200) || (h3_index == 4200) )
	$fdisplay (file1, "time = %d, no = %d, inValue  %b,", $time, no, inValue);
end
*/

integer i;
always @(posedge clk)
	if (reset) for(i=0; i<`IBFSize; i=i+1) IBF1[i] = 'b0;
	else if (crcDone) begin
		if ( (h1_index == h2_index) && (h2_index == h3_index) ) // 3 indexes are the same
			IBF1[h1_index] <= IBF1_comb_h1;
		else if ( (h1_index == h2_index) || (h1_index == h3_index) ) begin 
			// if h1 is equal to h2 or h3, h2 or h3 has the priority since they are updated the last
			IBF1[h2_index] <= IBF1_comb_h2;
			IBF1[h3_index] <= IBF1_comb_h3;
		end
		else if (h2_index == h3_index) begin
			IBF1[h1_index] <= IBF1_comb_h1;
			IBF1[h2_index] <= IBF1_comb_h2;
		end
		else begin
			IBF1[h1_index] <= IBF1_comb_h1;
			IBF1[h2_index] <= IBF1_comb_h2;
			IBF1[h3_index] <= IBF1_comb_h3;
		end		
	end

// combinational update statements executed sequentially
always @(*) begin
	if (crcDone)
	     if ( (h1_index == h2_index) && (h2_index == h3_index) ) begin 
		// 3 indexes are the same, updated just once, this way helps the element decoding with the same indexes
		// hence h1 is updated
		IBF1_comb_h1[`CellSize-1:`CellSize-`KeyField] = IBF1[h1_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue;
		IBF1_comb_h1[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;
		IBF1_comb_h1[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
	     end
	     else if ( (h1_index == h2_index) | (h1_index == h3_index) ) begin 
		// it two indexes are the same, the cell with the same index is updated once, hence h2 and h3 updated
		IBF1_comb_h2[`CellSize-1:`CellSize-`KeyField] = IBF1[h2_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue;
		IBF1_comb_h3[`CellSize-1:`CellSize-`KeyField] = IBF1[h3_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue; 

		IBF1_comb_h2[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;
		IBF1_comb_h3[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;

		IBF1_comb_h2[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
		IBF1_comb_h3[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
	     end
	     else if (h2_index == h3_index) begin //h1 and h2 updated
		IBF1_comb_h1[`CellSize-1:`CellSize-`KeyField] = IBF1[h1_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue;
		IBF1_comb_h2[`CellSize-1:`CellSize-`KeyField] = IBF1[h2_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue;

		IBF1_comb_h1[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;
		IBF1_comb_h2[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;

		IBF1_comb_h1[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
		IBF1_comb_h2[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
	     end
	     else begin // three indexes are different, everybody is updated
		IBF1_comb_h1[`CellSize-1:`CellSize-`KeyField] = IBF1[h1_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue;
		IBF1_comb_h2[`CellSize-1:`CellSize-`KeyField] = IBF1[h2_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue;
		IBF1_comb_h3[`CellSize-1:`CellSize-`KeyField] = IBF1[h3_index][`CellSize-1:`CellSize-`KeyField] ^ keyValue; 

		IBF1_comb_h1[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;
		IBF1_comb_h2[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;
		IBF1_comb_h3[`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] 
			= IBF1[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ]^ inSig;

		IBF1_comb_h1[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
		IBF1_comb_h2[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
		IBF1_comb_h3[`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] 
			= IBF1[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] + 1;
	    end
	else begin
	    IBF1_comb_h1 = 'b0;
	    IBF1_comb_h2 = 'b0;
	    IBF1_comb_h3 = 'b0;
	end
end

integer programmed_IBF1 = 0;
integer j=0;
always @(posedge insertDone) begin
	//if (insertDone) begin
		if (no == 1'b0) programmed_IBF1 = $fopen("IBF1.txt");
		else if (no == 1'b1) programmed_IBF1 = $fopen("IBF2.txt");
		for (j=0; j<`IBFSize; j=j+1) begin
			$fdisplay(programmed_IBF1, "%b", IBF1[j]);
		end
		$fclose (programmed_IBF1);	
	//end
end

endmodule


