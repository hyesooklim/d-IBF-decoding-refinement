
//Written by prof. Hyesook Lim at Ewha Womans University (2023.01).
//This code decodes the d-IBF with the proposed method.
//The proposed method has consideration about T1 or T2 cases, and hence does not generate composite keys as distinct elements.
//In order to properly use this design, a directory named "result_prop" should exist in the current simulation directory.
//Result files for experimentA will be made in the result_prop directory.

`include "headers.v"
module d_IBF_Decoding_3 (input clk, reset, Start, input Wr, input [`CellSize-1: 0] IBF_Row, input [`IndexSize:0] Addr, 
			output reg wrDone, output reg allDone, output wire [`SetLen-1:0] decodedNum,
			output reg [15:0] sigNotEqualCount, T1CaseCount, T2CaseCount );

reg [`CellSize-1:0] IBF [0: `IBFSize-1];
reg [`CellSize-1:0] IBF_comb [0: `IBFSize-1];


reg pureListupDone;

parameter S0 = 0, S1 = 1;
reg state, nextState;
reg IBF_Load, pureListDecoding;
wire pureListEmpty;
reg IBF_Empty;

wire [`CRCLength-1:0] CRC_code;
wire pureDone;
reg Done;
integer i;
wire [`CellSize-1:0] currentCell;
reg preStart;
wire crcStart;
//wire [`KeyField-1:0] Key, h1_key, h2_key, h3_key;
// to differenciate Set1 and Set2
wire [`KeyField:0] Key;
wire [`KeyField-1:0] h1_key, h2_key, h3_key;

wire [`SigField-1:0] sigField, inSig, h1_sig, h2_sig, h3_sig;
wire sigNotEqual;
//wire [`CountField-1:0] countField, h1_count, h2_count, h3_count;
wire signed [`CountField-1:0] countField, h1_count, h2_count, h3_count;

reg [0:`IBFSize-1] pureList, pureListPre;
reg [`IndexSize-1:0] pureIndex;
wire [`IndexSize-1:0] h1_index, h2_index, h3_index;
wire cellSkip, fakePure;
reg [1: `DecodeMax] T2CasePre, T2CaseNow;
wire [1: `DecodeMax] T2CaseList;
//reg [`KeyField:0] decodedList [1: `DecodeMax] ;
// to differentiate Set1 and Set2
reg [`KeyField+1:0] decodedList [1: `DecodeMax] ;
reg [`SetLen-1:0] decodeIndex; 

CRCgenerator CRC (clk, reset, crcStart, Key[`KeyField-1:0], crcDone, CRC_code);

always @(posedge clk)
	if (reset) Done <= 1'b0;
	else Done <= pureDone;

always @(posedge clk)
	if (reset) allDone <= 1'b0;
	else allDone <= Done;


assign decodedNum = (decodeIndex-1-(T2CaseCount<<1));

//IBF processing
always @(posedge clk) begin
	if (reset) wrDone <= 0;
	else if ((IBF_Load) & (Wr)) begin
		if (Addr <`IBFSize) begin 
			IBF[Addr] <= IBF_Row; 
			wrDone <= 0; 
		end
		else if (Addr ==`IBFSize)  wrDone <= 1;
	end
	else begin 
		wrDone <= 0;
		if (crcDone & !pureDone & !fakePure) begin
			IBF[h1_index] <= IBF_comb[h1_index];
			IBF[h2_index] <= IBF_comb[h2_index];
			IBF[h3_index] <= IBF_comb[h3_index];
		end
	end
end


always @(posedge clk) 
	if (reset) state <= S0;
	else state <= nextState;

always @(*) begin
	case (state)
	S0: begin //IBF Load
		IBF_Load = 1; 
		pureListDecoding = 0;
		if (wrDone) nextState = S1; 
		else nextState = S0; 
	end 
	S1: begin //Decoding in pureList
		IBF_Load = 0; 
		pureListDecoding = 1;
		if (pureDone) nextState = S0;
		else nextState = S1;
	end 
	default: begin
		IBF_Load = 0; 
		pureListDecoding = 0;
	end
	endcase
end

