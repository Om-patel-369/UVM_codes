// Code your testbench here
// or browse Examples


import uvm_pkg::*;
`include "uvm_macros.svh"

//______________________INTERFACE_________________________

interface ram_if #(ADD_WIDTH=8,DATA_WIDTH=32) (input bit clk,input bit reset);
  
  logic [ADD_WIDTH-1:0]add;
  logic [DATA_WIDTH-1:0]din;//write
  logic [DATA_WIDTH-1:0]dout;//read
  bit w_en;
  bit r_en;
  
  clocking cb_tb @(posedge clk);
    input dout;
    output add,din,w_en,r_en;
    endclocking
  
  clocking cb_dut @(posedge clk);
    output dout;
    input add,din,w_en,r_en;
    endclocking

 modport DUT (clocking cb_dut, input clk, input reset);
  modport TB (clocking cb_tb, output clk, output reset);
    
    endinterface
    
//_________________________SEQ_ITEM______________________
    
 class ram_tx#(ADD_WIDTH=8,DATA_WIDTH=32) extends uvm_sequence_item; 
      
      
      rand bit [ADD_WIDTH-1:0]add;
      rand bit [DATA_WIDTH-1:0]din;//write
           bit [DATA_WIDTH-1:0]dout;//read
           bit w_en; //write_enable
           bit r_en; //read enable
   
           static bit count; //flag for w-r-w
           static int tx_no = 0;
   
   constraint c_din {din inside {[0:500]};}
      
      `uvm_object_param_utils_begin(ram_tx#(ADD_WIDTH,DATA_WIDTH))
   `uvm_field_int(add,UVM_DEFAULT+UVM_DEC)
   `uvm_field_int(din,UVM_DEFAULT+UVM_DEC)
   `uvm_field_int(dout,UVM_DEFAULT+UVM_DEC)
   `uvm_field_int(w_en,UVM_DEFAULT)
   `uvm_field_int(r_en,UVM_DEFAULT)
   `uvm_field_int(count,UVM_DEFAULT)
   `uvm_field_int(tx_no,UVM_DEFAULT)
   `uvm_object_utils_end // Don't add param in utils end MACRO
  
      
      
   function new(string name = "tx");
     super.new(name);
     
   endfunction
   
   function pre_randomize();
     count =~count; //for read after write 
     tx_no++; //to count no of tx
     
     if(count) begin
       w_en=1;
       r_en=0;
       dout=0;
     end
     
     else begin
       r_en=1;
       w_en=0;
       add.rand_mode(0);
       din=0;end
   
   endfunction
   
   function post_randomize();
     add.rand_mode(1); 
   endfunction
      
 endclass
    
//______________________SEQUENECE_________________________
      
    class base_sequence extends uvm_sequence#(ram_tx);
      ram_tx tx;
      
      `uvm_object_utils(base_sequence)
      
      function new(string name = "base_seq");
     super.new(name);
   endfunction
      
      task pre_body();
        `uvm_info(get_type_name,"into seq pre-body",UVM_HIGH) 
      endtask
      
      task body();
        
        tx = ram_tx#(8,32)::type_id::create("tx"); // added param
        
        repeat(1)begin
          
         `uvm_info(get_type_name,"into seq body",UVM_HIGH)
          start_item(tx);
          assert(tx.randomize());
          tx.print();
          finish_item(tx);
          `uvm_info(get_type_name,"tx over from seq body\n",UVM_HIGH)
          
        end
      endtask
      
      task post_body();
        `uvm_info(get_type_name,"into post_seq body",UVM_HIGH)
      endtask
      
    endclass
    
    //____________________CALLBACK___________________
    
    class base_cb extends uvm_callback;
      `uvm_object_utils(base_cb)
      
      function new(string name = "CB");
        super.new(name);
      endfunction
      
      virtual function void test_cb();
        `uvm_info("CB","callback check",UVM_LOW)
      endfunction
    endclass
 //__________________________DRIVER____________________________
    class driver extends uvm_driver#(ram_tx);
     `uvm_component_utils(driver)
      `uvm_register_cb(driver,base_cb)
      virtual ram_if vif;
      
      function new(string name = "driver", uvm_component parent = null);
        super.new(name,parent);
   endfunction
      
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ram_if)::get(this,"","vif",vif))
          `uvm_fatal("in driver","NO VIF set/get problem")
          endfunction
          
     task run_phase(uvm_phase phase); 
        ram_tx tx; 
     super.run_phase(phase);
     
        
        forever begin
          `uvm_info(get_type_name,"welcome to driver",UVM_HIGH)
           seq_item_port.get_next_item(tx); //recieve tx
          `uvm_info(get_type_name,"got next item",UVM_HIGH)
          
          drive(tx); // drive happens here
          `uvm_do_callbacks(driver,base_cb,test_cb())
          
          seq_item_port.item_done();//handshake
          `uvm_info(get_type_name,"item done from driver",UVM_HIGH)
           `uvm_info(get_type_name,$sformatf("ADD:%0d DIN:%0d W_EN:%0d R_EN:%0d",vif.add,vif.din,vif.w_en,vif.r_en),UVM_HIGH)
          end 
          endtask
          
          task drive(input ram_tx tx);
            @(vif.cb_tb);
            vif.add <= tx.add;
            vif.din <= tx.din;
            vif.w_en <= tx.w_en;
            vif.r_en <= tx.r_en;
            
    `uvm_info(get_type_name,"tx driven on if",UVM_HIGH)
          endtask
          endclass
//___________________________MONITOR___________________________
      class monitor extends uvm_monitor; 
          virtual ram_if vif;
          uvm_analysis_port#(ram_tx) ap; 
          `uvm_component_utils(monitor)
          
    function new(string name = "monitor", uvm_component parent = null);
     super.new(name,parent);
   endfunction
      
     function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     if(!uvm_config_db#(virtual ram_if)::get(this,"","vif",vif))
     `uvm_fatal("in driver","NO VIF set/get problem")
       
       ap= new("ap",this);
      endfunction 
        
     task run_phase(uvm_phase phase);
       ram_tx tx;
     super.run_phase(phase);
       
       forever begin
         `uvm_info(get_type_name,"welcome to monitor",UVM_HIGH)
         tx = ram_tx::type_id::create();
        
        @(negedge vif.clk);
         #1;
        tx.add=vif.add;
        tx.din=vif.din;
        tx.dout=vif.dout;
        tx.w_en=vif.w_en;
        tx.r_en=vif.r_en;
         
         `uvm_info(get_type_name,"rec tx from vif of DUT",UVM_HIGH)
        tx.print();
        ap.write(tx);
      end
       
     endtask
      endclass
        
//______________________AGENT______________________
        
   class agent extends uvm_agent;
   `uvm_component_utils(agent)
        
     driver drv;
     monitor mon;
     uvm_sequencer#(ram_tx) seqr;
    
     function new(string name = "agent", uvm_component parent = null);
     super.new(name,parent);
   endfunction
     
     function void build_phase(uvm_phase phase);
     super.build_phase(phase);
       drv = driver::type_id::create("driver",this);
       mon = monitor::type_id::create("monitor",this);
       seqr = uvm_sequencer#(ram_tx)::type_id::create("seqr",this);
     endfunction
     
     function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
       drv.seq_item_port.connect(seqr.seq_item_export);
     endfunction
   endclass
    
 //____________________SCOREBOARD________________________
        
        class scoreboard#(ADD_WIDTH=8,DATA_WIDTH=32) extends uvm_scoreboard;
          int pass =0;
          int fail =0;
          `uvm_component_param_utils(scoreboard#(ADD_WIDTH,DATA_WIDTH))
      
      // declaring memory
      logic [DATA_WIDTH-1:0] mem [(2**ADD_WIDTH)-1:0];
      // declaring queue to store the packet comes from monitor
      ram_tx mon_data[$];
      
      uvm_analysis_imp#(ram_tx,scoreboard) a_imp;
      
      function new(string name = "scoreboard", uvm_component parent = null);
     super.new(name,parent);
   endfunction
     
     function void build_phase(uvm_phase phase);
     super.build_phase(phase);
       a_imp = new("a_imp",this);
     endfunction
      
      function void write(ram_tx tx);
      ram_tx rec_tx;//for compare model
        
        mon_data.push_back(tx);
        `uvm_info(get_type_name(),"======SB======",UVM_LOW)
       // tx.print();
        
        if(mon_data.size() > 0) begin //start
          `uvm_info("ref mem","into compare mode of sb",UVM_LOW);
          
        rec_tx = mon_data.pop_front();
          
          if(rec_tx.w_en) begin
            mem[rec_tx.add] = rec_tx.din;
            `uvm_info("ref mem","ref mem wr done",UVM_LOW);
          end
          
          else if(rec_tx.r_en) begin
            
            if (rec_tx.dout == mem[rec_tx.add]) begin
              `uvm_info(get_type_name(),"\n ____ PASS _____\n",UVM_LOW)
              pass++; end
            
            else begin
       `uvm_warning(get_type_name(),"FAIL/MISMATCH")
              fail++; end
            
          end
        end 
      endfunction
          
          function void extract_phase(uvm_phase phase);
            `uvm_info(" SB COUNT ",$sformatf("\n >>>>TOTAL PASS-%0d & TOTAL FAIL-%0d <<<< \n",pass,fail),UVM_LOW)
        endfunction          
         
     endclass
//______________ENVIORNMENT________________
        
        class environment extends uvm_env; 
       `uvm_component_utils(environment)   
      agent agt;
      scoreboard sb;
      
      function new(string name = "Environment", uvm_component parent = null);
     super.new(name,parent);
   endfunction
     
     function void build_phase(uvm_phase phase);
     super.build_phase(phase);
       agt = agent::type_id::create("agent",this);
       sb = scoreboard::type_id::create("scoreboard",this);
     endfunction
      
      function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(sb.a_imp);
      endfunction
      
          function void end_of_elaboration_phase(uvm_phase phase);
            print();
          endfunction
            
    endclass
 //________________UVM_TEST________________
        
        class test extends uvm_test;
          `uvm_component_utils(test)
         environment env;
          base_cb b_cb;
          
          function new(string name = "TEST", uvm_component parent = null);
     super.new(name,parent);
   endfunction
          
          function void build_phase(uvm_phase phase);
     super.build_phase(phase);
            env = environment::type_id::create("env",this);
            b_cb = base_cb::type_id::create("CB");
            
          endfunction
          
    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
  uvm_callbacks#(driver,base_cb)::add(env.agt.drv,b_cb);
          endfunction
          
       task run_phase(uvm_phase phase);
           base_sequence b_seq;
        super.run_phase(phase);
       
         
         phase.raise_objection(this);//start
         b_seq = base_sequence::type_id::create("seq");
         b_seq.start(env.agt.seqr);
         phase.drop_objection(this); //end
         phase.phase_done.set_drain_time(this,12ns);
        
       endtask
        endclass
        
        
 //__________________Top module__________________
        
    module top;
      bit clk;
      bit reset;
      ram_if vif(clk,reset);
      
      ram DUT(vif);
      
      initial begin
        clk = 0;
        forever #5 clk = ~clk;
      end
      
      initial begin
        uvm_config_db#(virtual ram_if)::set(null,"*","vif",vif);
        run_test("test");
      end
    endmodule
        
        //________________{{{{{{{{{{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}