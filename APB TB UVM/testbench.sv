// Code your testbench here
// or browse Examples

 import uvm_pkg::*;
`include "uvm_macros.svh"
   
`include "apb_int.sv"
`include "apb_seq_item.sv"
`include "apb_seq.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_sb.sv"
`include "apb_agent.sv"
`include "apb_env.sv"
`include "apb_test.sv"


module top;

bit pclk;
bit preset;

apb_int p_int(pclk,preset);
apb_slave dut (p_int);

initial begin
pclk = 0;
forever #5 pclk=~pclk;
end

initial begin
uvm_config_db#(virtual apb_int)::set(null,"*","vif",p_int);
run_test("test");
end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,top);
  end

endmodule
