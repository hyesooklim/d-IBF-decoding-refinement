
//Written by prof. Hyesook Lim at Ewha Womans University (2023.01).
//This header file is very important. 
//Each constant value should be consistent with each other.
//The KeyField is the number of bits allocated for each element. ExpA should be 14 bits and ExpB should be 17 bits.
//SigField is fixed as 4 bits.
//CountField is fixed as 16 bits to avoid overflow.
//CellSize length should be equal to the summation of KeyField + SigField + CountField
//The IBF size should be consistent with the IndexSize. For example, in ExpA, IBFSize 40 and 60 should have IndexSize 6
//and IBFSize 80 and 120 should have IndexSize 7.
//Set size is adjusted for each experiment.
//SetLen is equal to KeyField
//DecodeMax should be large enough to accommodate all the decoded elements.
//CRCLength is fixed as 32-bit.

`timescale 1ns/1ns
`define CellSize 64 //should be equal to KeyField + SigField + CountField. 
//34 for ExpA. 40 for ExpC
//For ExpB, the size of KeyField has been extended to 32 bits to avoid misclassification on Mar. 4, 2024
//Hence 64 for ExpB
`define KeyField 32 //14 for ExpA. 32 for ExpB. 20 for ExpC
`define SigField 16
`define CountField 16

`define IBFSize 25000 //for ExpA, this should be 40, 60, 80, 100. For ExpB, this should be 10000, 15000, 20000, 25000
//for ExpC, 1K, 1.5K, 2K, 2.5K
`define IndexSize 15 //for ExpA, this should be 6, 6, 7, and 7. For ExpB, this should be 14, 14, 15, and 15.
//For ExpC, this should be 10, 11, 11, 12
`define NextIndexStart 5 //to generate 3 hash indexes, index1 is extracted from 31, index2 is extracted from 26.


`define SetSize  100000 //10000 for ExpA and 100000 for ExpB. 1000000 for ExpC
`define Set2Size 100000 //10020 for ExpA and 100000 for ExpB.  1000000 for ExpC
`define Common 95000 //9990 for ExpA and 95000 for ExpB. 999500 for ExpC
`define S1Distinct 5000 //SetSize - Common, 10 for ExpA and 5000 for ExpB. 500 for ExpC
`define S2Distinct 5000 //Set2Size - Common, 30 for ExpA and 5000 for ExpB.  500 for ExpC
`define SetLen 32 //14 for ExpA and 32 for ExpB. 20 for ExpC
`define DecodeMax 13000 //for ExpA, this should 100. For ExpB, this should be 13000. For ExpC, 2000
//the number of decoded elements could be more than the sum of S1Distinct and S2Distinct 
//because Type3Error will be listed starting with '0'

`define CRCLength 32

