// Code your testbench here
// or browse Examples

import uvm_pkg::*;
`include "uvm_macros.svh"
//_________________________________________________________
interface adder_if;
  bit [3:0]a,b;
  bit resp;
  bit [4:0]sum;
endinterface

//__________________________transaction_______________________________
class adder_txn extends uvm_sequence_item;
  rand bit [3:0]a,b;
       bit [4:0]sum;
       bit resp;
  
  `uvm_object_utils_begin(adder_txn)
  `uvm_field_int(a,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(b,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(sum,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(resp,UVM_DEFAULT+UVM_DEC)
  `uvm_object_utils_end
  
  
  function new (string name = "adder txn");
      super.new(name);
//     `uvm_info(get_type_name," txn class build",UVM_LOW)
    endfunction
endclass
//========================callback==========================

class do_callback extends uvm_callback; //regular callback
  `uvm_object_utils(do_callback)
  
  int count=0;
  
  function new(string name = "do_callback");
    super.new(name);
  endfunction
  
  virtual function void pre_drive();
    `uvm_info(get_type_name," pre-drive: congratulations, callback succesfully applied",UVM_LOW);
  endfunction
  
  virtual task modify(ref adder_txn tx);
    count++;
    if(count>=2 && count<=4) begin
    tx.a = tx.a + 1;
    tx.b = tx.b + 1;
      `uvm_info("IN CB","data modified by CB",UVM_LOW)
      `uvm_info(get_type_name,
                $sformatf(">>>> modified data by cb new A=%0d B=%0d",tx.a,tx.b),
        UVM_LOW)
    end
  endtask
    
  
  virtual function void post_drive();
    `uvm_info(get_type_name," post-drive: congratulations, callback succesfully applied",UVM_LOW);
  endfunction
  
endclass

//_____________extended callback____________________________________
class again_callback extends do_callback;
  `uvm_object_utils(again_callback)
  
  function new(string name = "ext_cb");
    super.new(name);
  endfunction
  
  function void pre_drive();
    `uvm_info(get_type_name," extended pre-drive: congratulations, callback succesfully applied",UVM_LOW);
  endfunction
    
  function void post_drive();
    `uvm_info(get_type_name," extended post-drive: congratulations, callback succesfully applied",UVM_LOW);
  endfunction
    
    endclass
      

//______________________sequnece______________________________________
class adder_seq extends uvm_sequence #(adder_txn);
  adder_txn tx;
  `uvm_object_utils(adder_seq)
  
  function new (string name = "sequence of sets ");
    super.new(name);
//     `uvm_info(get_type_name,"sequnece constructed",UVM_LOW)
    endfunction
  
  task body();
    
    repeat (5)begin
      `uvm_info(get_type_name," SEQUENCE STARTED",UVM_HIGH)
      tx = adder_txn::type_id::create("tx");
      wait_for_grant();//added
      `uvm_info(get_type_name,"wait for grant",UVM_LOW)
      assert(tx.randomize());
      tx.print();
      send_request(tx);//added
      `uvm_info(get_type_name,"send req ",UVM_LOW)
//       `uvm_info(get_type_name(),"before wait item done",UVM_LOW)
      wait_for_item_done();//added
      `uvm_info(get_type_name,"after wait item done",UVM_LOW)
      get_response(tx);//added
      `uvm_info(get_type_name,$sformatf("resp back trans =%p",tx.sprint()),UVM_LOW)
//       start_item(tx);
//       finish_item(tx);
    end
  endtask 
endclass
//-----------------------virtual sequence------------------

// class vir_seq extends uvm_sequence;
//   `uvm_object_utils(vir_seq);
  
//   `uvm_declare_p_sequencer(vir_seqr)
  
//   task body();
//     adder_seq n_seq;
//     n_seq = adder_seq::type_id::create("normal seq");
    
//     n_seq.start(p_sequencer.n_seqr);
    
//   endtask
// endclass
    
  
  
//--------------------sequncer-------------------

// class adder_seqr extends uvm_sequencer#(adder_txn);
//   `uvm_component_utils(adder_seqr)
  
