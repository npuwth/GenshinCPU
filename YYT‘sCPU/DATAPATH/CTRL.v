`include "Ctrl_encoding_def.v"
module CTRL (
    input [5:0] OP,
    input [4:0] Bopcode,
    input [5:0] Funct,
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] rd,
    input [31:2] PC,          // PC信号：用于PcSel信号的选择
    input BResult,            // BTypeOperate 模块的结果

    output  ID_PcSel,    // PC寄存器输入选择信号
    output [2:0] ID_BTypeOp,  // B型指令 比较信号选择
    output [2:0] ID_ExtOp,    // 符号扩展选择信号
    output [3:0] ID_AluOp,    // ALU操作码选择
    output  ID_AluSrcA,
    output  ID_AluSrcB,
    output [1:0] ID_NpcOp,
    output [1:0] ID_WbSel,    // 写回数据选择信号
    output [1:0] ID_SaveType, // SAVE指令类型
    output [1:0] ID_RwSel,    // 写回地址选择信号
    output ID_RfWr,           // 寄存器堆写信号
    output ID_DmWr,           // 数据存储器写信号
    output ID_ReadMen,        // LW信号
    output [2:0] ID_LTypeExtOp,  // WB级LType操作码
    output ID_LTypeSel,       //  WB级LType选择信号
    output [1:0] ID_VariShiftSel    //  移位量选择
); 
    reg  ID_PcSel_r;     // PC寄存器输入选择信号
    reg [2:0] ID_BTypeOp_r;   // B型指令 比较信号选择
    reg [2:0] ID_ExtOp_r;     // 符号扩展选择信号
    reg [3:0] ID_AluOp_r;     // ALU操作码选择
    reg  ID_AluSrcA_r;        // ALU A 选择信号（0:rs 1:Sa移位）
    reg  ID_AluSrcB_r;        // ALU B 选择信号（0:rt 1:Imm立即数）
    reg [1:0] ID_NpcOp_r; 
    reg [1:0] ID_WbSel_r;     // 写回数据选择信号
    reg [1:0] ID_SaveType_r;  // SAVE指令类型
    reg [1:0] ID_RwSel_r;     // 写回地址选择信号
    reg ID_RfWr_r;            // 寄存器堆写信号
    reg ID_DmWr_r;            // 数据存储器写信号
    reg ID_ReadMen_r;         // LW信号
    reg [2:0] ID_LTypeExtOp_r;
    reg ID_LTypeSel_r;
    reg [1:0] ID_VariShiftSel_r;
    // 在 IF 级需要使用的信号
    // ID_PcSel_r
    // 默认选择1(PC+4)
    always @(PC,BResult,Funct,OP) begin
        if (OP == `OP_BEQ_type && BResult == 1'b1) ID_PcSel_r=1'b0;
        else if (OP == `OP_BGTZ_type && BResult == 1'b1) ID_PcSel_r=1'b0;
        else if (OP == `OP_BLEZ_type && BResult == 1'b1) ID_PcSel_r=1'b0;
        else if (OP == `OP_BNE_type && BResult == 1'b1) ID_PcSel_r=1'b0;
        else if ((OP== `OP_BGEZ_BLTZ && Bopcode == `ACRON_BGEZ) &&( BResult == 1'b1 )) ID_PcSel_r=1'b0;
        else if ((OP== `OP_BGEZ_BLTZ && Bopcode == `ACRON_BLTZ) &&( BResult == 1'b1 )) ID_PcSel_r=1'b0;
        else if (OP == `OP_JAL_type) ID_PcSel_r=1'b0;
        else if (OP == `OP_R_type && (Funct == `FUNCT_JALR || Funct ==`FUNCT_JR )) ID_PcSel_r=1'b0;
        else if (OP == `OP_J_type) ID_PcSel_r=1'b0;
        else ID_PcSel_r = 1'b1;
    end

    

    // 在 ID 级需要使用的信号
    // ID_BTypeOp  & ID_ExtOp & ID_RfWr & ID_NpcOp
    // ID_BTypeOp_r
    always @(OP,Bopcode) begin
        case (OP)
           `OP_BEQ_type  : ID_BTypeOp_r = `B_TYPE_BEQ;
           `OP_BGTZ_type : ID_BTypeOp_r = `B_TYPE_BGTZ;
           `OP_BLEZ_type : ID_BTypeOp_r = `B_TYPE_BLEZ;
           `OP_BNE_type  : ID_BTypeOp_r = `B_TYPE_BNE;
           `OP_BGEZ_BLTZ :begin
               if (Bopcode == `ACRON_BGEZ) ID_BTypeOp_r = `B_TYPE_BGEZ;
               else if (Bopcode == `ACRON_BLTZ) ID_BTypeOp_r = `B_TYPE_BLTZ;
           end
            default: ID_BTypeOp_r = 3'bxxx;
        endcase
    end    

    // ID_ExtOp_r
    always @(OP) begin
        case (OP)           
           `OP_LW_type    : ID_ExtOp_r = `EXT_IMME_SIGN;   // Lw    -> Signed16
           `OP_LB_type    : ID_ExtOp_r = `EXT_IMME_SIGN;     // Lb    -> Signed16
           `OP_LBU_type   : ID_ExtOp_r = `EXT_IMME_SIGN;     // Lbu   -> Signed16
           `OP_LH_type    : ID_ExtOp_r = `EXT_IMME_SIGN;     // Lbu   -> Signed16
           `OP_LHU_type   : ID_ExtOp_r = `EXT_IMME_SIGN;     // Lbu   -> Signed16
           `OP_SW_type    : ID_ExtOp_r = `EXT_IMME_SIGN;   // Sw    -> Signed16
           `OP_SB_type    : ID_ExtOp_r = `EXT_IMME_SIGN;   // Sw    -> Signed16
           `OP_SH_type    : ID_ExtOp_r = `EXT_IMME_SIGN;   // Sw    -> Signed16
           `OP_ADDI_type  : ID_ExtOp_r = `EXT_IMME_SIGN;   // ADDI  -> Signed16
           `OP_ADDIU_type : ID_ExtOp_r = `EXT_IMME_SIGN;   // ADDIU -> Signed16
           `OP_SLTI_type  : ID_ExtOp_r = `EXT_IMME_SIGN;   // ADDIU -> Signed16
           `OP_SLTIU_type : ID_ExtOp_r = `EXT_IMME_SIGN;   // ADDIU -> Signed16

           `OP_ANDI_type  : ID_ExtOp_r = `EXT_IMME_ZERO;   // ANDI  -> Unsigned16
           `OP_ORI_type   : ID_ExtOp_r = `EXT_IMME_ZERO;   // ORI   -> Unsigned16
           `OP_XORI_type  : ID_ExtOp_r = `EXT_IMME_ZERO;   // ORI   -> Unsigned16
  
           `OP_LUI_type   : ID_ExtOp_r = `EXT_IMME_ZERO;      //  Lui   -> Set high
            default: ID_ExtOp_r=3'bxx;
        endcase 
    end

    // ID_RfWr_r
    // 1 有效 
    always @(OP,Funct) begin
        case (OP)
            `OP_R_type    : begin
                if (Funct == `FUNCT_JR) ID_RfWr_r = 1'b0;
                else  ID_RfWr_r = 1'b1;
            end 
            `OP_ORI_type  : ID_RfWr_r = 1'b1;
            `OP_ANDI_type : ID_RfWr_r = 1'b1;
            `OP_XORI_type : ID_RfWr_r = 1'b1;
            `OP_ADDI_type : ID_RfWr_r = 1'b1;
            `OP_ADDIU_type: ID_RfWr_r = 1'b1;
            /*********   IType  **********/
            `OP_LW_type   : ID_RfWr_r = 1'b1;
            `OP_LB_type   : ID_RfWr_r = 1'b1;
            `OP_LBU_type  : ID_RfWr_r = 1'b1;
            `OP_LH_type   : ID_RfWr_r = 1'b1;
            `OP_LHU_type  : ID_RfWr_r = 1'b1;
            `OP_LUI_type  : ID_RfWr_r = 1'b1;
            `OP_SLTI_type : ID_RfWr_r = 1'b1;
            `OP_SLTIU_type : ID_RfWr_r = 1'b1;

            `OP_JAL_type  : ID_RfWr_r = 1'b1;
            default : ID_RfWr_r = 1'b0;
        endcase
    end
    // ID_NpcOp_r
    always @(OP,Funct,BResult,Bopcode) begin
        if ((OP== `OP_BGEZ_BLTZ && Bopcode == `ACRON_BGEZ) &&( BResult == 1'b1 )) ID_NpcOp_r=`NPC_BRANCH;  // BGEZ 
        else if ((OP== `OP_BGEZ_BLTZ && Bopcode == `ACRON_BLTZ) &&( BResult == 1'b1 )) ID_NpcOp_r=`NPC_BRANCH;  // BLTZ
        else if ((OP == `OP_BEQ_type) && BResult == 1'b1)  ID_NpcOp_r=`NPC_BRANCH;   // BEQ
        else if ((OP == `OP_BGTZ_type) && (BResult == 1'b1)) ID_NpcOp_r=`NPC_BRANCH;   // BGTZ
        else if ((OP == `OP_BLEZ_type) && (BResult == 1'b1 )) ID_NpcOp_r=`NPC_BRANCH;   // BLEZ
        else if ((OP  ==`OP_BNE_type) && (BResult == 1'b1)) ID_NpcOp_r=`NPC_BRANCH;   // BNE
        else if (OP == `OP_J_type ) ID_NpcOp_r =`NPC_JUMP;
        else if (OP == `OP_JAL_type ) ID_NpcOp_r =`NPC_JUMP;
        else if (OP == `OP_R_type && (Funct == `FUNCT_JALR || Funct == `FUNCT_JR) ) ID_NpcOp_r =`NPC_RF;
        else ID_NpcOp_r =`NPC_NORMAL;
    end

// 在EXE级会用到的信号
    // ID_AluOp & ID_RwSel & ID_AluSrcA  & ID_AluSrcB & ID_VariShiftSel
    // ID_AluOp_r
    always @(OP,Funct) begin
        case (OP)
                /**********  R type **********/
           `OP_R_type : begin
               case (Funct)
                `FUNCT_ADD  : ID_AluOp_r = `ALUop_ADD;
                `FUNCT_ADDU : ID_AluOp_r = `ALUop_ADD;
                `FUNCT_SUBU : ID_AluOp_r = `ALUop_SUB;
                `FUNCT_AND  : ID_AluOp_r = `ALUop_AND;
                `FUNCT_SUB  : ID_AluOp_r = `ALUop_SUB;
                `FUNCT_OR   : ID_AluOp_r = `ALUop_ORI;
                `FUNCT_NOR  : ID_AluOp_r = `ALUop_NOR;
                `FUNCT_XOR  : ID_AluOp_r = `ALUop_XOR;
                `FUNCT_SLL  : ID_AluOp_r = `ALUop_SLL; 
                `FUNCT_SLLV : ID_AluOp_r = `ALUop_SLL; 
                `FUNCT_SRL  : ID_AluOp_r = `ALUop_SRL; 
                `FUNCT_SRLV : ID_AluOp_r = `ALUop_SRL; 
                `FUNCT_SRA  : ID_AluOp_r = `ALUop_SRA; 
                `FUNCT_SRAV : ID_AluOp_r = `ALUop_SRA; 
                `FUNCT_SLT  : ID_AluOp_r = `ALUop_SLT;
                `FUNCT_SLTU : ID_AluOp_r = `ALUop_SLTU;

                default: ;
                endcase 
           end

                /**********  I type **********/
            `OP_ORI_type   : ID_AluOp_r=`ALUop_ORI;
            `OP_XORI_type  : ID_AluOp_r=`ALUop_XOR;
            `OP_ANDI_type  : ID_AluOp_r=`ALUop_AND;

            `OP_LW_type    : ID_AluOp_r=`ALUop_ADD;
            `OP_LB_type    : ID_AluOp_r=`ALUop_ADD;
            `OP_LBU_type   : ID_AluOp_r=`ALUop_ADD;
            `OP_LH_type    : ID_AluOp_r=`ALUop_ADD;
            `OP_LHU_type   : ID_AluOp_r=`ALUop_ADD;

            `OP_LUI_type   : ID_AluOp_r=`ALUop_SLL;

            `OP_SW_type    : ID_AluOp_r=`ALUop_ADD;
            `OP_SB_type    : ID_AluOp_r=`ALUop_ADD;
            `OP_SH_type    : ID_AluOp_r=`ALUop_ADD;

            `OP_ADDI_type  : ID_AluOp_r=`ALUop_ADD;
            `OP_ADDIU_type : ID_AluOp_r=`ALUop_ADD;
            `OP_SLTI_type  : ID_AluOp_r = `ALUop_SLT;
            `OP_SLTIU_type : ID_AluOp_r = `ALUop_SLTU;
            

            //     /**********  B type **********/
            // `OP_BEQ_type : ID_AluOp_r=`ALUop_SUB;
            // // `OP_B_type   : ID_AluOp_r=`ALUop_SUB;
            // // `OP_BGTZ_type: ID_AluOp_r=`ALUop_SUB;
            // // `OP_BLEZ_type: ID_AluOp_r=`ALUop_SUB;
            // // `OP_BNE_type : ID_AluOp_r=`ALUop_SUB;
            default: ID_AluOp_r=3'bxxx;
        endcase
    end

    // ID_RwSel_r
    // R_Type   -> 01 : select rd
    // I_Type   -> 00 : select rt
    // JAL_Type -> 10 : select 5'd31
    always @(OP,Funct) begin
        case (OP)
            `OP_R_type   : begin
                if (Funct == `FUNCT_JALR ) ID_RwSel_r = 2'b01;
                else ID_RwSel_r = 2'b01;
            end 
            `OP_ORI_type  : ID_RwSel_r = 2'b00;
            `OP_ANDI_type : ID_RwSel_r = 2'b00;
            `OP_XORI_type : ID_RwSel_r = 2'b00;
            
            `OP_LW_type   : ID_RwSel_r = 2'b00;
            `OP_LB_type   : ID_RwSel_r = 2'b00;
            `OP_LBU_type  : ID_RwSel_r = 2'b00;
            `OP_LH_type   : ID_RwSel_r = 2'b00;
            `OP_LHU_type  : ID_RwSel_r = 2'b00;
            `OP_LUI_type  : ID_RwSel_r = 2'b00;

            `OP_ADDI_type : ID_RwSel_r = 2'b00;
            `OP_ADDIU_type: ID_RwSel_r = 2'b00;
            
            `OP_SLTI_type : ID_RwSel_r = 2'b00;
            `OP_SLTIU_type: ID_RwSel_r = 2'b00;

            `OP_JAL_type  : ID_RwSel_r = 2'b10;
            default: ID_RwSel_r = 2'bxx;
        endcase
    end

    // ID_AluSrcA
    // （0:rs 1:Sa移位）
    always @(OP,Funct) begin
        case (OP)
           `OP_R_type : begin
               case (Funct)
                  // // `FUNCT_SLL  : ID_AluSrcA_r = 1'b1;  // 还有2种情况未写上
                  `FUNCT_JALR : ID_AluSrcA_r = 1'bx;
                  `FUNCT_JR   : ID_AluSrcA_r = 1'bx;
                   default: ID_AluSrcA_r = 1'b0;
               endcase
           end 
            default: ID_AluSrcA_r = 1'b0;
        endcase
    end
    // ID_AluSrcB
    // （0:rt 1:Imm立即数）
    always @(OP,Funct) begin
        case (OP)
           `OP_R_type : begin
               case (Funct)
                  `FUNCT_JALR :  ID_AluSrcB_r = 1'bx;
                  `FUNCT_JR   :  ID_AluSrcB_r = 1'bx;
                   default: ID_AluSrcB_r = 0;
               endcase
           end 
           `OP_LUI_type  : ID_AluSrcB_r = 1'b1;
            default: ID_AluSrcB_r = 1;
        endcase
    end
    // ID_VariShiftSel
    // 00 -> s (fixed shift)
    // 01 -> variable shift 
    // 11 -> 5'D16 
    always @(OP,Funct) begin
        if(OP == `OP_R_type )begin
            if ( Funct == `FUNCT_SLLV || Funct == `FUNCT_SRAV || Funct == `FUNCT_SRLV) ID_VariShiftSel_r =2'b01;
            else if ( Funct == `FUNCT_SLL || Funct == `FUNCT_SRA || Funct == `FUNCT_SRL) ID_VariShiftSel_r =2'b00;
            else ID_VariShiftSel_r =1'bx;
        end
        else if (OP == `OP_LUI_type)ID_VariShiftSel_r =2'b11;
    end
    // ID_ReadMen_r,        // LW信号
    always @(OP) begin
        case (OP)
            `OP_LW_type  : ID_ReadMen_r = 1'b1;
            `OP_LB_type  : ID_ReadMen_r = 1'b1;
            `OP_LBU_type : ID_ReadMen_r = 1'b1;
            `OP_LH_type  : ID_ReadMen_r = 1'b1;
            `OP_LHU_type : ID_ReadMen_r = 1'b1;
            default: ID_ReadMen_r = 1'b0;
        endcase
    end 

// MEM级会用到的信号
    // ID_DmWr_r & ID_SaveType_r
    // ID_DmWr_r 
    always @(OP) begin
        case (OP)
            `OP_SW_type :  ID_DmWr_r=1;
            `OP_SH_type :  ID_DmWr_r=1;
            `OP_SB_type :  ID_DmWr_r=1;
            default: ID_DmWr_r=0;
        endcase
    end
    // ID_SaveType_r 
    always @(OP) begin  
    case (OP)
        `OP_SB_type : ID_SaveType_r=`MODE_SB;
        `OP_SH_type : ID_SaveType_r=`MODE_SH;
        `OP_SW_type : ID_SaveType_r=`MODE_SW;
        default: ID_SaveType_r=2'bxx; 
    endcase
    end

    // WB级会用到的信号
    // ID_WbSel_r & ID_LTypeExtOp_r
    // 01: sel ALU result
    // 00: sel DM result 
    // 10: sel PC result
    always @(OP,Funct) begin
        if (OP == `OP_R_type && Funct == `FUNCT_JALR )  ID_WbSel_r=2'b10;  // select PC result
        else begin
            case (OP)
                `OP_R_type     : ID_WbSel_r = 2'b01;
                `OP_ADDI_type  : ID_WbSel_r=2'b01;
                `OP_ADDIU_type : ID_WbSel_r=2'b01;
                `OP_ANDI_type  : ID_WbSel_r=2'b01;
                `OP_XORI_type  : ID_WbSel_r=2'b01;
                `OP_ORI_type   : ID_WbSel_r=2'b01;

                `OP_LW_type    : ID_WbSel_r=2'b00;
                `OP_LB_type    : ID_WbSel_r=2'b00;
                `OP_LBU_type   : ID_WbSel_r=2'b00;
                `OP_LHU_type   : ID_WbSel_r=2'b00;
                `OP_LUI_type   : ID_WbSel_r=2'b00;
                `OP_SLTI_type  : ID_WbSel_r=2'b01;
                `OP_SLTIU_type : ID_WbSel_r=2'b01;

                `OP_LH_type    : ID_WbSel_r=2'b00;
                `OP_JAL_type   : ID_WbSel_r = 2'b10;
                default: ID_WbSel_r=2'bxx;
            endcase
        end 
    end

    // ID_LTypeExtOp_r
    always @( OP) begin
        case (OP)
           `OP_LW_type  : ID_LTypeExtOp_r = `EXT_32;
           `OP_LB_type  : ID_LTypeExtOp_r = `EXT_8_SIGNED;
           `OP_LBU_type : ID_LTypeExtOp_r = `EXT_8_ZERO;
           `OP_LH_type  : ID_LTypeExtOp_r = `EXT_16_SIGNED;
           `OP_LHU_type : ID_LTypeExtOp_r = `EXT_16_ZERO;
           `OP_LUI_type : ID_LTypeExtOp_r = `EXT_32;
            default: ID_LTypeExtOp_r = `EXT_32;
        endcase
    end
    // ID_LTypeSel_r
    // 0-> Lui type
    // 1-> Dmresult
    always @(OP) begin
        if (OP == `OP_LUI_type)  ID_LTypeSel_r=0;
        else ID_LTypeSel_r=1;
        
    end


assign ID_PcSel   = ID_PcSel_r;
assign ID_BTypeOp = ID_BTypeOp_r;
assign ID_ExtOp   = ID_ExtOp_r;
assign ID_AluOp   = ID_AluOp_r;
assign ID_NpcOp   = ID_NpcOp_r;
assign ID_WbSel   = ID_WbSel_r;
assign ID_RwSel   = ID_RwSel_r;
assign ID_AluSrcA = ID_AluSrcA_r;
assign ID_AluSrcB = ID_AluSrcB_r;
assign ID_SaveType = ID_SaveType_r;
assign ID_RfWr = ID_RfWr_r;
assign ID_DmWr = ID_DmWr_r;
assign ID_LTypeExtOp = ID_LTypeExtOp_r;
assign ID_LTypeSel = ID_LTypeSel_r;
assign ID_VariShiftSel=ID_VariShiftSel_r;
assign ID_ReadMen = ID_ReadMen_r;

endmodule

