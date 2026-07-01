// Code your testbench here
// or browse Examples

import uvm_pkg::*;
`include "uvm_macros.svh"
`define NUM_W_TX 5
`define NUM_R_TX 1


//================--- INTERFACE --- =====================================

interface axi_if(input bit clk,input bit reset);
  
  //AW channel- write address
  
  logic awvalid;
  logic awready;
  
  logic [31:0]awaddr;
  logic [7:0] awlen;//max 256 beats
  logic [1:0] awsize;//max 4 byte
  logic [1:0] awburst; //enum
  
  //W channel - write data
  
  logic wvalid;
  logic wready;
  
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wlast;
  
  //B channel - write response
  
  logic bvalid;
  logic bready;
  
  logic [1:0] bresp; //enum
  
  //AR channel - read address
  
  logic arvalid;
  logic arready;
  
  logic [31:0]araddr;
  logic [7:0] arlen;
  logic [1:0] arsize;
  logic [1:0] arburst; //enum
  
  //R channel - read data
  
  logic rvalid;
  logic rready;
  logic rlast;
  
  logic [31:0]rdata;
  logic [1:0] rresp; //enum
  
endinterface

//**********************************************
//------------------AXI_TX_CLASS & ENUM --------
//**********************************************

typedef enum bit {READ,WRITE} axi_rw;  //global enum
typedef enum {FIXED,INCR,WRAP} burst_t;
typedef enum logic[1:0] {OKAY,EXOKAY,SLVERR,DECERR}resp_t;
//-----------------------------------------------
class axi_tx extends uvm_sequence_item;
    
  //read or write tx flag
  rand axi_rw rw;
  
  //write address signals
//  rand bit [3:0] awid;
  rand bit[31:0] awaddr;
  rand bit [7:0] awlen;
  rand bit [1:0] awsize;
  rand burst_t  awburst;
  
  //write data signals
  rand bit [31:0] wdata[$];
  rand bit [3:0]  wstrb[$];
       bit        wlast;
  
  //write response 
  resp_t bresp;
  
  //read address channel
//  rand bit [3:0]  arid;
  rand bit [31:0] araddr;
  rand bit [7:0]  arlen;
  rand bit [1:0]  arsize;
  rand burst_t  arburst;
  
  //read data channel
  bit[31:0] rdata[$];
  bit       rlast;
  
  resp_t rresp; //read response
  
  //constraints
    
  constraint awlen_c {
    awaddr inside {[0:511]}; //easy
    araddr inside {[0:500]}; // numbers
    awsize < 3;
    awburst==WRAP; 
  }
  
  constraint wdata_c{
    foreach(wdata[i]) {
      wdata[i] inside {[0:65535]};
    }
  }
 
   constraint awaddress_c{
     if(awburst == WRAP) { awaddr % 4 == 0;}
        
   }
    
       
  constraint array_size_c {
    wdata.size() == awlen + 1;
    wstrb.size() == awlen + 1;
  }
      
          
  constraint wlen_sup_c{
    
    if (awburst == WRAP){awlen inside {1,3,7,15};}
    //awlen inside {[0:3]};
    awlen == 3; 
  }
      
  constraint rlen_sup_c{      
    if (arburst == WRAP){arlen inside {1,3,7,15};}
    arlen inside {[0:3]};
  }
      
     
    //factory reg.
  
  `uvm_object_utils_begin(axi_tx)
  
  `uvm_field_enum(axi_rw,rw,UVM_DEFAULT) //read write enum
  
//  `uvm_field_int(awid,UVM_DEFAULT)
      `uvm_field_int(awaddr,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(awlen,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(awsize,UVM_DEFAULT+UVM_DEC)
  `uvm_field_enum(burst_t,awburst,UVM_DEFAULT) //enum
  
  `uvm_field_queue_int(wdata,UVM_DEFAULT+UVM_DEC) //array
      `uvm_field_queue_int(wstrb,UVM_DEFAULT+UVM_BIN) //array  
  `uvm_field_int(wlast,UVM_DEFAULT)
  `uvm_field_enum(resp_t,bresp,UVM_DEFAULT)//enum
 
