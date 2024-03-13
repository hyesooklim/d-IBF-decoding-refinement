This simulation is for the performance evaluation of d-IBF decoding algorithm.
1) We need to generate two sets first which have a small number of different elements and 
the majority of elements is common.
2) Need to program two IBFs, each of which is for each set.
3) Need to perform subtract operation to build a d-IBF for two IBFs.
Upto this point, no difference between the conventional algorithm and the proposed algorithm.
4) In decoding the d-IBF, the conventional algorithm only considers sigNotEqual case and does not 
consider T1 cases or T2 cases, in determining whether a cell is a genuine pure cell.
In decoding the d-IBF, the proposed algorithm considers sigNotEqual cases and T1 cases,
and these cases are skipped without decoding because they are not genuine pure cell. 
On the other hand, T2 cases are not obvious before decoding, these cells are decoded. However,
if the same element is decoded twice, it is noticed that T2 case occurs. Hence, both decoded 
elements becomes invalid in the decodedList. In this way, the T2 cases are solved in our proposed
algorithm.
5) Resulting files are generated in the directory of "./result_conv" or "./result_prop". Hence, 
the directories with those name should be made in the current directory before starting simulation. 

//Files
- headers.v : define and set parameters (This file is very important. The numbers should be 
consistent each other. Otherwise, simulation results are wrong)
- LFSR: random number generation for set generation in any length
- CRCgenerator: 32-bit CRC. hash index generation for IBF programming
- TwoSetGenerator_Tb: Set1 and Set2 are generated, and Set_Difference.txt is also generated.
- IBFProgramming, TwoIBFProgramming_Tb: IBF1 and IBF2 are generated for Set1 and Set2, respectively
- d_IBF_Build, d_IBF_Build_Tb: a d-IBF is constructed
- d_IBF_Decoding_3, d_IBF_Decoding_Tb: d-IBF is decoded using the proposed algorithm.
IBF_left and decodedList are generated, and decoded list is compared with Set_Difference and the
statistics result is stored in statistics file. In this version, decoded distinct elements are distinguished
by their membership of S1 or S2.

//Directory: Following directories should be constructed first to store simulation results.
Otherwise, simulation does not work.
- result_conv
- result_prop

//Procedure
0) set headers.v
- Set Size, IBF Size, Cell Size, and accordingly index sizes should be set
1) TwoSetGenerator_Tb: Sets S1, S2, Set_Difference are generated
2) TwoIBFProgramming_Tb: IBF1 and IBF2 are programmed
3) d_IBF_Build_Tb: d-IBF is constructed
4) d_IBF_Decoding_Tb: Following files are generated
- IBF_left (if every distinct element is decoded, then IBF_left has all-zero entries)
- decodedList(has decoded elements. format: {1-bit valid, x-bit element}
- Elements with valid bit 0 are T2Case. A pair means the case is fixed. No pair means not fixed.
- The number of decoded elements does not include the T2CaseCount if it is fixed in the proposed
algorithm.

* We found out that hash indexes generated from idSum field have the same role of sigSum field,
since they can be used in differentiating one idSum from another. Hence, no need to allocate
a large number of bits for sigSum. 

*Mar. 3, 2024
1) In case that the same hash indexes are generated for a key, if we increase the count values according to the number of hash indexes, the number of elements stored in a cell is not equal to the count value. In this case, it is not possible to distinguish the set membership of an element using the count value.
In other words, in order to identify the set membership of an element using the count value, we had to store the key once in a cell by increasing the count value by one even though the same hash indexes are generated for a key. 
This way also helps to decode the element with a single value in all the hash indexes.
IBF_programming.v and d_IBF_decoding_3.v reflect this change. 

2) For ExpB, the number of bits of each element is extended to 32 bits to avoid the error caused by the case that a composite number is equal to a distinct number.

3) Simulation Results (X means FAIL, O means SUCCESS)
ExpA (d=40): IBF Size 40 (X), 60(O), 80(O), 100(O)
ExpB (d=10000): IBF Size 10000(X), 15000(X), 20000(O), 25000(O)
ExpC (d=1000): IBF Size 1000(X), 1500(O), 2000(O), 2500(O)