//   function new(string name = "seqr",uvm_component parent)
//     super.new(name,parent);
//   endfunction
  
// endclass

//------------------------virtual sequencer---------------------------

// class vir_seqr extends uvm_sequencer;
//   `uvm_component_utils(vir_seq)
  
//   adder_seqr n_seqr;
  
//   function new(string name = "virtual seqr", uvm_component parent);
//     super.new(name,parent);
//   endfunction
  
// endclass


//______________________DRIVER_____________________________________
class adder_driver extends uvm_driver #(adder_txn);
  `uvm_component_utils(adder_driver)
  `uvm_register_cb(adder_driver,do_callback)
  uvm_event ev;
   virtual adder_if vif;
  
  function new (string name ="drv",uvm_component parent);
    super.new(name,parent);
//     `uvm_info(get_type_name,"driver created",UVM_LOW)
    endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name,"welcome to driver build phase",UVM_LOW);
    uvm_config_db#(uvm_event)::get(this,"","ev_event",ev);
    if(!uvm_config_db#(virtual adder_if)::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","NO vif")
  endfunction
  
  task run_phase(uvm_phase phase);
    adder_txn tx;
    
    
    forever begin
      
      ev.wait_trigger();
      $display(" wait trigger executed");
      
      `uvm_do_callbacks(adder_driver,do_callback,pre_drive())
      
      `uvm_info(get_type_name,"welcome to driver run phase",UVM_LOW) 
//      seq_item_port.get_next_item(tx);
      seq_item_port.get(tx);
      `uvm_info(get_type_name,"got next item",UVM_LOW)
      
      `uvm_do_callbacks(adder_driver,do_callback,modify(tx));

      
      vif.a <= tx.a;
      vif.b <= tx.b;
      #1;
      tx.resp = 1;
//      seq_item_port.item_done();
      seq_item_port.put(tx);
      `uvm_info(get_type_name(),"after item done",UVM_LOW)
      `uvm_do_callbacks(adder_driver,do_callback,post_drive())
    end
  endtask
endclass
//_________________________MONITOR______________________

class adder_monitor extends uvm_monitor;
  `uvm_component_utils(adder_monitor)
  virtual adder_if vif;
  uvm_analysis_port#(adder_txn) ap;
  
  
  function new (string name = "monitor of class",uvm_component parent);
    super.new(name,parent);
    endfunction
   
  function void build_phase(uvm_phase phase);
    ap = new("ap",this);
    
    if (!uvm_config_db#(virtual adder_if)::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","no vif")
      endfunction
      
      task run_phase(uvm_phase phase);
    adder_txn tx;
   
    forever begin
      `uvm_info(get_type_name,"welcome to monitor run phase",UVM_HIGH)
      tx = adder_txn::type_id::create("tx");
      
      #1;
      
      tx.a = vif.a;
      tx.b = vif.b;
      tx.sum = vif.sum;
      
      ap.write(tx);
    end
    endtask
    endclass
    
 //_____________________---scoreboard_________________________________
    
    class adder_sb extends uvm_component;
      
      `uvm_component_utils(adder_sb)
      uvm_event ev;
      
      uvm_analysis_imp#(adder_txn,adder_sb) imp;
      
      function new (string name = "scoreboard of match ",uvm_component parent);
    super.new(name,parent);
    endfunction
      
      function void build_phase(uvm_phase phase);
        imp = new("imp",this);
        uvm_config_db#(uvm_event)::get(this,"","ev_event",ev);
      endfunction
      
      function void write(adder_txn tx);
        `uvm_info(get_type_name,"welcome to Scoreboard write method",UVM_HIGH)
        if (tx.sum == tx.a + tx.b) begin
          `uvm_info("pass","correct",UVM_LOW)
          ev.trigger(); end// event triggered 
          else
            `uvm_error("fail","wrong result")
    endfunction
  endclass
            
//___________________________AGENT_____________________________
            
  class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent)
    
    adder_driver drv;
    adder_monitor mon;
    uvm_sequencer#(adder_txn) seqr;
    
    function new (string name = "agent vinod ",uvm_component parent);
    super.new(name,parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      drv = adder_driver::type_id::create("drv",this);
      mon = adder_monitor::type_id::create("mon",this);
      seqr = uvm_sequencer#(adder_txn)::type_id::create("seqr",this);
       
    endfunction
    
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass
        
//_____________________________ENV__________________________________
        
  class adder_env extends uvm_env;
    
    `uvm_component_utils(adder_env)
    
    adder_agent agt;
    adder_sb sb;
//      vir_seqr vseqr;  //for virtual sequencer
    
    function new (string name = "Env. of earth ",uvm_component parent);
    super.new(name,parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = adder_agent::type_id::create("agt",this);
      sb = adder_sb::type_id::create("sb",this);
//       vseqr = vir_seqr::type_id::create("vir_seqr"); //create virtual sequencer
    endfunction
    
    function void connect_phase(uvm_phase phase);
      agt.mon.ap.connect(sb.imp);
//       vseqr.n_seqr = agt.seqr; // real to virtual seqr
    endfunction
    
    
  endclass
 //_________________________________TEST____________________________
        
        class adder_test extends uvm_test;
          `uvm_component_utils(adder_test)
          adder_env env;
          uvm_event ev;
          do_callback do_cb; //callback instantiated
          
          
          
    function new (string name = " test of whites ",uvm_component parent);
    super.new(name,parent);
    endfunction
          
          function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = adder_env::type_id::create("env",this);
            ev = new("event");
            uvm_config_db#(uvm_event)::set(this,"*","ev_event",ev);
        do_cb = do_callback::type_id::create("callback_class");
            uvm_top.set_timeout(8ns);// uvm_callbacks#(adder_driver,do_callback)::add(env.agt.drv,do_cb); 
            //if i write it here it is giving null error
          endfunction
          
          function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);  //so, moved it here
            uvm_callbacks#(adder_driver,do_callback)::add(env.agt.drv,do_cb);
          endfunction
          
          
          task run_phase(uvm_phase phase);
            adder_seq seq;