//  `uvm_field_int(arid,UVM_DEFAULT)
  `uvm_field_int(araddr,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(arlen,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(arsize,UVM_DEFAULT+UVM_DEC) 
  `uvm_field_enum(burst_t,arburst,UVM_DEFAULT) //enum
    
  `uvm_field_queue_int(rdata,UVM_DEFAULT+UVM_DEC) //array
  `uvm_field_enum(resp_t,rresp,UVM_DEFAULT) //enum
  `uvm_field_int(rlast,UVM_DEFAULT)
  
  `uvm_object_utils_end
    
  function new(string name = "axi_tx");
    super.new(name);
  endfunction
  
endclass

//*********************************************
//------------------AXI_SEQ_CLASS--------------
//*********************************************
    
    class axi_w_seq extends uvm_sequence #(axi_tx);
      axi_tx w_tx;
      
      `uvm_object_utils(axi_w_seq)
      
      function new (string name ="axi_w_seq");
        super.new(name);
      endfunction
      
      task body();
        repeat (`NUM_W_TX) begin
          w_tx = axi_tx::type_id::create("w_tx");
          start_item(w_tx);
          w_tx.araddr.rand_mode(0);
          w_tx.arlen.rand_mode(0);
          w_tx.rlen_sup_c.constraint_mode(0);
          w_tx.arsize.rand_mode(0);
          assert (w_tx.randomize() with {rw==WRITE;});
          finish_item(w_tx);          
        end
      endtask
    endclass
    
    class axi_r_seq extends uvm_sequence #(axi_tx);
      axi_tx r_tx;
      
      `uvm_object_utils(axi_r_seq)
      
      function new (string name ="axi_r_seq");
        super.new(name);
      endfunction
      
      task body();
        repeat (`NUM_R_TX) begin
          r_tx = axi_tx::type_id::create("r_tx");
          start_item(r_tx);
          r_tx.awaddr.rand_mode(0);
          r_tx.awlen.rand_mode(0);
          r_tx.wlen_sup_c.constraint_mode(0);
          r_tx.awsize.rand_mode(0);
          r_tx.array_size_c.constraint_mode(0);          
          r_tx.wdata.rand_mode(0);          
          r_tx.wstrb.rand_mode(0);
          assert (r_tx.randomize() with {rw==READ;});
          finish_item(r_tx);        
        end
      endtask
    endclass
    
    class axi_seqr extends uvm_sequencer#(axi_tx);
      `uvm_component_utils(axi_seqr)
      
      function new(string name ="axi_seqr",uvm_component parent);
        super.new(name,parent);
      endfunction
      
    endclass
    
    class virtual_seqr extends uvm_sequencer;
      `uvm_component_utils(virtual_seqr)
      axi_seqr axi_ka_seqr;
      
      function new(string name ="v_seqr",uvm_component parent);
        super.new(name,parent);
      endfunction
      
    endclass
    
    class v_seq extends uvm_sequence;
      axi_w_seq wseq;
      axi_r_seq rseq;
      
      axi_seqr seqr;
      `uvm_declare_p_sequencer(virtual_seqr)
           
      `uvm_object_utils(v_seq)
            
      function new (string name = "v_seq");
        super.new(name);
      endfunction
      
      virtual task body();
        wseq = axi_w_seq::type_id::create("w_seq");
        
        
       // rseq = axi_r_seq::type_id::create("r_seq");
        
        
        wseq.start(p_sequencer.axi_ka_seqr);
       // rseq.start(p_sequencer.axi_ka_seqr);
        
        
      endtask      
    endclass
  
//************************************************
//------------------AXI_DRIVER_CLASS--------------
//************************************************
    
