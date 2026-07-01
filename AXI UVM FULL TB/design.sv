// Code your design here
import uvm_pkg::*;
`include "uvm_macros.svh"

  //-------------------------
 module axi_slave_dut (axi_if vif);
  
  //DUT specific reg/variables
  
  reg [31:0] mem [512]; //main storage
  reg [31:0] dut_awaddr;
  reg [7:0]  dut_awlen;
  reg [1:0]  dut_awsize;
  typedef enum {FIXED,INCR,WRAP}dut_burst_t;
  dut_burst_t dut_awburst;
  
  reg [31:0] dut_araddr;
  reg [7:0] dut_arlen;
  reg [1:0] dut_arsize;
  dut_burst_t dut_arburst;
  
  int  r_count; //for rdata ref.
  typedef enum {OKAY,EXOKAY,SLVERR,DECERR} resp_t;
  bit ar_handshake;
  reg [31:0] l_wrap;  
  reg [31:0] u_wrap;
  reg [31:0] start_addr; //interface addr
  reg [31:0] total_bytes; //beats*bytes
  

  //-------------------------
  //for AW channel
  //-------------------------
  
  always @(posedge vif.clk or posedge vif.reset) begin
    
    if(vif.reset)
      mem<='{default : 0};
    else
      if(vif.awvalid) begin
        vif.awready<=1;
        `uvm_info ("DUT","AWREADY=1",UVM_LOW)
        
        dut_awaddr <=(vif.awaddr);
        start_addr <=vif.awaddr; //for WRAP
        
        if(vif.awaddr>$size(mem))
          `uvm_warning("DUT","MEM DOES NOT HAVE THIS AWADDR")
        
        dut_awlen  <= vif.awlen;
        dut_awsize <= vif.awsize;
        dut_awburst <= vif.awburst;
        total_bytes <= (2**vif.awsize)*(vif.awlen+1); //for WRAP
        
        `uvm_info ("DUT",$sformatf("GOT AW SIGNALS, total_bytes = %0h, dut_awsize =%0h, dut_awlen = %0h",total_bytes,dut_awsize,dut_awlen),UVM_LOW)
        
        @(posedge vif.clk);
        vif.awready<=0;
      end
  end
  
  //-------------------------
  //for AR channel
  //-------------------------
  
  always @(posedge vif.clk or posedge vif.reset) begin
    
    if(vif.reset)
      mem<='{default : 0};
    else
      if(vif.arvalid) begin
        vif.arready<=1;
        `uvm_info ("DUT","ARREADY=1",UVM_LOW)
        dut_araddr <=vif.araddr;
        if(vif.araddr>$size(mem))
          `uvm_warning("DUT","MEM DOES NOT HAVE THIS ARADDR")
        
        dut_arlen  <=vif.arlen;        
        dut_arsize <=vif.arsize;
        dut_arburst <=vif.arburst;
        `uvm_info ("DUT","GOT AR SIGNALS",UVM_LOW)
        @(posedge vif.clk);
        vif.arready<=0;
        ar_handshake = 1;
      end
  end
  
  //-------------------------
  //for WDATA channel
  //-------------------------
  always @(negedge vif.clk or posedge vif.reset) begin //1
    `uvm_info ("DUT","INSIDE WDATA CHANNEL",UVM_HIGH)
    if(vif.reset)
      mem<='{default : 0};
    
    else begin //2
      if(vif.wvalid) begin //3
        `uvm_info ("DUT","WVALID=1",UVM_HIGH)
        vif.wready<=1;
        `uvm_info ("DUT","WREADY=1",UVM_LOW)
        
      // ____>>>>>>>>>>>>>>   FOR WRAP  <<<<<<<<---------
        
      // Calculate lower wrap and upper wrap boundary before writing into memory
      // IF the write address reached upper wrap boundary, wrap to lower boundary
        
      if(dut_awburst==WRAP) begin
        l_wrap = int'(start_addr/total_bytes)*total_bytes;
        u_wrap = l_wrap + (total_bytes-1); //2F
       
        if(dut_awaddr>=u_wrap) begin
          dut_awaddr = l_wrap; end
      end
        
      // Write data into the byte addressable memory according to the WSTRB
        
      for(int i=0;i<4;i++) begin
        if (vif.wstrb[i]) begin
          
          mem[dut_awaddr >> 2] [8*i +: 8] = vif.wdata[8*i +: 8];
          `uvm_info("DUT MEM",$sformatf("%0d th bit of wstrb & %0d byte of wdata written at mem[awaddr]=%0h formula print vif.wdata[8*(%0d)+:8]=%0h",i,i,mem[dut_awaddr],i,vif.wdata[8*i +: 8]),UVM_HIGH)
        end
      end
       
      if (dut_awburst != FIXED) begin
          dut_awaddr = dut_awaddr + 4;
      end
        
        `uvm_info("DUT WRAP",$sformatf ("total bytes = %0h l_wrap = %0h u_wrap=%0h dut_awaddr = %0d",total_bytes,l_wrap,u_wrap,dut_awaddr),UVM_LOW)
      
        
      if(vif.wlast) begin
        @(posedge vif.clk); // add posedge
        vif.wready<=0;
        `uvm_info ("DUT","WLAST=1 and WREADY=0",UVM_LOW)
      end
        
      end //3  
    end //2
    
  end
  
  //-------------------------
  //B-Response channel
  //-------------------------
  always @(negedge vif.clk or posedge vif.reset) begin //1
    
    if(vif.reset)
      mem<='{default : 0};
    
    else begin //2
      
      if(vif.wlast) begin //3
        @(posedge vif.clk);
        vif.bvalid<=1;
        
        vif.bresp<=OKAY;
        `uvm_info ("DUT","BRESP SENT",UVM_LOW)//155
        @(posedge vif.clk);
        wait(!vif.bready);
        vif.bvalid<=0;
        vif.bresp<='hx;
      end //3
    end//2
  end//1
  
  //-------------------------
  //R- read data+resp channel
  //----------------------------------
  
  always @(negedge vif.clk or posedge vif.reset) begin //1
    
    if(vif.reset)
      mem<='{default : 0};
    
    else begin //2
      if (ar_handshake) begin
      `uvm_info ("DUT","AR HANDSHAKE DONE",UVM_LOW)
      @(posedge vif.clk);
      vif.rvalid<=1;
      `uvm_info ("DUT","RVALID=1",UVM_LOW)
      wait(vif.rready == 1);
       `uvm_info ("DUT","wait over for vif.rready=1",UVM_LOW) 
        
        case(dut_arsize)
          
          0: begin vif.rdata <= mem[dut_araddr>>2][7:0];
            `uvm_info ("DUT","1 byte read",UVM_LOW)end
          1: begin vif.rdata <= mem[dut_araddr>>2][15:0];
            `uvm_info ("DUT","2 byte read",UVM_LOW)end
          2: begin vif.rdata <= mem[dut_araddr>>2][31:0];
            `uvm_info ("DUT","4 byte read",UVM_LOW)end
          3: $display("READ:EXCEEDS BUS SIZE");
          
        endcase
        
         vif.rresp<= OKAY;
        `uvm_info ("DUT","RRESP SENT",UVM_LOW)
               
        if(dut_arburst==INCR)
          dut_araddr++;
        
        if(r_count==(dut_arlen)) begin //3
          vif.rlast<=1;
          `uvm_info ("DUT","setting RLAST=1 on vif",UVM_LOW)
           r_count = 0;
          ar_handshake = 0;
          @(posedge vif.clk);
          vif.rlast<=0;
          vif.rvalid<=0;
          vif.rresp<='hx;
      end //3
      else begin
         r_count++;
      end
      	
                    
    end //2
  end //1
  end
endmodule