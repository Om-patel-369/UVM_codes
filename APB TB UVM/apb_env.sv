class environment extends uvm_env;
agent agt;
scoreboard sb;

`uvm_component_utils(environment)

function new(string name = "environment",uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);

agt = agent::type_id::create("agent",this);
sb = scoreboard::type_id::create("sb",this);

endfunction

function void connect_phase(uvm_phase phase);
agt.mon.ap.connect(sb.a_imp);
`uvm_info("ENV","MON to SB port connection established",UVM_LOW)
endfunction

endclass