class axi_driver extends uvm_driver#(axi_tx);
  virtual axi_if vif;
  uvm_analysis_port#(axi_tx) drv_ap;
  `uvm_component_utils(axi_driver)
  
  function new(string name = "axi_driver",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
       `uvm_fatal("DRV","NO VIF FOUND")
      drv_ap = new("drv_ap",this);
  endfunction
  
  task run_phase(uvm_phase phase);
    axi_tx tx;
    forever begin
      
      seq_item_port.get_next_item(tx);
      `uvm_info ("DRV","TX GOT IN DRIVER",UVM_LOW)
      tx.print(uvm_default_line_printer);
      
      case(tx.rw)
        WRITE : drive_write(tx);
        READ  : drive_read(tx);
      endcase
      
      seq_item_port.item_done();   
    end   
  endtask //runphase end
       
       //for WRITE
       task drive_write(axi_tx tx);
         drive_aw(tx);
         drive_w(tx);
         get_bresp(tx);
         drv_ap.write(tx);
         `uvm_info ("DRV","WRITE TX SENT TO SB by AP",UVM_LOW)
      endtask
       //AW
       task drive_aw(axi_tx tx);
         @(posedge vif.clk);
         vif.awvalid<=1;
         `uvm_info ("DRV","AWVALID=1 - DRIVING AW",UVM_LOW)
         
         vif.awaddr <= tx.awaddr;
         vif.awlen <= tx.awlen;
         vif.awsize <= tx.awsize;
         vif.awburst <= tx.awburst;
         
         wait(vif.awready==1);
         `uvm_info ("DRV HS","AW HS DONE",UVM_LOW)
         @(posedge vif.clk);
         vif.awvalid<=0;
         `uvm_info ("DRV","AWVALID = 0",UVM_LOW)
         
       endtask
       //w
       task drive_w(axi_tx tx);
         
         @(posedge vif.clk); //35
         vif.wvalid<=1;
         `uvm_info ("DRV","WVALID=1 - DRIVING W",UVM_LOW)
         
         foreach (tx.wdata[i]) begin //for each element
           vif.wdata<=tx.wdata[i];
           vif.wstrb<=tx.wstrb[i];
           `uvm_info ("DRV",$sformatf("wdata=%0d i=%0d, tx.wdata.size()= %0d",tx.wdata[i],i,tx.wdata.size()),UVM_LOW)

           if(i==(tx.wdata.size()-1)) begin
            vif.wlast<=1;
             tx.wlast = 1;
//              vif.wvalid<=0;
             `uvm_info ("DRV","wlast = 1 so WVALID=0",UVM_LOW)
             
           end
            else
             vif.wlast<=0;
           
           if(!vif.wlast)
             wait(vif.wready==1);//handshake
             `uvm_info ("DRV W-HS","Write HS DONE",UVM_LOW)
           @(posedge vif.clk);
           
         end  //loop ends
         
         vif.wvalid<=0;
         vif.wlast<=0;
         `uvm_info ("DRV","WVALID = 0",UVM_LOW)
       
       endtask 
  
       //B
       task get_bresp(axi_tx tx);
         
         wait(vif.bvalid==1);
         `uvm_info ("DRV"," wait over BVALID = 1, on BRESP channel ",UVM_LOW)
      
         
         vif.bready<=1;
         tx.bresp = vif.bresp;
         `uvm_info ("DRV B-HS",$sformatf("after HS got Bresp = %0s",tx.bresp.name()),UVM_LOW)
         @(posedge vif.clk);
         vif.bready<=0;
         `uvm_info ("DRV","Bready = 0",UVM_LOW)
         
       endtask
       
       //for read
       
       task drive_read(axi_tx tx);
         drive_ar(tx);         
         get_data_resp(tx);
         drv_ap.write(tx);
         `uvm_info ("DRV","READ TX SENT TO SB by AP",UVM_LOW)
       endtask
       
       //AR
       task drive_ar(axi_tx tx);
         
         @(posedge vif.clk);
         vif.arvalid<=1;
         `uvm_info ("DRV","AR CHANNEL-DRIVING ARVALID = 1 ",UVM_LOW)
         vif.araddr <= tx.araddr;
         vif.arlen <= tx.arlen;
         vif.arsize <= tx.arsize;
         vif.arburst <= tx.arburst;
         
         wait (vif.arready==1);
         `uvm_info ("DRV AR-HS","ARREADY = 1 ",UVM_LOW)
         @(posedge vif.clk);
         vif.arvalid<=0;
         `uvm_info ("DRV","ARVALID = 0 ",UVM_LOW)
         
       endtask
  
       // R 
  
  task get_data_resp(ref axi_tx tx);
         @(posedge vif.clk);
          wait(vif.rvalid==1);
           @(posedge vif.clk);
           vif.rready <= 1;
           `uvm_info ("DRV R-HS"," R channel HS done, rvalid = 1 ",UVM_LOW)
      
    `uvm_info ("DRV","R CHANNEL-RECIEVING RREADY = 1 ",UVM_LOW)
         
         for(int i=0;i<tx.arlen+1;i++) begin
              `uvm_info ("DRV","in R Channel - read loop",UVM_LOW)
              @(negedge vif.clk);//added for rdata in SB
           tx.rdata.push_back(vif.rdata);
              `uvm_info ("DRV R-HS",$sformatf("vif.rdata=%0d",vif.rdata),UVM_LOW) 
           
           tx.rresp <= vif.rresp;           
           
      `uvm_info ("DRV",$sformatf("rdata[%0d] = %0d vif.rdata=%0d",i,tx.rdata[i],vif.rdata),UVM_LOW)
     // @(negedge vif.clk); //added
      `uvm_info("DRV",$sformatf("rresp=%s - %b vif.rresp =%b",tx.rresp.name(),tx.rresp,vif.rresp),UVM_LOW)
           
           if(vif.rlast) begin             
             `uvm_info ("DRV"," RLAST = 1 ",UVM_LOW)
             tx.rlast <= vif.rlast;
             @(posedge vif.clk);
             vif.rready<=0;
             `uvm_info ("DRV","RREADY = 0 ",UVM_LOW) end
           else
             @(posedge vif.clk);
      
         end //loop end
         
       endtask
       // all subtask ends here      
  endclass
  
//***********************************************
//----------------AXI_MONITOR_CLASS-------------
//***********************************************
   class axi_monitor extends uvm_monitor;
     virtual axi_if vif;
     uvm_analysis_port#(axi_tx) ap;
     axi_tx tx,rtx,trans,rtrans;
     uvm_event evnt;
     
     `uvm_component_utils(axi_monitor)
     
     function new(string name = "monitor",uvm_component parent);
       super.new(name,parent);
     endfunction
     
     function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       if(!uvm_config_db#(virtual axi_if)::get(this,"","vif",vif))
       `uvm_fatal("DRV","NO VIF FOUND")
         ap =new("mon_ap",this);
     endfunction
     
     task run_phase(uvm_phase phase);
       tx = axi_tx::type_id::create("mon_tx");
       rtx = axi_tx::type_id::create("mon_rx");
       evnt = uvm_event_pool::get_global("mon2sb_event");
       
       forever begin
         
         @(posedge vif.clk); //original negedge
         `uvm_info ("MON ","WELCOME TO MON",UVM_HIGH)
         fork
           mon_aw();
           mon_w();
           mon_b();
           mon_ar();
           mon_r();
         join
       end
     endtask
       
       task mon_aw();
         if(vif.awvalid && vif.awready)begin
           
           `uvm_info ("MON HS","AW-HS DONE",UVM_LOW)
           tx.awaddr = vif.awaddr;
           tx.awlen = vif.awlen;
           tx.awsize = vif.awsize;
           tx.awburst = vif.awburst;
           tx.rw = WRITE;
           
            
           `uvm_info ("MON",$sformatf("AWADD=%0d AWLEN=%0d AWSIZE=%0d AWBURST=%s",tx.awaddr,tx.awlen,tx.awsize,tx.awburst.name()),UVM_LOW)
         end           
       endtask
       
       task mon_w();
         `uvm_info ("MON HS",">>>BEFORE W-HS DONE<<<",UVM_HIGH)
         if(vif.wvalid && vif.wready)begin
           `uvm_info ("MON HS",">>>>>> AFTER W-HS DONE<<<<<<<",UVM_LOW)
           tx.wdata.push_back(vif.wdata);
           tx.wstrb.push_back(vif.wstrb);
           tx.wlast = vif.wlast;
           `uvm_info ("MON GOT",$sformatf("vif.wdata=%0d -tx.wdata=%p",vif.wdata,tx.wdata),UVM_LOW)
                     
           if(tx.wlast) begin
             `uvm_info ("MON","WLAST=1",UVM_LOW)
//              ap.write(tx);
//              tx.wdata.delete(); // Empty Queue
//              `uvm_info ("MON","SENT W-TX TO SB",UVM_LOW)
           end
         end
       endtask
       
       task mon_b();
         if(vif.bvalid && vif.bready)begin
           `uvm_info ("MON HS","B-HS DONE",UVM_LOW)
           tx.bresp = vif.bresp;
           `uvm_info ("MON",$sformatf("Bresp = %s",tx.bresp.name()),UVM_LOW)
            trans = new tx;
            ap.write(trans);
           evnt.trigger();
           `uvm_info ("MON","event triggered tx sent",UVM_LOW)
             tx.wdata.delete(); // Empty Queue
             tx.wstrb.delete();
             `uvm_info ("MON","SENT W-TX TO SB",UVM_LOW)
         end
       endtask
         
         task mon_ar();
           if(vif.arvalid && vif.arready)begin
             `uvm_info ("MON HS","AR-HS DONE",UVM_LOW)
           rtx.araddr = vif.araddr;
           rtx.arlen = vif.arlen;
           rtx.arsize = vif.arsize;
           rtx.arburst = vif.arburst;
             rtx.rw = READ;
             `uvm_info ("MON",$sformatf("ARADD=%0d ARLEN=%0d ARSIZE=%0d ARBURST=%0d",rtx.araddr,rtx.arlen,rtx.arsize,rtx.arburst),UVM_LOW)
             
           end
         endtask
         
         task mon_r();
           if(vif.rvalid && vif.rready) begin
             `uvm_info ("MON HS","R-HS DONE",UVM_LOW)
             rtx.rdata.push_back(vif.rdata);
             rtx.rlast = vif.rlast;
             rtx.rresp = vif.rresp;
             if(rtx.rlast)begin
               `uvm_info ("MON","RLAST=1",UVM_LOW)
               //rtx.rresp = vif.rresp;
               rtrans = new rtx;
               ap.write(rtrans);
               rtx.rdata.delete();
             //  rtx.rdata.delete(); // Delete read data queue
               `uvm_info ("MON","SENT R-TX TO SB",UVM_LOW)
             evnt.trigger();
               `uvm_info ("MON EVENT","EVENT triggered ",UVM_LOW)
             end
           end
         endtask
           
   endclass
    
//*********************************************
//----------------AXI_COVERAGE_CLASS-----------
//*********************************************
    
    
//     class axi_cov extends uvm_subscriber#(axi_tx);
//       `uvm_component_utils(axi_cov)
      
//       virtual function void write(axi_tx t);
//         axi_wcover_group.sample();
//         axi_rcover_group.sample();
//       endfunction
      
//       covergroup axi_wcover_group;
        
//         awburst_cp: coverpoint t.awburst;
//         bresp_cp:  coverpoint t.bresp;
//         awlen_cp: coverpoint t.awlen;
//         awsize_cp: coverpoint t.awsize;
   
//       endgroup
       
//       covergroup axi_rcover_group;
        
//         arburst_cp: coverpoint t.arburst;
//         rresp_cp:  coverpoint t.rresp;
//         arlen_cp: coverpoint t.arlen;
//         arsize_cp: coverpoint t.arsize;
       
//       endgroup
      
//       function new(string name ="coverage", uvm_component parent);
//         super.new(name,parent);
//         axi_wcover_group = new();
//         axi_rcover_group = new();
//       endfunction
      
//     endclass 
       
        
//*********************************************
//----------------AXI_AGENT_CLASS-------------
//*********************************************
       
    class axi_agent extends uvm_agent;
      `uvm_component_utils(axi_agent)
      
      axi_driver drv;
      axi_monitor mon;
      axi_seqr axi_p_seqr;
      
      
      function new(string name = "",uvm_component parent);
        super.new(name,parent);
      endfunction
      
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = axi_driver::type_id::create("axi_drv",this);
        mon = axi_monitor::type_id::create("axi_mon",this);
        axi_p_seqr = axi_seqr::type_id::create("seqr",this);
      endfunction
      
      function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(axi_p_seqr.seq_item_export);
        `uvm_info ("AGENT","DRV TO SEQR CONNECTED",UVM_HIGH)
        
      endfunction     
    endclass
         
//*********************************************
//----------------AXI_SCOREBOARD_CLASS-------------
//*********************************************
       `uvm_analysis_imp_decl(_mon_imp)
       `uvm_analysis_imp_decl(_drv_imp)    
       
       
    class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)
    uvm_analysis_imp_mon_imp#(axi_tx,axi_scoreboard) monn_imp;
    uvm_analysis_imp_drv_imp#(axi_tx,axi_scoreboard) drvv_imp;
      axi_tx drv2sb_tx[$],mon2sb_tx[$]; //to save txs in queue
      axi_tx dtx,mtx; //to save from queue and compare 
      uvm_event evnt;
      int unsigned matched_tx,mismatched_tx;
      
      
      function new(string name = "SB",uvm_component parent);
       super.new(name,parent);
      endfunction
      
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monn_imp = new("mon_imp",this);
        drvv_imp = new("drv_imp",this);
      endfunction
      
      function write_mon_imp(axi_tx tx);
        tx.print(uvm_default_line_printer);
        mon2sb_tx.push_back(tx);
        `uvm_info ("SB WRITE",$sformatf("mon2sb queue =%p",mon2sb_tx),UVM_LOW)
      endfunction
      
      function write_drv_imp(axi_tx tx);
        tx.print(uvm_default_line_printer);
        drv2sb_tx.push_back(tx);
        `uvm_info ("SB WRITE",$sformatf("drv2sb queue =%p",drv2sb_tx),UVM_LOW)
      endfunction
      
      function bit compare_tx(axi_tx dtx,axi_tx mtx);
        if (dtx.rw == READ) begin//1
          
          if(dtx.araddr == mtx.araddr && dtx.arlen == mtx.arlen && dtx.arsize == mtx.arsize && dtx.arburst == mtx.arburst && dtx.rdata == mtx.rdata && dtx.rresp == mtx.rresp)
            return 1;
          else begin//2
            dtx.print(uvm_default_line_printer);
            mtx.print(uvm_default_line_printer);
            return 0;
          end//2
        end//1
        
        else begin
          if(dtx.awaddr == mtx.awaddr && dtx.awlen == mtx.awlen && dtx.awsize == mtx.awsize && dtx.awburst == mtx.awburst && dtx.wdata == mtx.wdata && dtx.bresp == mtx.bresp)
            return 1;
          else begin
            dtx.print(uvm_default_line_printer);
            mtx.print(uvm_default_line_printer);
            return 0;
          end
        end
      endfunction
      
      function compare_drv_with_mon();
        `uvm_info ("SB","COMPARISON STARTED",UVM_LOW)
        dtx=drv2sb_tx.pop_front();
        mtx=mon2sb_tx.pop_front();
//         dtx.print();
//         mtx.print();
        if (compare_tx(dtx,mtx))begin
          `uvm_info("SB","\nDRV and MON signals matched\n",UVM_LOW)
          matched_tx++;end
          else begin
            `uvm_info("SB",$sformatf("\nDRV and MON signals NOT matched\n"),UVM_LOW)
            mismatched_tx++;end
                
      endfunction
            
        task run_phase(uvm_phase phase);
        super.run_phase(phase);
        evnt = uvm_event_pool::get_global("mon2sb_event");
        `uvm_info ("SB","RUN PHASE OF SB",UVM_LOW)
        
        forever begin//1
          `uvm_info ("SB","RUN PHASE OF SB before condition",UVM_LOW)
          evnt.wait_ptrigger();
          `uvm_info ("SB EVENT","wait over now comp. starts",UVM_LOW)
          if(mon2sb_tx.size()>0 && drv2sb_tx.size()>0)begin//2
            
            compare_drv_with_mon();
            `uvm_info ("SB COMP","________________COMPARISON DONE___________________",UVM_LOW)           
          evnt.reset();
            `uvm_info ("SB EVENT",">>>>----Event reset done-------<<<<<",UVM_LOW)
            
          end//2
          #5;          
        end//1
          
         
        endtask  
      
      virtual function void report_phase(uvm_phase phase);
        `uvm_info ("SB RESULT",$sformatf("\n\nTOTAL MATCHED=%0d TOTAL MISMATCHED=%0d\n",matched_tx,mismatched_tx),UVM_LOW)
          
      endfunction
    endclass
        
//***************************************
//----------------AXI_ENV_CLASS---------
//***************************************
     class axi_env extends uvm_env;
          
    `uvm_component_utils(axi_env)
    
    axi_agent agt;
    axi_scoreboard sb;
    virtual_seqr v_seqr;
       
    
    function new (string name = "axi_env",uvm_component parent);
    super.new(name,parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = axi_agent::type_id::create("agt",this);
      sb = axi_scoreboard::type_id::create("sb",this);      
      v_seqr = virtual_seqr::type_id::create("v-seqr",this);
      
    endfunction
       
     function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       agt.mon.ap.connect(sb.monn_imp);
       `uvm_info ("ENV","MON to SB-AP CONNECTED",UVM_HIGH)
       agt.drv.drv_ap.connect(sb.drvv_imp);
       `uvm_info ("ENV","DRV to SB-AP CONNECTED",UVM_HIGH)
       v_seqr.axi_ka_seqr = agt.axi_p_seqr;
     endfunction
       
     endclass
        
//*********************************************
//----------------AXI_TEST---------------------
//*********************************************
     class axi_test extends uvm_test;
      `uvm_component_utils(axi_test)
     axi_env env;
     v_seq vseq;
          
     function new (string name = "axi_test",uvm_component parent);
    super.new(name,parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = axi_env::type_id::create("env",this);
    endfunction
       
       task run_phase(uvm_phase phase);
         
         phase.raise_objection(this);
         `uvm_info ("TEST","EVERYTHING STARTS HERE- AXI WORLD",UVM_LOW)
         
         vseq = v_seq::type_id::create("v_seq");
         
         vseq.start(env.v_seqr);
         `uvm_info ("TEST","SEQ STARTED ON SEQR",UVM_LOW)
         phase.drop_objection(this);
         `uvm_info ("TEST","ALMOST EVERYTHING STOPS HERE",UVM_LOW)
         phase.phase_done.set_drain_time(this,25);
                  
       endtask
     endclass
        
//*********************************************
//----------------AXI_TOP_MODULE---------------
//*********************************************
        
        
   module top;
     bit clk,reset;
     axi_if vif (clk,reset);
     axi_slave_dut dut (vif);
     
     initial begin
      uvm_config_db#(virtual axi_if)::set(null,"*","vif",vif);
       `uvm_info ("TOP","VIF SET BY CONFIG DB",UVM_LOW)
       run_test("axi_test");
       
     end
     
     initial begin
      clk = 0;
       forever #5 clk = ~clk;
     end
     
     initial begin
       $dumpfile("axi.vcd");
       $dumpvars(0,top);
     end
     
   endmodule        ////////////////////////////////////////////////////////////