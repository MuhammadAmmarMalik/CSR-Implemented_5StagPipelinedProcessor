module single_cycle_processor (
								input logic reset,
								input logic clk,
  								input logic t_interrupt,
  								input logic e_interrupt
													);
  wire pc_sel_wire;
  wire [32-1:0] alu_out_Ex_wire;
  wire [32-1:0] alu_out_Ma_wire;
  wire [32-1:0] pc_ID_wire;
  wire [32-1:0] pc_Ex_wire;
  wire [32-1:0] pc_Ma_wire;
  wire [32-1:0] inst_ID_wire;
  wire [32-1:0] inst_Ex_wire;
  wire [32-1:0] inst_Ma_wire;
  wire [32-1:0] inst_Wb_wire;
  wire [32-1:0] inst_at_Wb_wire;
  wire reg_write_en_wire;
  wire [32-1:0] wb_mux_out_wire;
  wire [32-1:0] wb_mux_out_Wb_wire;
  wire [32-1:0] rs1_Ex_wire;
  wire [32-1:0] rs2_Ex_wire;
  wire [32-1:0] rs1_Ma_wire;
  wire [32-1:0] rs2_Ma_wire;
  wire [2-1:0] busA_mux_sel_wire;
  wire [2-1:0] busB_mux_sel_wire;
  wire [3-1:0] imm_sel_wire;
  wire BrUn_wire;
  wire [3-1:0]alu_sel_wire;
  wire [3-1:0] alu_op_wire;
  wire BrEq_wire;
  wire BrLT_wire;
  wire mem_rw_wire;
  wire [2-1:0]wb_sel_wire;
  wire [3-1:0] reg_mux_sel_wire;
  wire [2-1:0] branch_muxA_sel_wire;
  wire [2-1:0] branch_muxB_sel_wire;
  wire [32-1:0] immediate_wire;
  wire [32-1:0] epc_wire;
  wire epc_taken_wire;
  wire wb_selMW_wire;
  wire [32-1:0] rdata_wire;
  wire [32-1:0] inst_csr_wire;
  wire is_mret_wire;
  
  
  pp_5stage pp_5stage_inst (.clk(clk), .reset(reset), .inst_Id(inst_ID_wire), .inst_Ex(inst_Ex_wire), .inst_Ma(inst_Ma_wire), .inst_Wb(inst_at_Wb_wire),.inst_csr(inst_csr_wire),.BrEq(BrEq_wire), .BrLT(BrLT_wire), .alu_op(alu_op_wire), .pc_sel(pc_sel_wire), .imm_sel(imm_sel_wire), .reg_write_en(reg_write_en_wire), .BrUn(BrUn_wire), .reg_mux_sel(reg_mux_sel_wire),.branch_muxA_sel(branch_muxA_sel_wire), .branch_muxB_sel(branch_muxB_sel_wire), .busA_sel_mux(busA_mux_sel_wire), .busB_sel_mux(busB_mux_sel_wire), .alu_sel(alu_sel_wire), .mem_rw(mem_rw_wire), .wb_sel(wb_sel_wire) ,.wb_selMW(wb_selMW_wire), .is_mret(is_mret_wire), .epc_taken(epc_taken_wire));
  
  If_stage If_stage_inst (.clk(clk), .reset(reset), .pc_sel(pc_sel_wire), .reg_mux_sel(reg_mux_sel_wire), .alu_out_Ex(alu_out_Ex_wire), .epc_taken(epc_taken_wire), .epc(epc_wire), .pc_ID(pc_ID_wire), .inst_ID(inst_ID_wire));
  
  Id_stage Id_stage_inst (.clk(clk), .reset(reset), .reg_write_en(reg_write_en_wire), .reg_mux_sel(reg_mux_sel_wire), .pc_ID(pc_ID_wire), .inst_ID(inst_ID_wire), .inst_Wb(inst_at_Wb_wire), .wb_mux_out_Wb(wb_mux_out_Wb_wire), .pc_Ex(pc_Ex_wire), .rs1_Ex(rs1_Ex_wire), .rs2_Ex(rs2_Ex_wire), .inst_Ex(inst_Ex_wire));
  
  Ex_stage Ex_stage_inst ( .clk(clk), .pc_Ex(pc_Ex_wire), .rs1_Ex(rs1_Ex_wire), .rs2_Ex(rs2_Ex_wire), .alu_out_Ma_fb(alu_out_Ma_wire), .wb_mux_out_Wb_fb(wb_mux_out_Wb_wire), .inst_Ex(inst_Ex_wire), .branch_muxA_sel(branch_muxA_sel_wire), .branch_muxB_sel(branch_muxB_sel_wire), .busA_mux_sel(busA_mux_sel_wire), .busB_mux_sel(busB_mux_sel_wire), .imm_sel(imm_sel_wire), .BrUn(BrUn_wire),.alu_sel(alu_sel_wire), .alu_op(alu_op_wire), .reg_mux_sel(reg_mux_sel_wire), .BrEq(BrEq_wire), .BrLT(BrLT_wire), .pc_Ma(pc_Ma_wire), .alu_out_Ex(alu_out_Ex_wire), .alu_out_Ma(alu_out_Ma_wire), .rs1_Ma(rs1_Ma_wire) ,.rs2_Ma(rs2_Ma_wire), .inst_Ma(inst_Ma_wire),.immediate(immediate_wire), .inst_csr(inst_csr_wire));
  
  Ma_stage Ma_stage_inst ( .clk(clk), .reset(reset), .pc_Ma(pc_Ma_wire), .alu_out_Ma(alu_out_Ma_wire), .rs2_Ma(rs2_Ma_wire), .inst_Ma(inst_Ma_wire), .mem_rw(mem_rw_wire), .wb_sel(wb_sel_wire), .reg_write_en(reg_write_en_wire), .wb_selMW(wb_selMW_wire), .rdata(rdata_wire), .wb_mux_out(wb_mux_out_wire), .inst_Wb(inst_Wb_wire));
  
  Wb_stage Wb_stage_inst ( .wb_mux_out(wb_mux_out_wire), .inst_Wb(inst_Wb_wire), .wb_mux_out_Wb(wb_mux_out_Wb_wire), .inst_at_Wb(inst_at_Wb_wire));
  
  csr csr_inst (.reset(reset), .clk(clk), .inst_csr(inst_csr_wire), .pc_Ma(pc_Ma_wire), .wdata(rs1_Ma_wire), .t_interrupt(t_interrupt), .e_interrupt(e_interrupt), .addr(immediate_wire), .reg_wr(), .reg_rd(), .is_mret(is_mret_wire), .rdata(rdata_wire), .epc(epc_wire), .epc_taken(epc_taken_wire));
  
 
endmodule


`include "pp_5stage.sv"
`include "IF.sv"
`include "ID.sv"
`include "EX.sv"
`include "MA.sv"
`include "WB.sv"
`include "csr.sv"

