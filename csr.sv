module csr (
  				input logic reset,
  				input logic clk,
  input logic [32-1:0] inst_csr,
  				input logic [32-1:0] pc_Ma,
  input logic [32-1:0] wdata, //rs1_MA from Ex block
  				input logic t_interrupt,
  				input logic e_interrupt,
  				input logic [32-1:0] addr, //immediate from Ex stage
  				input logic reg_wr,
  				input logic reg_rd,
  				input logic is_mret,
  				output logic [32-1:0] rdata,
  output logic [32-1:0] epc,
  				output logic epc_taken
  
			

													);
  
  //30200073 MRET in hexadecimal
  logic [32-1:0] csr_reg [4096-1:0];//csr registers
  logic [3-1:0] op_sel;
  logic [32-1:0] mepc;
  logic [32-1:0] temp_wire;
 
  logic [32-1:0] interrupt_encode;
  logic [32-1:0] mcause_sll2;
  logic [32-1:0] epc_mux1_out;
  logic [2-1:0] epc_mux1_sel;
  logic [32-1:0] epc_mux2_out;
  logic  epc_mux2_sel;
  logic [12-1:0] csr_reg_address;
  
  //defining 6 registers for CSR;
  logic [32-1:0] mcasuse_sll2;
  logic [32-1:0] mip_reg;
  logic [32-1:0] mie_reg;
  logic [32-1:0] mstatus_reg;
  logic [32-1:0] mcause_reg;
  logic [32-1:0] mtvec_reg;
  logic [32-1:0] mepc_reg;
  assign mstatus_reg = csr_reg[12'h300];
  assign mie_reg = csr_reg[12'h304];
  assign mtvec_reg = csr_reg[12'h305];
  assign mepc_reg = csr_reg[12'h341];
  assign mcause_reg = csr_reg[12'h342];
  assign mip_reg = csr_reg[12'h344]; 
  assign op_sel = inst_csr[14:12];
  assign epc_mux1_sel = mtvec_reg[1:0]; /*mtvec[1:0] */
  assign csr_reg_address = inst_csr[31:20];
  
  //important
  assign epc_mux2_sel = is_mret;
  
  //wires for exceptional interrupt
  logic t_interrupt_wire;
  logic e_interrupt_wire;
  logic or_all_interrupt;
  logic exception_wire;
  logic mip_meip_bit;
  logic mip_mtip_bit;
  logic mie_mtie_bit;
  logic mie_meie_bit;
  logic mstatus_mie_bit;
  
  assign mip_mtip_bit = mip_reg[7];
  assign mip_meip_bit = mip_reg[11];
  assign mie_mtie_bit = mie_reg[7];
  assign mie_meie_bit = mie_reg[11];
  assign mstatus_mie_bit = mstatus_reg[3];
  
  and(t_interrupt_wire, mip_mtip_bit,mie_mtie_bit);
  and(e_interrupt_wire, mip_meip_bit,mie_meie_bit);
  or (or_all_interrupt, t_interrupt_wire, e_interrupt_wire);
  and(exception_wire, or_all_interrupt,  mstatus_mie_bit);
  
 
  
  
  
  //on reset
  always @ (posedge clk) begin
    if(reset)
      	epc_taken = 0;
  end
  //epc taken
  always @ (*) begin
    if (exception_wire == 1'b1 )
      epc_taken = 1;
    else if (exception_wire == 0'b0 && is_mret == 0'b0)
      epc_taken = 0;
  end
  always @ (*) begin
    if(is_mret == 1'b1)
      epc_taken = 1'b1;
  end
  
  always @ (posedge clk) begin
     if(reset) begin
       for (int i = 0; i<4096;i++) 
         csr_reg[i] = 0; 
     end//if
  end
  
  always @ (*) begin
    //1.//1. setting mcause 0x342
    csr_reg[12'h342]    = interrupt_encode; 
    //2. setting mip 0x344,  mtip = mip[7] timer interrupt meip = mip[11] external interupt
    csr_reg[12'h344][7]  =  t_interrupt;
    csr_reg[12'h344][11] = e_interrupt;
    
    
  end
  
  //mepc
  always @ (*) begin
    ///3. mepc register 0x341 assign when an interrupt comes
    if(exception_wire == 1'b1) 
      csr_reg[12'h341] = pc_Ma + 4;
  end
  
  
  
  
  //interrupt encoding
  always @ (*) begin
  	// for timer interrupt mcasue = 1
    if(t_interrupt)
      interrupt_encode = 1;
    // for external interrupt mcasue = 2
    else if (e_interrupt)
      interrupt_encode = 2;
  end
  
  //3. CSRRW insturction
  always @ (*) begin
    if (inst_csr[6:0] == 7'b1110011 /*CSR Instruction*/ ) begin
      
      case (op_sel)
        3'b001: begin //CSRRW
          rdata = csr_reg [csr_reg_address]; //csr register value will be send to RD
          csr_reg[csr_reg_address] = wdata;
        end
        3'b010: begin //CSRRS
          csr_reg[csr_reg_address] = csr_reg[csr_reg_address] | wdata;
          
        end
        3'b011: begin //CSRRC
          csr_reg[csr_reg_address] = csr_reg[csr_reg_address] & ~wdata;
        end
        3'b101: begin //CSRRWI
          
        end
        3'b101: begin //CSRRSI
          
        end
        3'b101: begin //CSRRCI
          
        end
                    
      endcase
    end
  end
  //epc calculation
  always @ (*) begin
      	mcause_sll2 = mcause_reg <<2;
    	epc_mux1_out = epc_mux1_sel? mtvec_reg : mcause_sll2 +mtvec_reg; /*mtvec*/
    	epc_mux2_out = epc_mux2_sel ? mepc_reg : epc_mux1_out; 
  end
  
  assign epc = epc_mux2_out;
  //epc_mux2_sel not defined yet
endmodule
