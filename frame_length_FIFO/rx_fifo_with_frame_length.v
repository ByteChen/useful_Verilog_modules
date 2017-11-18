//-----------------------------------------------------------------------------
// Title      : EthernetAXI-Streaming FIFO
// Project    : 10G Gigabit Ethernet
//-----------------------------------------------------------------------------
// File       : axi_10g_ethernet_0_axi_fifo.v
// Author     : Xilinx Inc. &&  ByteChen
//-----------------------------------------------------------------------------
// Description: This is the AXI-Streaming fifo for the client loopback design
//              example of the 10G Gigabit Ethernet core
//
//              The FIFO is created from Block RAMs and can be chosen to of
//              size (in 8 bytes words) 512, 1024(外面的不行了 2048, 4096, 8192, or 2048.）
//
//              Frame data received from the write side is written into the
//              data field of the BRAM on the wr_axis_aclk. Start of Frame ,
//              End of Frame and a binary encoded strobe signal (indicating the
//              number of valid bytes in the last word of the frame) are
//              created and stored in the parity field of the BRAM
//
//              The wr_axis_tlast and wr_axis_tuser signals are used to qualify
//              the frame.  A frame for which wr_axis_tuser was not asserted
//              when wr_axis_tlast was asserted will cause the FIFO write
//              address pointer to be reset to the base address of that frame.
//              In this way the bad frame will be overwritten with the next
//              received frame and is therefore dropped from the FIFO.
//
//              When there is at least one complete frame in the FIFO,
//              the read interface will be enabled allowing data to be read
//              from the fifo.
//				
//				修改说明：
//				本fifo经过修改，在输出帧时会附带上帧的长度信息。
//				帧在进入fifo时，会计算帧的长度，并存入一个循环队列里。循环队列使用读指针和写指针进行读写。
//				循环队列的最大长度设置成128了，也就是说此FIFO内最多缓存有128个帧。
//				所以呢使用此FIFO时，FIFO_SIZE只能设置成512或者1024，其实也够大了。
//				FIFO_SIZE = 1024时，最多能装 8B*1024/64B = 128个最短帧。所以循环队列的大小正是按照这个上限来设置。
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps

