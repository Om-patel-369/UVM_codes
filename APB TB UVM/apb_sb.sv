class scoreboard extends uvm_scoreboard;
uvm_analysis_imp#(txn,scoreboard) a_imp;
txn tx;

`uvm_component_utils(scoreboard)

bit [31:0] ref_mem [256];
int pass = 0;
int fail = 0;

function new(string name = "SB",uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);

a_imp =new("sb_ap",this);
tx = txn::type_id::create("sb_tx");

endfunction

function void write(txn tx);
`uvm_info("SB","got tx in SB",UVM_LOW)

if(tx.pwrite)
ref_mem[tx.paddr] = tx.pwdata; 

else begin
if(tx.prdata==ref_mem[tx.paddr]) begin
pass++;
`uvm_info("SB-COMP","-------read data matched------",UVM_LOW)
end
else begin
fail++;
`uvm_info("SB-COMP","WARNING:------read data mismatched--------",UVM_LOW)
end
end

endfunction

  
function void report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("SB-REPORT",$sformatf("\n \n TOTAL PASS -->%0d TOTAL FAIL-->%0d \n",pass,fail),UVM_NONE)
endfunction
endclass



