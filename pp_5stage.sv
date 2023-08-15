module pp_5stage (
  									input logic clk,
  									input logic reset,
  									input logic [32-1:0] inst_Id,
  									input logic [32-1:0] inst_Ex,
  									input logic [32-1:0] inst_Ma,
  									input logic [32-1:0] inst_Wb,
  input logic [32-1:0] inst_csr,

  									input logic BrEq,
  									input logic BrLT,
  output logic [3-1:0] reg_mux_sel,
  output logic [2-1:0] branch_muxA_sel,
  output logic [2-1:0] branch_muxB_sel,
  									output logic [3-1:0] alu_op,
  									output logic pc_sel,
  									output logic [3-1:0] imm_sel,
  									output logic reg_write_en,
  									output logic BrUn,
  output logic [2-1:0] busA_sel_mux,
  output logic [2-1:0] busB_sel_mux,
  output logic [3-1:0]alu_sel,
  									output logic mem_rw,
  output logic [2-1:0] wb_sel,
  output logic wb_selMW,
  output logic is_mret,
  input logic epc_taken
											);
  
  
 
 //0000000 01001 01001 000 01100 1100011 //00948663
 //BEQ x9, x9, 12
  //opcodes
  //0110011  R-type
  //0010011  Immediate type (I type)
  //0000011  Load type (sub type of I)
  //0100011  Story type
  //1100011  Branch type
  //1100111 JALR
  //1101111 JAL
  //0110111 LUI
  //0010111 AUIPC
  //1110011 CSR
  
  
  //parameters for immediate generation
  parameter I = 1;
  parameter S = 2;
  parameter B = 3;
  parameter J = 4;
  parameter U = 5;
  parameter unsigned_ext = 6;//CSR, unsigned extension

  assign alu_op = inst_Ex[14:12];//alu_op
  
  always @ (*) begin
    if(reset) begin
      reg_write_en = 0;
      mem_rw = 0;
      is_mret = 0;
    end
  end
  //In case of Branch need bypass data
  always @ (*) begin
    //if inst_Ma != (U | J) && inst_Ex = B && inst_Ex -->RS1 == int_Ma--> Rd do forwarding between Ma and Ex
    if(!(inst_Ma[6:0]== 7'b0110111/*LUI*/ | inst_Ma[6:0]== 7'b0010111/*AUIPC*/ | inst_Ma[6:0]== 7'b1101111/*JAL*/ |   inst_Ma[6:0]== 7'b1100111/*JALR*/) && (inst_Ex[6:0] == 7'b1100011 /*Branch*/) && (inst_Ex[19:15]/*RS1*/ == inst_Ma[11:7] /*RD*/))
      branch_muxA_sel = 2;
    //else if inst_WB != (U & J) && inst_Ex = B && inst_ex --> RS1 == inst_Ma --> Rd do forwarding between Wb and Ex
    else if(!(inst_Wb[6:0]== 7'b0110111/*LUI*/ | inst_Wb[6:0]== 7'b0010111/*AUIPC*/ | inst_Wb[6:0]== 7'b1101111/*JAL*/ |   inst_Wb[6:0]== 7'b1100111/*JALR*/) && (inst_Ex[6:0] == 7'b1100011 /*Branch*/) && (inst_Ex[19:15]/*RS1*/ == inst_Wb[11:7] /*RD*/))
      branch_muxA_sel = 3;
    //else don't do forwarding
    else
      branch_muxA_sel = 0;
  end
  always @ (*) begin
    //if inst_Ma != (U & J) && inst_Ex = B && inst_Ex -->RS2 == int_Ma--> Rd do forwarding between Ma and Ex
    if(!(inst_Ma[6:0]== 7'b0110111/*LUI*/ | inst_Ma[6:0]== 7'b0010111/*AUIPC*/ | inst_Ma[6:0]== 7'b1101111/*JAL*/ |   inst_Ma[6:0]== 7'b1100111/*JALR*/) && (inst_Ex[6:0] == 7'b1100011 /*Branch*/) && (inst_Ex[24:20]/*RS2*/ == inst_Ma[11:7] /*RD*/))
      branch_muxB_sel = 2;
    //else if inst_WB != (U & J) && inst_Ex = B && inst_ex --> RS2 == inst_Ma --> Rd do forwarding between Wb and Ex
    else if(!(inst_Wb[6:0]== 7'b0110111/*LUI*/ | inst_Wb[6:0]== 7'b0010111/*AUIPC*/ | inst_Wb[6:0]== 7'b1101111/*JAL*/ |   inst_Wb[6:0]== 7'b1100111/*JALR*/) && (inst_Ex[6:0] == 7'b1100011 /*Branch*/) && (inst_Ex[24:20]/*RS2*/ == inst_Wb[11:7] /*RD*/))
      branch_muxB_sel = 3;
    //else don't do forwarding
    else
      branch_muxB_sel = 0;
  end
  
  
  
  
  
  
  
  
  
  //reg_mux_sel
  always @(*) begin
    //stall when ((inst_Ma == (Load)) && ( ( (inst_EX == (R, S)) && (inst_Ma-->Rd == instr_Ex --> RS1 | inst_Ma-->Rd == instr_Ex -->RS2)) | ((inst_EX == (I & Load, CSR)) && (inst_Ma --> Rd == inst_Ex -->RS1))))
    if ((inst_Ma[6:0] == 7'b0000011 /*Load*/  )&&(((inst_Ex[6:0] ==7'b0110011 /*R type*/ | inst_Ex[6:0] ==7'b0100011 /*S type*/  )&&(inst_Ma[11:7]/*Rd*/ == inst_Ex[19:15]/*RS1*/ | inst_Ma[11:7]/*Rd*/ ==inst_Ex[24:20]/*RS2*/ )) | (( inst_Ex[6:0] ==7'b0010011 /*I type*/ | inst_Ex[6:0] ==7'b0000011 /*Load type*/ | inst_Ex[6:0] ==7'b1110011 /*CSR type*/ )&&(inst_Ma[11:7]/*Rd*/ == inst_Ex[19:15]/*RS1*/ ))))
      reg_mux_sel = 3'b100;
    
    //bubble flushing
    else if (pc_sel == 1 | epc_taken== 1'b1  ) 
      reg_mux_sel = 3'b010;
    //normal
    else if(pc_sel == 0 )
      reg_mux_sel = 3'b001;
    
  end
  
   //pc sel
  always @ (posedge clk) begin
    if (reset)
      pc_sel = 0;
  end
  //pc control
  always @ (*) begin
    if ( ((inst_Ex [6:0] == 7'b1100111 )/*JALR*/ |  (inst_Ex [6:0] == 7'b1101111 ))/*JAL*/ | ((inst_Ex [6:0] == 7'b1100011/*B type*/ )&&(inst_Ex [14:12] == 3'b000 && BrEq) | (inst_Ex [14:12] == 3'b001 && !BrEq) | (inst_Ex [14:12] == 3'b100 && BrLT) | (inst_Ex [14:12] == 3'b101 && !BrLT)  | (inst_Ex [14:12] == 3'b110 && BrLT) | (inst_Ex [14:12] == 3'b111 && !BrLT)) ) //B , JALR , JAL
      	pc_sel = 1;//taken
    else // R, I, L, S, LUI, AUIPC
      pc_sel = 0;//Not Taken
   
  end
  
  //immediate selection
  always @(*) begin
    if(inst_Ex[6:0] ==7'b0010011 | inst_Ex[6:0]==7'b0000011 | inst_Ex [6:0] == 7'b1100111 /*JALR*/) //I, L,JALR, CSR
      imm_sel = I;
    else if (inst_Ex[6:0] == 7'b0100011) //S
      imm_sel = S;
    else if (inst_Ex [6:0] == 7'b1100011) //B
      imm_sel = B;
    else if (inst_Ex [6:0] == 7'b1101111 ) //JAL
      imm_sel = J;
    else if ( inst_Ex[6:0] == 7'b0110111 |  inst_Ex[6:0] == 7'b0010111 ) // LUI, AUIPC
      imm_sel = U;
    else if( inst_Ex[6:0] == 7'b1110011 /*CSR*/)
      imm_sel = unsigned_ext;
    else //R
      imm_sel = 0;
    
  end

  //register write enable
  always @ (*) begin
    if( inst_Wb[6:0] == 7'b0110011 |  inst_Wb[6:0] == 7'b0010011 | inst_Wb[6:0] == 7'b0000011 | inst_Wb[6:0] == 7'b1100111 | inst_Wb[6:0] == 7'b1101111 | inst_Wb[6:0] == 7'b0110111 | inst_Wb[6:0] == 7'b0010111 | (inst_Wb[6:0]== 7'b1110011 && (inst_Wb[14:12] == 3'b001 /*CSRRW*/ |  inst_Wb[14:12] == 3'b101/*CSRRWI*/))) //R, I, Load, JALR, JAL, LUI, AUIPC
      reg_write_en = 1;
    else if (inst_Wb [6:0] == 7'b0100011 | inst_Wb [6:0] == 7'b1100011 )// S type and B type
      reg_write_en = 0;
    
  end
  
  //BrUN
  always @ (*) begin
    if(inst_Ex [6:0] == 7'b1100011 /*B*/ && (inst_Ex[14:12]==3'b110 /*BrLTU*/ | inst_Ex[14:12]==3'b111/*BGEU*/ ))
       BrUn = 1;
     else 
       BrUn = 0;
  end
  
  //mux A selection
  always @ (*) begin
    
    //do forwading from MA when inst_Ex != (JAL, Branch, Load, U ) && inst_Ma != ( CSR, Load, S and B, NOP type)
    if ((!( inst_Ex[6:0]==7'b1101111 /*JAL type*/ | inst_Ex[6:0]==7'b1100011 /*B type*/ | inst_Ex[6:0]==7'b0000011 /*Load type*/ | inst_Ex[6:0]==7'b0110111 /*LUI*/| inst_Ex[6:0]==7'b0010111/*AUIPC*/  )&& !( inst_Ma[6:0]==7'b1110011 /*CSR*/ | inst_Ma[6:0]==7'b0000011 /*Load type*/ | inst_Ma[6:0]==7'b0100011 /*S type*/ | inst_Ma[6:0]==7'b1100011 /*B type*/ | inst_Ma[6:0]==7'b0000000 /*NOP type*/)) && (inst_Ex[19:15] == inst_Ma[11:7] /*forwarding between Ma and Ex*/ )) 
	  busA_sel_mux = 2;
    //do forwading from WB when inst_Ex != (JAL, Branch, U ) && inst_Wb != (CSR, S and B & NOP type)
    //catch wheb instruction at WB is load then we can forward if needed
    else if ((!( inst_Ex[6:0]==7'b1101111 /*JAL type*/ | inst_Ex[6:0]==7'b1100011 /*B type*/ | inst_Ex[6:0]==7'b0110111 /*LUI*/| inst_Ex[6:0]==7'b0010111/*AUIPC*/   )&&!(inst_Wb[6:0]==7'b1110011 /*CSR*/ | inst_Wb[6:0]==7'b0100011 /*S type*/ | inst_Wb[6:0]==7'b1100011 /*B type*/ | inst_Wb[6:0]==7'b0000000 /*NOP type*/)) && (inst_Ex[19:15] == inst_Wb[11:7] /*forwarding between Wb and Ex*/ )) 
      busA_sel_mux = 3;
	else if(inst_Ex [6:0] == 7'b1100011 | inst_Ex[6:0] == 7'b1101111 | inst_Ex[6:0] == 7'b0010111 ) // B type, JAL, AUIPC
      busA_sel_mux = 1;
    else //R, I, Load, S,JALR //Don't care for LUI
      busA_sel_mux = 0;
    
  end
   //mux B selection
  always @ (*) begin
    //forwading for busA_sel_mux      
    //do forwading from MA when inst_Ex != (JAL, JALR, Branch, Load, I, U ) && inst_Ma != (CSR, Load, S and B, NOP type)
    if ((!(inst_Ex[6:0]==7'b1101111 /*JAL type*/ | inst_Ex[6:0]==7'b1100111 /*JALR type*/ | inst_Ex[6:0]==7'b1100011 /*B type*/ | inst_Ex[6:0]==7'b0000011 /*Load type*/ | inst_Ex[6:0]==7'b0010011 /*I type*/  | inst_Ex[6:0]==7'b0110111 /*LUI*/| inst_Ex[6:0]==7'b0010111/*AUIPC*/ )&& !(inst_Ma[6:0]==7'b1110011 /*CSR*/ | inst_Ma[6:0]==7'b0000011 /*Load type*/ | inst_Ma[6:0]==7'b0100011 /*S type*/ | inst_Ma[6:0]==7'b1100011 /*B type*/ | inst_Ma[6:0]==7'b0000000 /*NOP type*/)) && (inst_Ex[24:20] /*RS2*/== inst_Ma[11:7/*Rd*/] /*forwarding between Ma and Ex*/ )) 
      busB_sel_mux = 2;
    
    //do forwading from WB when inst_Ex != (JAL, JALR, Branch, Load , I and U ) && inst_Wb != (CSR, S and B type)
    //catch wheb instruction at WB is load then we can forward if needed
    else if ((!(inst_Ex[6:0]==7'b1101111 /*JAL type*/ | inst_Ex[6:0]==7'b1100111 /*JALR type*/ | inst_Ex[6:0]==7'b1100011 /*B type*/ | inst_Ex[6:0]==7'b0000011 /*Load type*/ | inst_Ex[6:0]==7'b0010011 /*I type*/ | inst_Ex[6:0]==7'b0110111 /*LUI*/| inst_Ex[6:0]==7'b0010111/*AUIPC*/   )&&!(inst_Wb[6:0]==7'b1110011 /*CSR*/ | | inst_Wb[6:0]==7'b0100011 /*S type*/ | inst_Wb[6:0]==7'b1100011 /*B type*/ | inst_Wb[6:0]==7'b0000000 /*NOP type*/)) && (inst_Ex[24:20]/*RS2*/ == inst_Wb[11:7]/*RD*/ /*forwarding between Wb and Ex*/ )) 
      busB_sel_mux = 3;
    
    else if(inst_Ex[6:0] == 7'b0010011 | inst_Ex[6:0] == 7'b0000011 | inst_Ex [6:0] == 7'b0100011 | inst_Ex [6:0] == 7'b1100011 | inst_Ex [6:0] == 7'b1100111 | inst_Ex [6:0] == 7'b1101111 |  inst_Ex[6:0] == 7'b0110111 | inst_Ex[6:0] == 7'b0010111 ) begin //I, L, s, B, JALR, JAL, LUI, AUIPC
      busB_sel_mux = 1;
    end
     else  //R
        busB_sel_mux = 0;
  end
  
  //alu selection
  always @ (*) begin
    if (inst_Ex [6:0] == 7'b0110011 /*R type*/ ) // R type
      if(inst_Ex[30]==1)
      		alu_sel = 1; //subtraction
    	else 
          	alu_sel = 0;
    
    else if( inst_Ex[6:0]==7'b0010011 /*I type*/ )
      if(alu_op == 3'b101 && inst_Ex[30]==1)
        alu_sel = 1;
    else 
      	alu_sel = 0;
    else if( inst_Ex[6:0] == 7'b0110111 )
      alu_sel = B; //B, LUI
  	else
      alu_sel = J;//add//AUIPC
  end
  
  //mem_rw
  always @ (*) begin
    if(inst_Ma[6:0] == 7'b0100011) //S
      mem_rw = 1; //Write
    else //R,I,L,B, JALR, LUI, AUIPC
      mem_rw = 0;//Read
  end
  
  //wb_sel
  always @(*) begin
    if(inst_Ma[6:0]==7'b0000011 ) // L 
      wb_sel = 0;//Dmem
    else if(inst_Ma [6:0] == 7'b1100111 | inst_Ma [6:0] == 7'b1101111 )// JALR , JAL
        wb_sel = 2; //pc+ 4
    else// R, I , S, B, LUI, AUIPC
      	wb_sel = 1; //alu out
  end
  
 //wb_selMW
  always @ (*) begin
    if(inst_Ma == 7'b1110011 /*CSR Instruction*/)
      wb_selMW =1;
    else
      wb_selMW = 0;
  end
  //is_mret
  always @ (*) begin
    if(inst_csr == 32'h30200073)
      is_mret = 1;
    else
      is_mret = 0;
  end

endmodule





