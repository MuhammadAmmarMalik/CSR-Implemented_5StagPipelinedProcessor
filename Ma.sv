module Ma_stage(
                    input logic clk,
                    input logic reset,
  input logic [32-1:0] pc_Ma,
  					input logic [32-1:0] alu_out_Ma,
                    input logic [32-1:0] rs2_Ma,
                    input logic [32-1:0] inst_Ma,
                    input logic mem_rw,
  input logic [2-1:0] wb_sel,
  
  					input logic reg_write_en,//no need
					input logic wb_selMW,
  input logic [32-1:0] rdata,
  					output logic [32-1:0] wb_mux_out,
  					output logic [32-1:0] inst_Wb
  
														);
  logic [3-1:0] alu_op; //important don't get from control unit
  assign alu_op = inst_Ma[14:12];
  logic [32-1:0] wb_mux_out_Ma;
  logic [32-1:0] csr_wb_mux_out_Ma;
  logic [8-1:0] dmem [6000-1:0]; //Data memory for Load and store operation
  logic [32-1:0] dataR;   //Read data for DMEM
  logic [32-1:0] pc_adder_out;
  
  assign csr_wb_mux_out_Ma = wb_selMW? rdata : wb_mux_out_Ma;
  
  assign pc_adder_out = pc_Ma + 4;
  //loading data in data memory
  always @ (posedge clk) begin
    if(reset) begin
      for(int i=0;i<6000;i++)
        dmem[i]=i;
      
    end
  end
  
  
  //WB mux output 
  always @ (*) begin
    
    //if(reg_write_en) //important we can comment it in pipeline
      case(wb_sel)
        2'b00:
          wb_mux_out_Ma <= dataR;
        2'b01:
          wb_mux_out_Ma <= alu_out_Ma;
        2'b10:
          wb_mux_out_Ma <= pc_adder_out;
      
      endcase
  end
  
  //DMEM BLOCK
  always @(*) begin
    case (alu_op)
    	3'b000: begin
          dataR[7:0] = dmem[alu_out_Ma];
      			for(int i=8;i<32;i++)
        			dataR[i]=dataR[7];
        end
    	3'b001: begin
          		dataR[15:0] ={dmem[alu_out_Ma+1], dmem[alu_out_Ma]};
      			for(int i=16;i<32;i++)
                  dataR[i]=dataR[15];
        end
      	3'b010:
        		dataR ={dmem[alu_out_Ma+3],dmem[alu_out_Ma+2],dmem[alu_out_Ma+1], dmem[alu_out_Ma]};
      	3'b100:begin
        		dataR[7:0] = dmem[alu_out_Ma];
      			for(int i=8;i<32;i++)
                	dataR[i]=0;
        end
      	3'b101:begin
        		dataR[15:0] ={dmem[alu_out_Ma+1], dmem[alu_out_Ma]};
      			for(int i=16;i<32;i++)
                	dataR[i]=0;
        end
    endcase//case
  end//always
  
  //write operation of DMEM
  always @ (posedge clk) begin
    if(mem_rw == 1) begin
    	case (alu_op)
      		3'b000:
              dmem[alu_out_Ma] = rs2_Ma[7:0];
	  		3'b001: begin
        			dmem[alu_out_Ma + 1 ] = rs2_Ma[15:8];
        			dmem[alu_out_Ma]      = rs2_Ma[7:0];
      		end
      		3'b010: begin
        			dmem[alu_out_Ma + 3 ] = rs2_Ma[31:24];
        			dmem[alu_out_Ma + 2 ] = rs2_Ma[23:16];
        			dmem[alu_out_Ma + 1 ] = rs2_Ma[15:8];
        			dmem[alu_out_Ma]      = rs2_Ma[7:0];
      		end
        endcase
  	end//if
  end//always  
  //pipeline registers
  //inst_Wb 
  always @(posedge clk) begin
    inst_Wb = inst_Ma;    
  end
  always @ (posedge clk) begin
  	wb_mux_out =csr_wb_mux_out_Ma;    
  end
  
  
endmodule
