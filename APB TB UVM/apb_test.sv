class test extends uvm_test;

environment env;

`uvm_component_utils(test)

function new(string name = "s_test",uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
env = environment::type_id::create("env",this);
endfunction

task run_phase(uvm_phase phase);
seq_c seq;

phase.raise_objection(this);
`uvm_info("TEST","objection raised",UVM_LOW)
seq = seq_c::type_id::create("seq");
seq.start(env.agt.seqr);
`uvm_info("TEST","objection dropped",UVM_LOW)
phase.drop_objection(this);
phase.phase_done.set_drain_time(this,10);

endtask

function void end_of_elaboration_phase(uvm_phase phase);
print();
endfunction

endclass


