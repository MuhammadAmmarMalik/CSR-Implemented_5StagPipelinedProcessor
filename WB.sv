module Wb_stage (
                    input logic [32-1:0] wb_mux_out,
                    input logic [32-1:0] inst_Wb,
  output logic [32-1:0] wb_mux_out_Wb,
  					output logic [32-1:0] inst_at_Wb

															);
 
	assign wb_mux_out_Wb = wb_mux_out;
	assign inst_at_Wb = inst_Wb;
  
endmodule
