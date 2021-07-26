# Details

Date : 2021-07-20 15:25:13

Directory c:\Users\ywj\Desktop\GitLab\OPT_refactor\Src\refactor

Total : 46 files,  9364 codes, 1290 comments, 1048 blanks, all 11702 lines

[summary](results.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [AXIInteract.sv](/AXIInteract.sv) | SystemVerilog | 1,663 | 155 | 118 | 1,936 |
| [CPU_Defines.svh](/CPU_Defines.svh) | SystemVerilog | 575 | 68 | 59 | 702 |
| [Cache_Defines.svh](/Cache_Defines.svh) | SystemVerilog | 90 | 22 | 21 | 133 |
| [Cache_options.svh](/Cache_options.svh) | SystemVerilog | 13 | 5 | 9 | 27 |
| [CommonDefines.svh](/CommonDefines.svh) | SystemVerilog | 290 | 65 | 74 | 429 |
| [Control.sv](/Control.sv) | SystemVerilog | 286 | 76 | 75 | 437 |
| [EXE/ALU.sv](/EXE/ALU.sv) | SystemVerilog | 49 | 13 | 3 | 65 |
| [EXE/BranchSolve.sv](/EXE/BranchSolve.sv) | SystemVerilog | 111 | 18 | 8 | 137 |
| [EXE/Countbit.sv](/EXE/Countbit.sv) | SystemVerilog | 81 | 14 | 13 | 108 |
| [EXE/EXE_Reg.sv](/EXE/EXE_Reg.sv) | SystemVerilog | 118 | 41 | 6 | 165 |
| [EXE/ExceptionInEXE.sv](/EXE/ExceptionInEXE.sv) | SystemVerilog | 41 | 9 | 5 | 55 |
| [EXE/ForwardUnitInEXE.sv](/EXE/ForwardUnitInEXE.sv) | SystemVerilog | 27 | 11 | 4 | 42 |
| [EXE/HILO.sv](/EXE/HILO.sv) | SystemVerilog | 34 | 42 | 5 | 81 |
| [EXE/MULTDIV.sv](/EXE/MULTDIV.sv) | SystemVerilog | 334 | 38 | 35 | 407 |
| [EXE/TOP_EXE.sv](/EXE/TOP_EXE.sv) | SystemVerilog | 220 | 17 | 24 | 261 |
| [EXE/TRAP.sv](/EXE/TRAP.sv) | SystemVerilog | 38 | 9 | 1 | 48 |
| [ID/DataHazard.sv](/ID/DataHazard.sv) | SystemVerilog | 56 | 14 | 4 | 74 |
| [ID/Decode.sv](/ID/Decode.sv) | SystemVerilog | 1,581 | 47 | 145 | 1,773 |
| [ID/EXT.sv](/ID/EXT.sv) | SystemVerilog | 27 | 9 | 0 | 36 |
| [ID/ForwardUnitInID.sv](/ID/ForwardUnitInID.sv) | SystemVerilog | 43 | 14 | 4 | 61 |
| [ID/ID_Reg.sv](/ID/ID_Reg.sv) | SystemVerilog | 39 | 12 | 5 | 56 |
| [ID/RF.sv](/ID/RF.sv) | SystemVerilog | 38 | 7 | 17 | 62 |
| [ID/TOP_ID.sv](/ID/TOP_ID.sv) | SystemVerilog | 152 | 19 | 17 | 188 |
| [IF/IF_Reg.sv](/IF/IF_Reg.sv) | SystemVerilog | 23 | 10 | 5 | 38 |
| [IF/TOP_IF.sv](/IF/TOP_IF.sv) | SystemVerilog | 24 | 11 | 5 | 40 |
| [MEM1/CP0.sv](/MEM1/CP0.sv) | SystemVerilog | 418 | 50 | 13 | 481 |
| [MEM1/DCache.sv](/MEM1/DCache.sv) | SystemVerilog | 471 | 31 | 93 | 595 |
| [MEM1/DCacheWen.sv](/MEM1/DCacheWen.sv) | SystemVerilog | 114 | 11 | 4 | 129 |
| [MEM1/DTLB.sv](/MEM1/DTLB.sv) | SystemVerilog | 236 | 16 | 11 | 263 |
| [MEM1/Exception.sv](/MEM1/Exception.sv) | SystemVerilog | 97 | 13 | 13 | 123 |
| [MEM1/MEM_Reg.sv](/MEM1/MEM_Reg.sv) | SystemVerilog | 93 | 42 | 18 | 153 |
| [MEM1/TOP_MEM.sv](/MEM1/TOP_MEM.sv) | SystemVerilog | 224 | 31 | 14 | 269 |
| [MEM2/MEM2_Reg.sv](/MEM2/MEM2_Reg.sv) | SystemVerilog | 63 | 20 | 5 | 88 |
| [MEM2/TOP_MEM2.sv](/MEM2/TOP_MEM2.sv) | SystemVerilog | 69 | 24 | 9 | 102 |
| [MUX.sv](/MUX.sv) | SystemVerilog | 77 | 13 | 7 | 97 |
| [PRE_IF/ICache.sv](/PRE_IF/ICache.sv) | SystemVerilog | 288 | 28 | 77 | 393 |
| [PRE_IF/ITLB.sv](/PRE_IF/ITLB.sv) | SystemVerilog | 162 | 34 | 11 | 207 |
| [PRE_IF/PC.sv](/PRE_IF/PC.sv) | SystemVerilog | 16 | 10 | 4 | 30 |
| [PRE_IF/PCSEL.sv](/PRE_IF/PCSEL.sv) | SystemVerilog | 44 | 10 | 7 | 61 |
| [PRE_IF/TOP_PREIF.sv](/PRE_IF/TOP_PREIF.sv) | SystemVerilog | 117 | 16 | 14 | 147 |
| [Utils/PLRU.sv](/Utils/PLRU.sv) | SystemVerilog | 63 | 10 | 11 | 84 |
| [Utils/Rams.sv](/Utils/Rams.sv) | SystemVerilog | 110 | 56 | 29 | 195 |
| [WB/TOP_WB.sv](/WB/TOP_WB.sv) | SystemVerilog | 43 | 30 | 8 | 81 |
| [WB/WB_Reg.sv](/WB/WB_Reg.sv) | SystemVerilog | 48 | 23 | 5 | 76 |
| [mycpu_top.sv](/mycpu_top.sv) | SystemVerilog | 430 | 53 | 27 | 510 |
| [tlb.sv](/tlb.sv) | SystemVerilog | 228 | 23 | 6 | 257 |

[summary](results.md)