class agent extends uvm_agent;

driver drv;
monitor mon;
uvm_sequencer#(txn) seqr;

`uvm_component_utils(agent)

function new(string name = "act_agent",uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);

drv = driver::type_id::create("drv",this);
mon = monitor::type_id::create("mon",this);
seqr = uvm_sequencer#(txn)::type_id::create("seqr",this);

endfunction

function void connect_phase(uvm_phase phase);
drv.seq_item_port.connect(seqr.seq_item_export);
`uvm_info("AGT","driver to seqr port connection established",UVM_LOW)
endfunction

endclass