assign pureListEmpty = ~|pureList; 
always @(*) begin
	if (pureDone) 
		 for (i=0;i<`IBFSize; i=i+1) IBF_Empty = (IBF[i] == 'b0) ? 1: 0;
	else IBF_Empty = 0;
end

assign pureDone = (pureListDecoding & pureListEmpty ) ? 1: 0;

assign h1_index = (pureListDecoding & crcDone) ? CRC_code[`CRCLength-1: `CRCLength-`IndexSize] % `IBFSize : 'bz;
assign h2_index = (pureListDecoding & crcDone) ? CRC_code[`CRCLength-`NextIndexStart-1: `CRCLength-`NextIndexStart-`IndexSize] % `IBFSize  : 'bz;
assign h3_index = (pureListDecoding & crcDone) ? CRC_code[`IndexSize-1: 0] % `IBFSize : 'bz;

/*
//for debugging
integer file1 = 0;
always @(*) begin
	file1 = $fopen ("debug1.txt");
	if ( !cellSkip && (h1_index == 4200) || (h2_index == 4200) || (h3_index == 4200) ) begin
		$fdisplay (file1, "time = %d, h1_index = %d, h2_index = %d, h3_index = %d", 
				$time, h1_index, h2_index, h3_index);
		$fdisplay (file1, "d-IBF[%d] = %b",
			h1_index, IBF[h1_index]); 
		$fdisplay (file1, "d-IBF[%d] = %b",
			h2_index, IBF[h2_index]); 
		$fdisplay (file1, "d-IBF[%d] = %b",
			h3_index, IBF[h3_index]); 
	end
	else if ( !cellSkip && (h1_index == 5008) || (h2_index == 5008) || (h3_index == 5008) ) begin
		$fdisplay (file1, "time = %d, h1_index = %d, h2_index = %d, h3_index = %d", 
				$time, h1_index, h2_index, h3_index);
		$fdisplay (file1, "d-IBF[%d] = %b",
			h1_index, IBF[h1_index]); 
		$fdisplay (file1, "d-IBF[%d] = %b",
			h2_index, IBF[h2_index]); 
		$fdisplay (file1, "d-IBF[%d] = %b",
			h3_index, IBF[h3_index]); 
	end
	else if ( !cellSkip && (h1_index == 4046) || (h2_index == 4046) || (h3_index == 4046) ) begin
		$fdisplay (file1, "time = %d, h1_index = %d, h2_index = %d, h3_index = %d", 
				$time, h1_index, h2_index, h3_index);
		$fdisplay (file1, "d-IBF[%d] = %b",
			h1_index, IBF[h1_index]); 
		$fdisplay (file1, "d-IBF[%d] = %b",
			h2_index, IBF[h2_index]); 
		$fdisplay (file1, "d-IBF[%d] = %b",
			h3_index, IBF[h3_index]); 
	end
end
*/	

always @(posedge clk) 
	if (reset) pureListupDone <= 0; 
	else if (wrDone) pureListupDone <= 1;
	else pureListupDone <= 0;

always @(posedge clk) begin
	if (reset) pureIndex <= 0;
	else if (pureListDecoding & crcDone) pureIndex <= (pureIndex + 1)  % `IBFSize;
	if (pureListDecoding & !pureList[pureIndex]) pureIndex <= (pureIndex + 1) % `IBFSize; //non-pure cells are skiped
end

assign T1Case = (pureListDecoding & crcDone & 
	((pureIndex != h1_index) & (pureIndex != h2_index) & (pureIndex != h3_index)) ) ? 1'b1: 1'b0;

always @(posedge clk)
	if (reset) T1CaseCount <= 0;
	else if (T1Case) T1CaseCount <= T1CaseCount + 1;

always @(posedge clk)
	if (reset) sigNotEqualCount <= 0;
	else if (sigNotEqual) sigNotEqualCount <= sigNotEqualCount + 1;

assign fakePure = sigNotEqual | T1Case;
assign cellSkip = (!pureList[pureIndex] | fakePure) ? 1: 0;


//fill an entry to the decodedList 
always @(posedge clk) 
	if (reset) decodeIndex <= 1; 
	else if (wrDone) decodeIndex <= 1;
	else if (pureListDecoding & crcDone & !fakePure) decodeIndex <= decodeIndex+1;

//Type2Error is identified if the same Key is already decoded in the decoded list. 
//In this case, the two same keys became invalid by setting the first bit with 0 
always @(posedge clk)
	if (reset) begin T2CaseNow <= 0; T2CaseCount <= 0; end
	else if (pureListDecoding & crcDone & !fakePure) 
		for (i=1; i<(decodeIndex + 1); i=i+1) 
			//if (decodedList[i] == {1'b1, Key}) begin
			if (decodedList[i][`KeyField-1:0] == Key[`KeyField-1:0]) begin
				T2CaseNow[decodeIndex] = 1'b1; T2CaseCount <= T2CaseCount + 1; 
			end

always @(posedge clk) 
	if (reset) T2CasePre <= 'b0; 
	else if (pureListDecoding & crcDone & !fakePure) 
		for (i=1; i<(decodeIndex + 1); i=i+1) 
			//if (decodedList[i] == {1'b1, Key}) T2CasePre[i] = 1'b1; 
			if (decodedList[i][`KeyField-1:0] == Key[`KeyField-1:0]) T2CasePre[i] = 1'b1; 

assign T2CaseList = T2CasePre | T2CaseNow;

always @(posedge clk) begin
	if (reset) for (i=1;i<`DecodeMax; i=i+1)decodedList[i] <= 0;
	else if (pureListDecoding & crcDone & !fakePure) decodedList[decodeIndex] <= {1'b1, Key};
	//for (i=1; i<(decodeIndex + 1); i=i+1) if (T2CaseList[i]) decodedList[i] <= {1'b0, decodedList[i][`KeyField-1:0]} ; 
	for (i=1; i<(decodeIndex + 1); i=i+1) 
		if (T2CaseList[i]) decodedList[i] <= {1'b0, decodedList[i][`KeyField:0]} ; 
				//T2Case entry becomes invalid
end

//crcStart generation
always @(posedge clk) begin
	if (reset) preStart <= 0; 
	else if (pureListDecoding & !pureListEmpty & (pureListupDone | crcDone | cellSkip)) 
		preStart <= 1;
	else preStart <= 0;
end

assign crcStart = preStart & !cellSkip;

//parsing the current cell of pureIndex
assign currentCell = (pureListDecoding) ? IBF[pureIndex]: 'b0;
//to handle negative count, Key has been modified
//assign Key = (pureListDecoding & pureList[pureIndex]) ? currentCell[`CellSize-1:`CellSize-`KeyField] : 'b0;
assign Key = (pureListDecoding & pureList[pureIndex]) ? 
		( (countField > 0) ? {1'b0, currentCell[`CellSize-1:`CellSize-`KeyField]} //Set1
		: {1'b1, currentCell[`CellSize-1:`CellSize-`KeyField]} ) //Set2
		: 'b0;
assign sigField = IBF[pureIndex][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ];
assign countField = (pureListDecoding & pureList[pureIndex]) ? 
			currentCell[`CellSize-`KeyField-`SigField-1:`CellSize-`KeyField-`SigField-`CountField] : 'b0;

assign inSig = (pureListDecoding & crcDone) ? CRC_code[`CRCLength-`IndexSize-1: `CRCLength-`IndexSize-`SigField]: 'bz;
assign sigNotEqual = (pureListDecoding & crcDone & (inSig != sigField) ) ? 1'b1: 1'b0;
	

//pure list generation, reset the current entry after processing and set the new one
//following always block has been modified to handle negative count on Feb. 29 2024
always @(*) begin
	if (crcDone & !pureDone) begin
	     if (!fakePure) begin
		pureListPre[pureIndex] = 0;	             
		case(pureIndex) 
		//cells only pointed by h1, h2, h3 indexes should be considered whether they become new pure cells
		h1_index: begin 
		   pureListPre[h1_index] = 0;
		   if (h1_count == 1) begin //purecell is S1 element
	           	if (h1_index == h2_index) begin // need to consider h3 only
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) )
					|| (h3_count == 2) ) pureListPre[h3_index] = 1;
			        else pureListPre[h3_index] = 0;
		        end
		        else if (h1_index == h3_index) begin // need to consider h2 only
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 2) ) pureListPre[h2_index] = 1;
		        	else pureListPre[h2_index] = 0;
			end
			else if (h2_index == h3_index) begin // need to consider h2 or h3 only
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 2) ) pureListPre[h2_index] = 1;
		        	else pureListPre[h2_index] = 0;
			end
			else begin // 3 indexes are different
			        if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 2) ) pureListPre[h2_index] = 1;
				else pureListPre[h2_index] = 0;
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) ) 
					|| (h3_count == 2) ) pureListPre[h3_index] = 1; 
				else pureListPre[h3_index] = 0;
			end
		   end
		   else begin //if (h1_count == 'hFFFF), purecell is S2 element
	           	if (h1_index == h2_index) begin // need to consider h3 only
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) )
					|| (h3_count == 'hFFFE) ) pureListPre[h3_index] = 1;
			        else pureListPre[h3_index] = 0;
		        end
		        else if (h1_index == h3_index) begin // need to consider h2 only
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 'hFFFE) ) pureListPre[h2_index] = 1;
		        	else pureListPre[h2_index] = 0;
			end
			else if (h2_index == h3_index) begin // need to consider h2 or h3 only
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 'hFFFE) ) pureListPre[h2_index] = 1;
		        	else pureListPre[h2_index] = 0;
			end
			else begin // 3 indexes are different
			        if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 'hFFFE) ) pureListPre[h2_index] = 1;
				else pureListPre[h2_index] = 0;
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) )
					|| (h3_count == 'hFFFE) ) pureListPre[h3_index] = 1; 
				else pureListPre[h3_index] = 0;
			end
		   end
		end
		h2_index: begin 
		   pureListPre[h2_index] = 0;
		   if (h2_count == 1) begin //purecell is S1 element
	           	if (h2_index == h1_index) begin // need to consider h3 only
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) )
					|| (h3_count == 2) ) pureListPre[h3_index] = 1;
			        else pureListPre[h3_index] = 0;
		        end
		        else if (h2_index == h3_index) begin // need to consider h1 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 2) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else if (h1_index == h3_index) begin // need to consider h1 or h3 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 2) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else begin // 3 indexes are different
			        if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 2) ) pureListPre[h1_index] = 1;
				else pureListPre[h2_index] = 0;
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) ) 
					|| (h3_count == 2) ) pureListPre[h3_index] = 1; 
				else pureListPre[h3_index] = 0;
			end
		   end
		   else begin //if (h1_count == 'hFFFF), purecell is S2 element
	           	if (h2_index == h1_index) begin // need to consider h3 only
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) )
					|| (h3_count == 'hFFFE) ) pureListPre[h3_index] = 1;
			        else pureListPre[h3_index] = 0;
		        end
		        else if (h2_index == h3_index) begin // need to consider h1 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 'hFFFE) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else if (h1_index == h3_index) begin // need to consider h1 or h3 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 'hFFFE) ) pureListPre[h2_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else begin // 3 indexes are different
			        if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 'hFFFE) ) pureListPre[h1_index] = 1;
				else pureListPre[h1_index] = 0;
				if ( ( (IBF[h3_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h3_count == 0) )
					|| (h3_count == 'hFFFE) ) pureListPre[h3_index] = 1; 
				else pureListPre[h3_index] = 0;
			end
		   end
		end
		h3_index: begin 
		   pureListPre[h3_index] = 0;
		   if (h3_count == 1) begin //purecell is S1 element
	           	if (h3_index == h1_index) begin // need to consider h2 only
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 2) ) pureListPre[h2_index] = 1;
			        else pureListPre[h2_index] = 0;
		        end
		        else if (h3_index == h2_index) begin // need to consider h1 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 2) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else if (h1_index == h2_index) begin // need to consider h1 or h2 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 2) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else begin // 3 indexes are different
			        if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 2) ) pureListPre[h1_index] = 1;
				else pureListPre[h1_index] = 0;
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) ) 
					|| (h2_count == 2) ) pureListPre[h2_index] = 1; 
				else pureListPre[h2_index] = 0;
			end
		   end
		   else begin //if (h1_count == 'hFFFF), purecell is S2 element
	           	if (h3_index == h1_index) begin // need to consider h2 only
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 'hFFFE) ) pureListPre[h2_index] = 1;
			        else pureListPre[h2_index] = 0;
		        end
		        else if (h3_index == h2_index) begin // need to consider h1 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 'hFFFE) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else if (h1_index == h2_index) begin // need to consider h1 or h2 only
				if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 'hFFFE) ) pureListPre[h1_index] = 1;
		        	else pureListPre[h1_index] = 0;
			end
			else begin // 3 indexes are different
			        if ( ( (IBF[h1_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h1_count == 0) )
					|| (h1_count == 'hFFFE) ) pureListPre[h1_index] = 1;
				else pureListPre[h1_index] = 0;
				if ( ( (IBF[h2_index][`CellSize-1:`CellSize-`KeyField] != 0 ) && (h2_count == 0) )
					|| (h2_count == 'hFFFE) ) pureListPre[h2_index] = 1; 
				else pureListPre[h2_index] = 0;
			end
		   end
		end
		endcase
	   end
	   else pureListPre[pureIndex] = 0;
	end
	else pureListPre = pureList;
end


always @(posedge clk) begin
	if (reset) begin 
		pureList <= 'b0; 
	end
	else if (wrDone) begin
		for (i=0;i<`IBFSize; i=i+1) //initial pure list, modified for including -1
			if ((IBF[i][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] == 1) |  
				(IBF[i][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] == 'hFFFF) )
				pureList[i] <= 1;
			else pureList[i] <= 0;
	end
	else if (crcDone & !pureDone) pureList <= pureListPre; //new generated pure cells during decoding
end

//parsing each field in IBF
assign h1_key = (crcDone & !pureDone & !fakePure) ? IBF[h1_index][`CellSize-1:`CellSize-`KeyField]:'bz;
assign h2_key = (crcDone & !pureDone & !fakePure) ? IBF[h2_index][`CellSize-1:`CellSize-`KeyField]:'bz;
assign h3_key = (crcDone & !pureDone & !fakePure) ? IBF[h3_index][`CellSize-1:`CellSize-`KeyField]:'bz;

assign h1_sig = (crcDone & !pureDone & !fakePure) ? IBF[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField]:'bz;
assign h2_sig = (crcDone & !pureDone & !fakePure) ? IBF[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField]:'bz;
assign h3_sig = (crcDone & !pureDone & !fakePure) ? IBF[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField]:'bz;

assign h1_count = (crcDone & !pureDone & !fakePure) ? IBF[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField]: 'bz;
assign h2_count = (crcDone & !pureDone & !fakePure) ? IBF[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField]: 'bz;
assign h3_count = (crcDone & !pureDone & !fakePure) ? IBF[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField]: 'bz;


//IBF processing. Since indexes could be the same, 
//the following processing should be performed sequentially in an combinational always block.
//following always block has been modified to handle negative count on Feb. 29 2024
always @(*) begin
	IBF_comb[h1_index] = IBF[h1_index];
	IBF_comb[h2_index] = IBF[h2_index];
	IBF_comb[h3_index] = IBF[h2_index];
	case(pureIndex)
		h1_index: begin 
	            if ( (h1_index == h2_index) && (h2_index == h3_index) ) begin //three indexes are the same, need to care just once
		        IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
		        if (h1_count == 1) 
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
	   	        else //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
	            end
		    else if (h1_index == h2_index) begin //if h1 and h2 are the same, need to care h1 and h3
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
		        if (h1_count == 1) begin
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
	            end
		    else if ((h1_index == h3_index) || (h2_index == h3_index) )begin 
			//if h1 and h3 are the same or h2 and h3 are the same, need to care h1 and h2
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
		        if (h1_count == 1) begin
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
			end
	   	        else begin //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
			 	IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count + 1;
			end
	            end
		    else begin //three indexes are different, need to care all of them
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
			if (h1_count == 1) begin
				IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
		     		IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
				IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
		    end
		end
		h2_index: begin 
		    if ( (h1_index == h2_index) && (h2_index == h3_index) ) begin //three indexes are the same, need to care just 1
		        IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
		        if (h2_count == 1) 
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
	   	        else //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
	            end
		    else if (h2_index == h1_index) begin //if h1 and h2 are the same, need to care h2 and h3
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
		        if (h2_count == 1) begin
		     		IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
				IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
	            end
		    else if ( (h2_index == h3_index) ||(h1_index == h3_index) ) begin 
			//if h2 and h3 are the same or h1 and h3 are the same, need to care h1 and h2
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
		        if (h2_count == 1) begin
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
			end
	   	        else begin //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
			 	IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count + 1;
			end
	            end
		    else begin //three indexes are different, need to care all of them
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
			if (h2_count == 1) begin
				IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
		     		IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
				IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
		    end
		end
		h3_index: begin 
		    if ( (h1_index == h2_index) && (h2_index == h3_index) ) begin //three indexes are the same, need to care just 1
		        IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
		        if (h3_count == 1) 
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
	   	        else //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
	            end
		    else if (h3_index == h1_index) begin //if h3 and h1 are the same, need to care h3 and h2
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
		        if (h3_count == 1) begin
		     		IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
				IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
	            end
		    else if ((h3_index == h2_index) || (h1_index == h2_index)) begin 
			//if h3 and h2 are the same or h1 and h2 are the same, need to care h1 and h3
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
		        if (h3_count == 1) begin
		     		IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
			 	IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
	            end
		    else begin //three indexes are different, need to care all of them
			IBF_comb[h1_index][`CellSize-1:`CellSize-`KeyField] = h1_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h1_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h1_sig ^ inSig;
			IBF_comb[h2_index][`CellSize-1:`CellSize-`KeyField] = h2_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h2_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h2_sig ^ inSig;
			IBF_comb[h3_index][`CellSize-1:`CellSize-`KeyField] = h3_key ^ Key[`KeyField-1:0];
	   	        IBF_comb[h3_index][`CellSize-`KeyField-1:`CellSize-`KeyField-`SigField ] = h3_sig ^ inSig;
			if (h3_count == 1) begin
				IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count - 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count - 1;
		     		IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count - 1;
			end
	   	        else begin //If it was -1, should be increased
				IBF_comb[h1_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h1_count + 1;
				IBF_comb[h2_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h2_count + 1;
			 	IBF_comb[h3_index][`CellSize-`KeyField-`SigField-1: `CellSize-`KeyField-`SigField-`CountField] = h3_count + 1;
			end
		    end
		end
	endcase	 
end

integer result1 = 0, result2 = 0, result3 = 0, result4 = 0;
wire [3:0] fileNo;

assign fileNo = (`IBFSize == 40) ? 1 : (`IBFSize == 60) ? 2: (`IBFSize == 80) ? 3 : (`IBFSize == 100) ? 4 :
  (`IBFSize == 10000) ? 5 : (`IBFSize == 15000) ? 6: (`IBFSize == 20000) ? 7 : (`IBFSize == 25000) ? 8 :
  (`IBFSize == 1000) ? 9 : (`IBFSize == 1500) ? 10: (`IBFSize == 2000) ? 11 : (`IBFSize == 2500) ? 12 : 
  (`IBFSize == 30000) ? 13: 0;

always @(posedge Done) begin

    case (fileNo)
	1: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_40.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_40.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_40.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_40.txt");
	end
	2: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_60.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_60.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_60.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_60.txt");
	end
	3: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_80.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_80.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_80.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_80.txt");
	end
	4: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_100.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_100.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_100.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_100.txt");
	end
	5: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_10000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_10000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_10000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_10000.txt");
	end
	6: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_15000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_15000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_15000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_15000.txt");
	end
	7: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_20000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_20000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_20000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_20000.txt");
	end
 	8: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_25000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_25000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_25000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_25000.txt");
	end
	13: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_30000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_30000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_30000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_30000.txt");
	end
	9: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_1000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_1000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_1000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_1000.txt");
	end
	10: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_1500.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_1500.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_1500.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_1500.txt");
	end
	11: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_2000.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_2000.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_2000.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_2000.txt");
	end
	12: begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop_2500.txt");
		result2 = $fopen ("./result_prop/decodedList_prop_2500.txt");
		result3 = $fopen ("./result_prop/Set1_distinct_2500.txt");
		result4 = $fopen ("./result_prop/Set2_distinct_2500.txt");
	end
	default:  begin 
		result1 = $fopen ("./result_prop/d-IBF_Left_prop.txt");
		result2 = $fopen ("./result_prop/decodedList_prop.txt");
		result3 = $fopen ("./result_prop/Set1_distinct.txt");
		result4 = $fopen ("./result_prop/Set2_distinct.txt");
	end
    endcase

	for (i=0; i<`IBFSize; i=i+1) $fdisplay (result1, "IBF[%d] = %b", i, IBF[i]);
	for (i=1; i<decodeIndex; i=i+1)  begin
		$fdisplay (result2, "%b", decodedList[i] );
		if (decodedList[i][`KeyField+1:`KeyField] == 2'b10) $fdisplay (result3, "%b", decodedList[i][`KeyField-1:0] ); //Set1
		else if (decodedList[i][`KeyField+1:`KeyField] == 2'b11)$fdisplay (result4, "%b", decodedList[i][`KeyField-1:0] ); //Set2
	end
	$fclose (result1);
	$fclose (result2);
	$fclose (result3);
	$fclose (result3);
end
	
endmodule
