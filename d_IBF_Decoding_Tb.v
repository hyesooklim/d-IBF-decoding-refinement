
//Written by prof. Hyesook Lim at Ewha Womans University (2023.01).
//This testbench is for testing the proposed decoding algorithm design by d_IBF_decoding_2.v for experiment A.
//The decoded results generated in ./result_prop directory are compared with correct answers in "Set_differnce.txt".
//The comparison results are written to statistics file.

`include "./headers.v"

module d_IBF_Decoding_Tb;
//parameter tlimit = 2000;
//initial #tlimit $stop;
reg [`CellSize-1:0] d_IBF [0: `IBFSize-1];

reg Wr;
reg [`IndexSize:0] Addr;
wire [`CellSize-1: 0] IBF_Row;
wire [`SetLen - 1: 0] decodedNum;

// to compare the result with correct answer
reg [`KeyField+1:0] SetDiff [0:`S1Distinct+`S2Distinct-1];
//reg [`KeyField:0] DecodedList [0:`DecodeMax-1];
//to differentiate Set1 and Set2
reg [`KeyField+1:0] DecodedList [0:`DecodeMax-1];
reg [0:`S1Distinct+`S2Distinct-1] Found;
wire [15:0] sigNotEqualCount, T1CaseCount, T2CaseCount;

reg clk = 0, reset = 1, Start = 0;

d_IBF_Decoding_3 d_IBF_Decoding_3 (clk, reset, Start, Wr, IBF_Row, Addr, wrDone, allDone, decodedNum, 
					sigNotEqualCount, T1CaseCount, T2CaseCount);

initial $readmemb ("d-IBF.txt", d_IBF);
initial $readmemb ("Set_Difference.txt", SetDiff);


always #5 clk = ~clk; //clock generation
initial #10 reset = 0; //reset de-activation

//Load dIBF
always @(posedge clk)
	if (reset) begin
		Wr = 1;
		Addr = 0;	
	end
	else if ((!wrDone) & (Addr <`IBFSize)) begin Addr = Addr + 1; end
	else if (Addr == `IBFSize) Wr = 0; 

assign IBF_Row = d_IBF[Addr]; 


integer foundCount = 0, notFoundCount = 0;
integer i, j, stat;
wire [3:0] fileNo;
assign fileNo = (`IBFSize == 40) ? 1 : (`IBFSize == 60) ? 2: (`IBFSize == 80) ? 3 : (`IBFSize == 100) ? 4 :
  (`IBFSize == 10000) ? 5 : (`IBFSize == 15000) ? 6: (`IBFSize == 20000) ? 7 : (`IBFSize == 25000) ? 8 :
  (`IBFSize == 1000) ? 9 : (`IBFSize == 1500) ? 10: (`IBFSize == 2000) ? 11 : (`IBFSize == 2500) ? 12 : 
  (`IBFSize == 30000) ? 13: 0;

always @(posedge allDone) begin
	case (fileNo)
	1: $readmemb ("./result_prop/decodedList_prop_40.txt", DecodedList);
	2: $readmemb ("./result_prop/decodedList_prop_60.txt", DecodedList);
	3: $readmemb ("./result_prop/decodedList_prop_80.txt", DecodedList);
	4: $readmemb ("./result_prop/decodedList_prop_100.txt", DecodedList);
	5: $readmemb ("./result_prop/decodedList_prop_10000.txt", DecodedList);
	6: $readmemb ("./result_prop/decodedList_prop_15000.txt", DecodedList);
	7: $readmemb ("./result_prop/decodedList_prop_20000.txt", DecodedList);
	8: $readmemb ("./result_prop/decodedList_prop_25000.txt", DecodedList);
	13: $readmemb ("./result_prop/decodedList_prop_30000.txt", DecodedList);
	9: $readmemb ("./result_prop/decodedList_prop_1000.txt", DecodedList);
	10: $readmemb ("./result_prop/decodedList_prop_1500.txt", DecodedList);
	11: $readmemb ("./result_prop/decodedList_prop_2000.txt", DecodedList);
	12: $readmemb ("./result_prop/decodedList_prop_2500.txt", DecodedList);
	default:  $readmemb ("./result_prop/decodedList_prop.txt", DecodedList);
	endcase

	for (i=0;i<`S1Distinct+`S2Distinct; i = i+1) Found[i] = 0;
	for (i=0;i<`S1Distinct+`S2Distinct; i = i+1) begin
		   for (j=0;j<`DecodeMax;j=j+1) begin
			if (SetDiff[i] == DecodedList[j]) begin
				foundCount = foundCount + 1; Found[i] = 1;
				//$display (" %d element is located in decodedList %d", i, j);
			end
		   end
		   if (!Found[i]) begin $display ("%d element not found", i); notFoundCount = notFoundCount + 1; end
	end
	case (fileNo)
	1: stat = $fopen ("./result_prop/statistics_prop_40.txt");
	2: stat = $fopen ("./result_prop/statistics_prop_60.txt");
	3: stat = $fopen ("./result_prop/statistics_prop_80.txt");
	4: stat = $fopen ("./result_prop/statistics_prop_100.txt");
	5: stat = $fopen ("./result_prop/statistics_prop_10000.txt");
	6: stat = $fopen ("./result_prop/statistics_prop_15000.txt");
	7: stat = $fopen ("./result_prop/statistics_prop_20000.txt");
	8: stat = $fopen ("./result_prop/statistics_prop_25000.txt");
	13: stat = $fopen ("./result_prop/statistics_prop_30000.txt");
	9: stat = $fopen ("./result_prop/statistics_prop_1000.txt");
	10: stat = $fopen ("./result_prop/statistics_prop_1500.txt");
	11: stat = $fopen ("./result_prop/statistics_prop_2000.txt");
	12: stat = $fopen ("./result_prop/statistics_prop_2500.txt");
	default:  stat = $fopen ("./result_prop/statistics_prop.txt");
	endcase
	
	$fdisplay (stat, "Proposed: Decoding complete! number of decoded elements: %d out of %d", decodedNum, `S1Distinct+`S2Distinct);
	$fdisplay (stat, "No. of elements decoded correctly = %d, No. of unfound elements = %d", foundCount, notFoundCount);
	$fdisplay (stat, "time = %d, No. of SigNotEqual = %d, No of T1 Cases = %d, No of T2 Cases = %d", $time,
			sigNotEqualCount, T1CaseCount, T2CaseCount);
	$fclose(stat);
	#20 $stop;
end 

endmodule