module rx_fifo_with_frame_length #(
   parameter                           FIFO_SIZE = 512,
   parameter                           IS_TX = 0)
  (
   // FIFO write domain
   input                               wr_axis_aresetn,
   input                               wr_axis_aclk,
   input       [63:0]                  wr_axis_tdata,
   input       [7:0]                   wr_axis_tkeep,
   input                               wr_axis_tvalid,
   input                               wr_axis_tlast,
   output                              wr_axis_tready,
   input                               wr_axis_tuser,

   // FIFO read domain
   input                               rd_axis_aresetn,
   input                               rd_axis_aclk,
   output reg  [63:0]                  rd_axis_tdata,
   output reg  [7:0]                   rd_axis_tkeep,
   output reg                          rd_axis_tvalid,
   output reg                          rd_axis_tlast,
   input                               rd_axis_tready,
   
   //modified by bytechen
   output reg [10:0]				   rd_frame_length,

      // FIFO Status Signals
   output reg  [3:0]                   fifo_status,
   output                              fifo_full
   );

   // the address width required is a function of FIFO size

   localparam ADDR_WIDTH = (FIFO_SIZE == 32)    ? 5 :
                           (FIFO_SIZE == 64)    ? 6 :
                           (FIFO_SIZE == 128)   ? 7 :
                           (FIFO_SIZE == 256)   ? 8 :
                           (FIFO_SIZE == 512)   ? 9 :
                           (FIFO_SIZE == 1024)  ? 10 :
                           (FIFO_SIZE == 2048)  ? 11 :
                           (FIFO_SIZE == 4096)  ? 12 :
                           (FIFO_SIZE == 8192)  ? 13 :
                           (FIFO_SIZE == 16384) ? 14 : 14;

   localparam IS_RX = !IS_TX;

   function [ADDR_WIDTH-1:0] gray2bin;
      input [ADDR_WIDTH-1:0]           gray;
      integer                          j;
   begin
      gray2bin[ADDR_WIDTH-1]           = gray[ADDR_WIDTH-1];
      for (j = ADDR_WIDTH-1; j > 0; j = j -1)
         gray2bin[j-1]                 = gray2bin[j] ^ gray[j-1];
   end
   endfunction

   function [3:0] gray2bin4;
      input [3:0]                      gray;
      integer                          j;
   begin
      gray2bin4[3]                     = gray[3];
      for (j = 3; j > 0; j = j - 1)
         gray2bin4[j-1]                = gray2bin4[j] ^ gray[j-1];
   end
   endfunction

   function [ADDR_WIDTH-1:0] bin2gray;
      input [ADDR_WIDTH-1:0]           bin;
      integer                          j;
   begin
      bin2gray[ADDR_WIDTH-1]           = bin[ADDR_WIDTH-1];
      for (j = ADDR_WIDTH-1; j > 0; j = j - 1)
         bin2gray[j-1]                 = bin[j] ^ bin[j-1];
   end
   endfunction

   function [3:0] bin2gray4;
      input [3:0]                      bin;
      integer                          j;
   begin
      bin2gray4[3]                     = bin[3];
      for (j = 3; j > 0; j = j - 1)
         bin2gray4[j-1]                = bin[j] ^ bin[j-1];
   end
   endfunction

   // write clock domain
   reg         [ADDR_WIDTH-1:0]        wr_addr;             // current write address
   reg         [ADDR_WIDTH-1:0]        wr_addr_last;        // store last address for frame drop
   wire        [ADDR_WIDTH-1:0]        wr_rd_addr_gray_sync;  // read address passed to write clock domain

   reg         [ADDR_WIDTH-1:0]        wr_rd_addr;          // rd_addr in wr domain
   wire                                wr_enable;           // write enable
   wire                                wr_enable_ram;       // write enable to ram
   reg                                 wr_fifo_full;        // fifo full
   reg         [63:0]                  wr_data_pipe;        // write data pipelined
   wire        [3:0]                   wr_ctrl_pipe;        // contains SOF, EOF and Remainder information for the frame: stored in the parity bits of BRAM.
   reg                                 wr_store_frame;      // decision to keep the previous received frame
   reg                                 wr_store_frame_reg;  // wr_store_frame pipelined
   reg                                 wr_store_frame_tog = 0;  // toggle everytime a frame is kept: this crosses onto the read clock domain
   reg         [2:0]                   wr_rem;              // Number of bytes valid in last word of frame encoded as a binary remainder
   reg                                 wr_eof;              // asserted with the last word of the frame

   reg                                 eof_before_fifo_full_seen;

   // read clock domain
   reg         [ADDR_WIDTH-1:0]        rd_addr;             // current read address
   wire        [ADDR_WIDTH-1:0]        rd_addr_gray;        // read address grey encoded
   reg         [ADDR_WIDTH-1:0]        rd_addr_gray_reg;    // read address grey encoded
   reg         [ADDR_WIDTH-2:0]        rd_frames;           // A count of the number of frames currently stored in the FIFO

   wire                                rd_store_frame_sync; // register wr_store_frame_tog a 2nd time
   reg                                 rd_store_frame_sync_del = 0; // register wr_store_frame_tog a 2nd time
   reg                                 rd_store_frame;      // edge detector for wr_store_frame_tog
   reg                                 rd_enable;           // read enable
   wire                                rd_enable_ram;       // read enable
   wire        [63:0]                  rd_data;             // data word output from BRAM
   wire        [3:0]                   rd_ctrl;             // data control output from BRAM parity (contains SOF, EOF and Remainder information for the frame)
   reg                                 rd_avail;            // there is at least 1 frame stored in the FIFO
   reg         [2:0]                   rd_state;            // frame read state machine
   reg         [2:0]                   rd_state_d1;         // 1-clk delayed version of the frame read state machine
   reg                                 rd_stall = 0;

   reg         [ADDR_WIDTH-1:0]        wr_addr_diff;        // the difference between read and write address
   wire        [ADDR_WIDTH-1:0]        wr_addr_diff_comb;   // the difference between read and write address
   wire        [ADDR_WIDTH-1:0]        wr_addr_diff_2s_comp; // 2s complement of read/write diff

   wire                                dst_rdy_in;
   wire                                sof;
   reg                                 wr_axis_tlast_reg = 0;
   reg                                 wr_axis_tvalid_prev = 0;
   wire                                wr_axis_tvalid_detected;
   wire                                reset_wr_addr;
   reg                                 ignore_frame = 0;
   reg                                 drop_frame = 0;
   reg                                 clear_rem  = 0;
   
   //ByteChen's signals
   reg rd_ctrl_reg;
   //reg rd_tlast_reg;

   wire                                axis_areset;
   wire                                wr_sreset;
   wire                                rd_sreset;

   assign dst_rdy_in                   = rd_axis_tready;
   assign sof                       = ((wr_axis_tlast_reg && wr_axis_tvalid) || wr_axis_tvalid_detected);

   assign wr_axis_tvalid_detected   = (!wr_axis_tvalid_prev && wr_axis_tvalid && !wr_axis_tlast);


   always @(posedge wr_axis_aclk)
   begin
      wr_axis_tvalid_prev <= wr_axis_tvalid;
   end

   always @(posedge wr_axis_aclk)
   begin
      if (wr_axis_tlast)
         wr_axis_tlast_reg <= 1;
      else
         wr_axis_tlast_reg <= 0;
   end

   always @(posedge wr_axis_aclk)
   begin
      if (wr_fifo_full) begin
         ignore_frame <= 1;
      end
      else if (sof && !wr_fifo_full) begin
         ignore_frame <= 0;
      end
   end

   assign reset_wr_addr = (ignore_frame && sof && IS_RX);

   always @(posedge wr_axis_aclk)
   begin
      if (sof) begin
         drop_frame <= 0;
      end
      else if (wr_fifo_full && IS_RX) begin
         drop_frame <= 1;
      end
   end

   assign axis_areset                  = !wr_axis_aresetn || !rd_axis_aresetn;

   axi_10g_ethernet_0_sync_reset wr_reset_gen (
      .reset_in                        (axis_areset),
      .clk                             (wr_axis_aclk),
      .reset_out                       (wr_sreset)
   );

   axi_10g_ethernet_0_sync_reset rd_reset_gen (
      .reset_in                        (axis_areset),
      .clk                             (rd_axis_aclk),
      .reset_out                       (rd_sreset)
   );

   //--------------------------------------------------------------------
   // FIFO Read domain
   //----------------------------------------------------------------------

   // Edge detector to register that a new frame was written into the
   // FIFO.
   // NOTE: wr_store_frame_tog crosses clock domains from FIFO write
   axi_10g_ethernet_0_sync_block rd_store_sync (
      .data_in                         (wr_store_frame_tog),
      .clk                             (rd_axis_aclk),
      .data_out                        (rd_store_frame_sync)
   );

   always@(posedge rd_axis_aclk)
   begin
      rd_store_frame_sync_del          <= rd_store_frame_sync;
   end

   always@(posedge rd_axis_aclk)
   begin
      // edge detector
      if (rd_store_frame_sync ^ rd_store_frame_sync_del) begin
         rd_store_frame                <= 1'b1;
      end
      else begin
         rd_store_frame                <= 1'b0;
      end
   end

   // Up/Down counter to monitor the number of frames stored within the
   // the FIFO. Note:
   //    * decrements at the beginning of a frame read cycle
   //    * increments at the end of a frame write cycle
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         rd_frames                     <= 0;
      else begin
         // A frame has been written into the FIFO
         if (rd_store_frame == 1'b1) begin
            if (rd_state == 3'b010 || (rd_state_d1 == 3'b100 && rd_state == 3'b011)) begin
               // one in, one out = no change
               rd_frames               <= rd_frames;
            end
            else begin
               if (&rd_frames != 1'b1)  // if we max out error!
                  rd_frames            <= rd_frames + 1;
            end
         end
         else begin  // A frame is about to be read out of the FIFO
            if (rd_state == 3'b010 || (rd_state_d1 == 3'b100 && rd_state == 3'b011)) // one out = take 1
               if (|rd_frames != 1'b0) // if we bottom out error!
                  rd_frames            <= rd_frames - 1;
         end
      end
   end

   // Data is available if there is at leat one frame stored in the FIFO.
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         rd_avail                      <= 1'b0;
      else begin
         if (|rd_frames != 1'b0)
            rd_avail                   <= 1'b1;
         else
            rd_avail                   <= 1'b0;
      end
   end

   // Read State Machine: to run through the frame read cycle.
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         rd_state                      <= 3'b000;
      else begin
         case (rd_state)
            // Idle state
            3'b000: begin
               // check for at least 1 frame stored in the FIFO:
               if (rd_avail == 1'b1)
                  rd_state             <= 3'b001;
            end

            // Read Initialisation 1: read 1st frame word out of FIFO
            3'b001:
               rd_state                <= 3'b010;

            // Read Initialisation 2: 1st word and SOF are registered onto
            //                        read whilst 2nd word is fetched
            3'b010:
               rd_state                <= 3'b011;

            // Frame Read in Progress
            3'b011: begin
               // detect the end of the frame
               if ((dst_rdy_in == 1'b1) && (rd_ctrl[3] == 1'b1))
                  rd_state             <= 3'b100;
            end
            // End of Frame Read: EOF is driven onto read interface
            3'b100: begin
               if (dst_rdy_in == 1'b1) begin // wait until EOF is sampled
                  if (rd_avail == 1'b1) begin // frame is waiting
                     if (IS_TX)
                        rd_state           <= 3'b011; 
                     else
                        rd_state           <= 3'b010; 
                  end
                  else                    // go to Idle state
                    rd_state           <= 3'b000;
               end
            end
            default:
               rd_state                <= 3'b000;
         endcase
      end
   end

   // Generate 1-clk delayed version of the RD FSM state variable
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1) begin
        rd_state_d1 <= 3'b000;
      end
      else begin
        rd_state_d1 <= rd_state;
      end 
   end   
     
   // Read Enable signal based on Read State Machine 
   always @(*)
   begin
      // assert read enable during preread cycles
      if (rd_state == 3'b001 || rd_state == 3'b010) begin
         rd_enable                  = 1'b1;
      end
      // remain asserted in "011" if no eof and another frame is NOT available
      else if (rd_state == 3'b011 && dst_rdy_in == 1'b1 && (rd_ctrl[3] == 1'b0 || rd_avail == 1'b1)) begin
         rd_enable                  = 1'b1;
      end
      // if in EOF state "100" then remain asserted if another frame is available
      else if (rd_state == 3'b100 && rd_avail == 1'b1 && dst_rdy_in == 1'b1) begin
         rd_enable                  = 1'b1;
      end
      else begin
         rd_enable                  = 1'b0;
      end
   end                                           
	
   assign rd_enable_ram             = (rd_state == 3'b001 || rd_state == 3'b010 ||   // Read Initialisation States
                                          (rd_state == 3'b011 && dst_rdy_in == 1'b1) ||
                                          (rd_state == 3'b100 && rd_avail == 1'b1
                                           && dst_rdy_in == 1'b1)) ? 1'b1 : 1'b0;

   // Create the Read Address Pointer
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         rd_addr                       <= 0;
      else begin
         if (rd_enable == 1'b1)
            rd_addr                    <= rd_addr + 1;
      end
   end

   // If the read enable is not dropped as data is available then hold to ensure tvalid is not dropped
   always @(posedge rd_axis_aclk)
   begin
      if (rd_state == 3'b010 || (rd_state_d1 == 3'b100 && rd_state == 3'b011))
         rd_stall                      <= 1'b0;
      else if (rd_state == 3'b011 && dst_rdy_in == 1'b1 && rd_ctrl[3] == 1'b1 && rd_avail == 1'b0) begin
         rd_stall                      <= 1'b1;
      end
   end

   // Create the AXI-S Output Packet Signals
   always @(posedge rd_axis_aclk)
   begin
	  if (rd_sreset == 1'b1) begin
         rd_axis_tdata                 <= 32'h00000000;
         rd_axis_tkeep                 <= 8'b00000000;
         rd_axis_tlast                 <= 1'b0;
      end
      else begin
         if (rd_state == 3'b010 || ((rd_state != 3'b000) && (dst_rdy_in == 1'b1))) begin
            // pipeline appropriately for registered read
            rd_axis_tdata              <= rd_data;

            // The remainder is encoded into rd_ctrl[2:0]
            case(rd_ctrl[2:0])
               3'b000: rd_axis_tkeep   <= 8'b00000001;
               3'b001: rd_axis_tkeep   <= 8'b00000011;
               3'b010: rd_axis_tkeep   <= 8'b00000111;
               3'b011: rd_axis_tkeep   <= 8'b00001111;
               3'b100: rd_axis_tkeep   <= 8'b00011111;
               3'b101: rd_axis_tkeep   <= 8'b00111111;
               3'b110: rd_axis_tkeep   <= 8'b01111111;
               3'b111: rd_axis_tkeep   <= 8'b11111111;
            endcase

            // The EOF is encoded into rd_ctrl[3]
            if (rd_state == 3'b011)
               rd_axis_tlast           <= rd_ctrl[3];
            else
               rd_axis_tlast           <= 1'b0;
         end
      end
   end

   // Create the AXI-S Valid Signal
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         rd_axis_tvalid                <= 1'b0;
      else begin  // Assert during Read Initialisation 2 state (when SOF is driven onto read interface)
         if (rd_state == 3'b010 || (rd_state_d1 == 3'b100 && rd_state == 3'b011))
            rd_axis_tvalid             <= 1'b1;

         // Remove on End of Frame Read state
         else begin
            if (rd_state == 3'b100 && dst_rdy_in == 1'b1 && rd_stall == 1'b1)
               rd_axis_tvalid          <= 1'b0;
         end
      end
   end

    // Take the Read Address Pointer and convert it into a grey code
   assign rd_addr_gray                 = bin2gray(rd_addr);

   // register the Read Address Pointer gray code
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         rd_addr_gray_reg              <= 0;
      else
         rd_addr_gray_reg              <= rd_addr_gray;
   end



   //--------------------------------------------------------------------
   // FIFO Write Domain
   //--------------------------------------------------------------------

   // Resync the Read Address Pointer grey code onto the write clock
   // NOTE: rd_addr_gray signal crosses clock domains
   genvar i;
   generate
   for (i=0; i<ADDR_WIDTH; i=i+1) begin : GRAY_SYNC

      axi_10g_ethernet_0_sync_block sync_gray_addr (
         .data_in                      (rd_addr_gray_reg[i]),
         .clk                          (wr_axis_aclk),
         .data_out                     (wr_rd_addr_gray_sync[i])
      );

   end
   endgenerate

   // Convert the resync'd Read Address Pointer grey code back to binary
   always @(posedge wr_axis_aclk)
   begin
      wr_rd_addr                       <= gray2bin(wr_rd_addr_gray_sync);
   end

   // Obtain the difference between write and read pointers
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1)
         wr_addr_diff                  <= 0;
      else
         wr_addr_diff                  <= wr_rd_addr - wr_addr;
   end

   assign wr_addr_diff_comb            = (wr_rd_addr - wr_addr);

   //--------------------------------------------------------------------
   // Create FIFO Status Signals in the Read Domain
   //--------------------------------------------------------------------

   // The FIFO status signal is four bits which represents the occupancy
   // of the FIFO in 16'ths.  To generate this signal take the 2's
   // complement of the difference between the read and write address
   // pointers and take the top 4 bits.

   assign wr_addr_diff_2s_comp         = (~(wr_addr_diff) + 1);

   // Register the top 4 bits to create the fifo status
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1)
         fifo_status                   <= 0;
      else
         fifo_status                   <= wr_addr_diff_2s_comp[ADDR_WIDTH-1:ADDR_WIDTH-4];
   end

   // Detect when the FIFO is full
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1)
         wr_fifo_full                  <= 1'b0;
      else begin
         //At the end of the frame FIFO will never be full since the
         //frame will be dropped if it's already full
         if (wr_axis_tlast==1'b1 && (IS_RX)) begin
            wr_fifo_full               <= 1'b0;
         end
         else begin
            // The FIFO is considered to be full if the write address
            // pointer is within 1 to 3 of the read address pointer.
            if (wr_addr_diff_comb[ADDR_WIDTH-1:3] == 0 &&
               wr_addr_diff_comb[2:0] != 3'b000) begin
               wr_fifo_full            <= 1'b1;
            end
            else begin
               // We hold the full signal until the end of frame reception
               // to guarantee that this frame will be dropped.
               if (IS_TX||wr_axis_tlast==1'b1)
                  wr_fifo_full         <= 1'b0;
            end
         end
      end
   end

   assign fifo_full                    = wr_fifo_full;
   assign wr_axis_tready               = ~wr_fifo_full;

   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1)
         eof_before_fifo_full_seen     <= 1'b0;
      else if (wr_rd_addr == (wr_addr_last - 1))
         eof_before_fifo_full_seen     <= 1'b0;
      else if (wr_eof&&wr_fifo_full==1'b0) //wr_axis_tvalid &&
         eof_before_fifo_full_seen     <= 1'b1;
   end

   // Create the Write Address Pointer
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1)
         wr_addr                       <= 0;
      else begin
         // If the received frame contained an error, it will be over-
         // written: reload the starting address for that frame
         if ((wr_axis_tlast== 1'b1 && wr_fifo_full == 1'b1 && (IS_RX)) ||
             (wr_axis_tlast== 1'b1 && wr_axis_tuser==1'b0) ||
             (eof_before_fifo_full_seen== 1'b0 && wr_fifo_full == 1'b1) || reset_wr_addr) begin
            wr_addr                    <= wr_addr_last;
         end
         // increment write pointer as frame is written.
         else if (wr_enable_ram == 1'b1) begin
            wr_addr                    <= wr_addr + 1;
         end
      end
   end

   // Record the starting address of a new frame in case it needs to be
   // overwritten
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1)
         wr_addr_last                  <= 0;
      else if (wr_store_frame_reg == 1'b1)
         wr_addr_last                  <= wr_addr;
   end

   // Write Enable signal based on write signals and FIFO status
   assign wr_enable                    = (wr_axis_tkeep[0] && wr_axis_tvalid && !wr_fifo_full) ? 1'b1 : 1'b0;



   // At the end of frame reception, decide whether to keep the frame or
   // to overwrite it with the next.
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1) begin
         wr_store_frame                <= 1'b0;
         wr_store_frame_reg            <= 1'b0;
      end
      else begin
         wr_store_frame_reg            <= wr_store_frame && !drop_frame && !wr_fifo_full;

         // Error free frame is received and has fit in the FIFO: keep
         if (wr_axis_tuser == 1'b1 && wr_axis_tvalid == 1'b1 && wr_fifo_full == 1'b0 && !drop_frame) begin
            wr_store_frame             <= 1'b1;
         end
         // Error free frame is received but does not fit in FIFO or
         // an error-ed frame is received: discard frame
         else if ((wr_axis_tlast == 1'b1 && wr_fifo_full == 1'b1) ||
                  (wr_axis_tlast == 1'b1 && wr_axis_tuser==1'b0) || drop_frame) begin
            wr_store_frame             <= 1'b0;
         end
         else begin
            wr_store_frame             <= 1'b0;
         end
      end
   end

   always @(posedge wr_axis_aclk)
   begin
      // Error free frame is received and has fit in the FIFO: keep
      if (wr_axis_tuser == 1'b1 && wr_axis_tvalid == 1'b1 && wr_fifo_full == 1'b0 && !drop_frame) begin
         wr_store_frame_tog            <= !wr_store_frame_tog;
      end
   end

   // Pipeline the data and control signals to BRAM
   always @(posedge wr_axis_aclk)
   begin
      if (wr_sreset == 1'b1) begin
         wr_data_pipe                  <= 0;
         wr_rem                        <= 3'b0;
         wr_eof                        <= 1'b0;
         clear_rem                     <= 1'b0;
      end
      else begin
         // pipeline write enable
         // End of frame is indicated by the tlast signal
         wr_eof                        <= wr_axis_tlast & wr_axis_tuser & wr_axis_tvalid &
                                          (IS_RX || !wr_fifo_full);
         // signal used to ensure rem is cleared at the end of a good or bad frame
         clear_rem                     <= wr_axis_tlast & wr_axis_tvalid &
                                          (IS_RX || !wr_fifo_full);
         //Hold the last data beat untill the last signal is received
         if(wr_enable) begin
            wr_data_pipe               <= wr_axis_tdata;

            // Encode the data valid signals as a binary remainder:
            // wr_axis_tkeep   wr_rem
            // -----------//   ------
            // 0x00000001      000
            // 0x00000011      001
            // 0x00000111      010
            // 0x00001111      011
            // 0x00011111      100
            // 0x00111111      101
            // 0x01111111      110
            // 0x11111111      111
            wr_rem[2]                  <= wr_axis_tkeep[4];

            case (wr_axis_tkeep)
               8'b00000001, 8'b00011111 :
                  wr_rem[1:0]          <= 2'b00;
               8'b00000011, 8'b00111111 :
                  wr_rem[1:0]          <= 2'b01;
               8'b00000111, 8'b01111111 :
                  wr_rem[1:0]          <= 2'b10;
               default:
                  wr_rem[1:0]          <= 2'b11;
            endcase
         end
         else if (clear_rem) begin
            wr_rem                     <= 3'b000;
         end
      end
   end

   assign wr_enable_ram             = (wr_rem==3'b111 & wr_enable)|(wr_eof);

   // This signal, stored in the parity bits of the BRAM, contains
   // EOF and Remainder information for the stored frame:
   // wr_ctrl[3]    = EOF
   // wr_ctrl([2:0] = remainder
   // Note that remainder is only valid when EOF is asserted.

   assign wr_ctrl_pipe                 = {wr_eof,wr_rem};

   
   
   //--------------------------------------------------------------------
   // //计算帧长并存储也转发
   //--------------------------------------------------------------------

   //计算帧长
   reg [10:0] frame_len = 11'd0;
   reg [ADDR_WIDTH-1:0]  previous_wr_addr = 0;
   
   always @(posedge wr_axis_aclk)
	if (sof)
		previous_wr_addr <= wr_addr;

   always @(posedge wr_axis_aclk)
   begin
	if (wr_sreset == 1'b1) 
		frame_len <= 11'd0;
	else if(wr_eof)
		begin
			if(wr_addr > previous_wr_addr)
				frame_len <= (wr_addr - previous_wr_addr)*8 + wr_rem + 1 + 4;	//最后加4是FCS，或许不加比较恰当，因为交换内部无FCS
			else
				frame_len <= (wr_addr + FIFO_SIZE - previous_wr_addr)*8 + wr_rem + 1 + 4;
		end
   end
   
   
   //写入循环队列，要求FIFO内缓存的帧数不超过 队列长度128
   reg [127:0]  row0;
   reg [127:0]  row1;
   reg [127:0]  row2;
   reg [127:0]  row3;
   reg [127:0]  row4;
   reg [127:0]  row5;
   reg [127:0]  row6;
   reg [127:0]  row7;
   reg [127:0]  row8;
   reg [127:0]  row9;
   reg [127:0] row10;
   
   reg wr_eof_reg = 1'b0;
      always @(posedge wr_axis_aclk)
      begin
           if(wr_sreset == 1'b1) 
               wr_eof_reg    <=    1'b0;
           else
               wr_eof_reg    <=    wr_eof;
      end
      
      reg wr_eof_reg_reg = 1'b0;
      always @(posedge wr_axis_aclk)
      begin
           if(wr_sreset == 1'b1) 
               wr_eof_reg_reg    <=    1'b0;
           else
               wr_eof_reg_reg    <=    wr_eof_reg;
      end
	  
	  
	  reg wr_store_frame_reg_reg;
	  always @(posedge wr_axis_aclk)
      begin
           if(wr_sreset == 1'b1) 
               wr_store_frame_reg_reg    <=    1'b0;
           else
               wr_store_frame_reg_reg    <=    wr_store_frame_reg;
      end
      
   reg [6:0] write_pointer;
   
   always @(posedge wr_axis_aclk)
   begin
		if(wr_sreset == 1'b1)
			write_pointer <= 7'd0;
		//else if(wr_eof_reg_reg)
		else if(wr_eof_reg_reg & wr_store_frame_reg_reg)
			begin
				if(write_pointer == 7'd127)
					write_pointer	<= 	7'd0;
				else
					write_pointer	<= 	write_pointer + 1;
			end
   end
   
   always @(posedge wr_axis_aclk)
	begin
		if (wr_sreset == 1'b1) 
		begin
			 row0	<= 	16'd0;
			 row1	<= 	16'd0;
			 row2	<= 	16'd0;
			 row3	<= 	16'd0;
			 row4	<= 	16'd0;
			 row5	<= 	16'd0;
			 row6	<= 	16'd0;
			 row7	<= 	16'd0;
			 row8	<= 	16'd0;
			 row9	<= 	16'd0;
			row10	<= 	16'd0;
		end
		
		//else if(wr_eof_reg)
		else if(wr_eof_reg & wr_store_frame_reg)
		begin
			row0[write_pointer]	    <=	frame_len[0]   ;
			row1[write_pointer]     <=	frame_len[1]   ;
			row2[write_pointer]     <=	frame_len[2]   ;
			row3[write_pointer]     <=	frame_len[3]   ;
			row4[write_pointer]     <=	frame_len[4]   ;
			row5[write_pointer]     <=	frame_len[5]   ;
			row6[write_pointer]     <=	frame_len[6]   ;
			row7[write_pointer]     <=	frame_len[7]   ;
			row8[write_pointer]     <=	frame_len[8]   ;
			row9[write_pointer]     <=	frame_len[9]   ;
		   row10[write_pointer]     <= frame_len[10]   ;
		end
	end		//完成写入队列
	
	
	/************************ 将帧长与帧一起往外传  ***************************/
	always @(posedge rd_axis_aclk)
		if(rd_sreset == 1'b1)
			rd_ctrl_reg 	<= 1'b0;
		else
			rd_ctrl_reg		<= rd_ctrl[3];
	/*
	always @(posedge rd_axis_aclk)
		if(rd_sreset == 1'b1)
			rd_tlast_reg 	<= 1'b0;
		else
			rd_tlast_reg	<= rd_axis_tlast;
	*/
	
	//更新读pointer
   reg [6:0] read_pointer;
   always @(posedge rd_axis_aclk)
   begin
		if(rd_sreset == 1'b1)
			read_pointer <= 7'd0;
		//else if(rd_state == 3'b011 && rd_ctrl[3] == 1'b1)
		//else if(rd_state_d1 == 3'b011 && rd_ctrl_reg == 1'b1)
		//else if(rd_ctrl[3] == 1'b1)	//这样差不多好了，但有瑕疵
		else if(rd_ctrl[3] == 1'b1 && rd_ctrl_reg != 1'b1)
			begin
				if(read_pointer == 7'd127)
					read_pointer	<= 	7'd0;
				else
					read_pointer	<= 	read_pointer + 1;
			end
   end
   
   
   always @(posedge rd_axis_aclk)
   begin
      if (rd_sreset == 1'b1)
         begin
				rd_frame_length[0]          <=		1'b0;	
				rd_frame_length[1]          <=		1'b0;	
				rd_frame_length[2]          <=		1'b0;	
				rd_frame_length[3]          <=		1'b0;	
				rd_frame_length[4]          <=		1'b0;	
				rd_frame_length[5]          <=		1'b0;	
				rd_frame_length[6]          <=		1'b0;	
				rd_frame_length[7]          <=		1'b0;	
				rd_frame_length[8]          <=		1'b0;	
				rd_frame_length[9]          <=		1'b0;	
			   rd_frame_length[10]          <=		1'b0;	
		 end
      else begin  // Assert during Read Initialisation 2 state (when SOF is driven onto read interface)
         if (rd_state == 3'b100 || rd_state == 3'b010 || (rd_state_d1 == 3'b100 && rd_state == 3'b011))
           begin
				rd_frame_length[0]          <=				row0[read_pointer]  ;
				rd_frame_length[1]          <=				row1[read_pointer]  ;
				rd_frame_length[2]          <=				row2[read_pointer]  ;
				rd_frame_length[3]          <=				row3[read_pointer]  ;
				rd_frame_length[4]          <=				row4[read_pointer]  ;
				rd_frame_length[5]          <=				row5[read_pointer]  ;
				rd_frame_length[6]          <=				row6[read_pointer]  ;
				rd_frame_length[7]          <=				row7[read_pointer]  ;
				rd_frame_length[8]          <=				row8[read_pointer]  ;
				rd_frame_length[9]          <=				row9[read_pointer]  ;
			   rd_frame_length[10]          <=			   row10[read_pointer]  ;
		   end

         // Remove on End of Frame Read state
         else begin
            if (rd_state == 3'b100 && dst_rdy_in == 1'b1 && rd_stall == 1'b1)
               begin
			   		rd_frame_length[0]          <=		1'b0;	
			   		rd_frame_length[1]          <=		1'b0;	
			   		rd_frame_length[2]          <=		1'b0;	
			   		rd_frame_length[3]          <=		1'b0;	
			   		rd_frame_length[4]          <=		1'b0;	
			   		rd_frame_length[5]          <=		1'b0;	
			   		rd_frame_length[6]          <=		1'b0;	
			   		rd_frame_length[7]          <=		1'b0;	
			   		rd_frame_length[8]          <=		1'b0;	
			   		rd_frame_length[9]          <=		1'b0;	
			   	   rd_frame_length[10]          <=		1'b0;	
			   end
         end
      end
   end
   

   //--------------------------------------------------------------------
   // Instantiate BRAMs to produce the dual port memory
   //--------------------------------------------------------------------

   axi_10g_ethernet_0_fifo_ram #(ADDR_WIDTH) fifo_ram_inst
   (
      .wr_clk                          (wr_axis_aclk),
      .wr_addr                         (wr_addr),
      .data_in                         (wr_data_pipe),
      .ctrl_in                         (wr_ctrl_pipe),
      .wr_allow                        (wr_enable_ram),
      .rd_clk                          (rd_axis_aclk),
      .rd_sreset                       (rd_sreset),
      .rd_addr                         (rd_addr),
      .data_out                        (rd_data),
      .ctrl_out                        (rd_ctrl),
      .rd_allow                        (rd_enable_ram)
   );

endmodule