//             vir_seq vseq;// v sequence 
            
            phase.raise_objection(this);
            
            seq = adder_seq::type_id::create("seq");
//             vseq = vir_seq::type_id::create("vseq"); //to start virtual seqeunce
            seq.start(env.agt.seqr);
//             vseq.start(env.vseqr); //vseq on vseqr
            
//             #10;
            `uvm_info(get_type_name(),"med verbosity",200)
//             `uvm_info(get_type_name(),"high verbosity",UVM_HIGH)
//             `uvm_info(get_type_name(),"none verbosity",UVM_NONE)
//             `uvm_info(get_type_name(),"full verbosity",UVM_FULL)
//             `uvm_info(get_type_name(),"debug verbosity",UVM_DEBUG)
//             `uvm_warning(get_type_name(),"warning severity")
//             `uvm_error(get_type_name(),"error severity")
//             #3;
//             //`uvm_fatal(get_type_name(),"fatal severity")
//             `uvm_info(get_type_name(),"none verbosity",UVM_NONE)
            
            
            phase.drop_objection(this);
          endtask
          
        endclass
        //----------------------------extended test---------------
        class ex_test extends adder_test;
          `uvm_component_utils(ex_test)
          again_callback acb;
          
          function new(string name = "ex_test",uvm_component parent);
            super.new(name,parent);
          endfunction
          
          function void build_phase(uvm_phase phase);
            super.build_phase(phase);
          endfunction
          
          function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            
            acb = again_callback::type_id::create("acb");
            uvm_callbacks#(adder_driver,do_callback)::add(env.agt.drv,acb);
          endfunction
        endclass
          
          
          
//_________________________TOP_________________________________
        
        module top;
          adder_if vif();
          
          assign vif.sum = vif.a + vif.b;//dut
          
          initial begin  
            
          uvm_config_db#(virtual adder_if)::set(null,"*","vif",vif);
            
            run_test("adder_test");
          end
        endmodule
//________________++++_____________+++++______________+++++_______
