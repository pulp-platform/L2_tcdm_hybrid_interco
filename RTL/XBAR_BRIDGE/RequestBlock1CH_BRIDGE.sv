// Copyright 2014-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// FOR TWO INPUTS
module RequestBlock1CH_BRIDGE
#(
    parameter ADDR_WIDTH = 32,
    parameter N_CH0      = 16, // Example Number of processors (OR10n, RISCV)
    parameter ID_WIDTH   = N_CH0,
    parameter N_SLAVE    = 16,
    parameter DATA_WIDTH = 32,
    parameter AUX_WIDTH  = 32,
    parameter BE_WIDTH   = DATA_WIDTH/8,
    parameter USE_TEST_SET = "TRUE"    
)
(
    // CHANNEL CH0 --> (example: Used for xP70s)
    input  logic [N_CH0-1:0]                     data_req_CH0_i,
    input  logic [N_CH0-1:0][ADDR_WIDTH-1:0]     data_add_CH0_i,
    input  logic [N_CH0-1:0]                     is_test_and_set_i,
    input  logic [N_CH0-1:0]                     data_wen_CH0_i,
    input  logic [N_CH0-1:0][DATA_WIDTH-1:0]     data_wdata_CH0_i,
    input  logic [N_CH0-1:0][BE_WIDTH-1:0]       data_be_CH0_i,
    input  logic [N_CH0-1:0][ID_WIDTH-1:0]       data_ID_CH0_i,
    input  logic [N_CH0-1:0][AUX_WIDTH-1:0]      data_aux_CH0_i,
    output logic [N_CH0-1:0]                     data_gnt_CH0_o,


    // -----------------             MEMORY                    -------------------
    // ---------------- RequestBlock OUTPUT (Connected to MEMORY) ----------------
    output logic                                 data_req_o,
    output logic                                 data_ts_set_o,
    output logic [ADDR_WIDTH-1:0]                data_add_o,
    output logic                                 data_wen_o,
    output logic [DATA_WIDTH-1:0]                data_wdata_o,
    output logic [BE_WIDTH-1:0]                  data_be_o,
    output logic [ID_WIDTH-1:0]                  data_ID_o,
    output logic [AUX_WIDTH-1:0]                 data_aux_o,
    input  logic                                 data_gnt_i,

    input   logic                                data_r_valid_i,
    input   logic [ID_WIDTH-1:0]                 data_r_ID_i,

    // GEN VALID_SIGNALS in the response path
    output logic [N_CH0-1:0]                     data_r_valid_CH0_o,

    input  logic                                 clk,
    input  logic                                 rst_n
);



    // CHANNEL CH0 --> (example: Used for Processing Elements / CORES)
    logic [2**$clog2(N_CH0)-1:0]                                data_req_CH0_int;
    logic [2**$clog2(N_CH0)-1:0][ADDR_WIDTH:0]                  data_add_CH0_int; // TS,ADDR[31:0]
    logic [2**$clog2(N_CH0)-1:0]                                data_wen_CH0_int;
    logic [2**$clog2(N_CH0)-1:0][DATA_WIDTH-1:0]                data_wdata_CH0_int;
    logic [2**$clog2(N_CH0)-1:0][BE_WIDTH-1:0]                  data_be_CH0_int;
    logic [2**$clog2(N_CH0)-1:0][ID_WIDTH-1:0]                  data_ID_CH0_int;
    logic [2**$clog2(N_CH0)-1:0][AUX_WIDTH-1:0]                 data_aux_CH0_int;
    logic [2**$clog2(N_CH0)-1:0]                                data_gnt_CH0_int;


    logic                                                       data_req_int;
    logic [ADDR_WIDTH:0]                                        data_add_int; //TS,ADDR[31:0] out of the arb tree
    logic                                                       data_wen_int;
    logic [DATA_WIDTH-1:0]                                      data_wdata_int;
    logic [BE_WIDTH-1:0]                                        data_be_int;
    logic [ID_WIDTH-1:0]                                        data_ID_int;
    logic [AUX_WIDTH-1:0]                                       data_aux_int;
    logic                                                       data_gnt_int;

    logic [N_CH0-1:0][ADDR_WIDTH:0]                             data_add_CH0_temp;

      generate

          for(genvar j = 0; j<N_CH0; j++)
          begin
            assign data_add_CH0_temp[j] = {is_test_and_set_i[j],data_add_CH0_i[j]};
          end


            if(2**$clog2(N_CH0) != N_CH0) // if N_CH0 is not power of 2 --> then use power 2 ports
            begin : _DUMMY_CH0_PORTS_

              logic [2**$clog2(N_CH0)-N_CH0 -1 :0]                                data_req_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0][ADDR_WIDTH-1:0]                data_add_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0]                                data_wen_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0][DATA_WIDTH-1:0]                data_wdata_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0][BE_WIDTH-1:0]                  data_be_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0][ID_WIDTH-1:0]                  data_ID_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0][AUX_WIDTH-1:0]                 data_aux_CH0_dummy;
              logic [2**$clog2(N_CH0)-N_CH0 -1 :0]                                data_gnt_CH0_dummy;


              assign data_req_CH0_dummy    = '0 ;
              assign data_add_CH0_dummy    = '0 ;
              assign data_wen_CH0_dummy    = '0 ;
              assign data_wdata_CH0_dummy  = '0 ;
              assign data_be_CH0_dummy     = '0 ;
              assign data_ID_CH0_dummy     = '0 ;
              assign data_aux_CH0_dummy    = '0 ;

              assign data_req_CH0_int      = {  data_req_CH0_dummy  ,     data_req_CH0_i     };
              assign data_add_CH0_int      = {  data_add_CH0_dummy  ,     data_add_CH0_temp  };
              assign data_wen_CH0_int      = {  data_wen_CH0_dummy  ,     data_wen_CH0_i     };
              assign data_wdata_CH0_int    = {  data_wdata_CH0_dummy  ,   data_wdata_CH0_i   };
              assign data_be_CH0_int       = {  data_be_CH0_dummy  ,      data_be_CH0_i      };
              assign data_ID_CH0_int       = {  data_ID_CH0_dummy  ,      data_ID_CH0_i      };
              assign data_aux_CH0_int      = {  data_aux_CH0_dummy  ,     data_aux_CH0_i     };


              for(genvar j=0; j<N_CH0; j++)
              begin : _MERGING_CH0_DUMMY_PORTS_OUT_
                assign data_gnt_CH0_o[j]     = data_gnt_CH0_int[j];
              end


          end
          else // N_CH0 is power of 2
          begin
                assign data_req_CH0_int   = data_req_CH0_i;
                assign data_add_CH0_int   = data_add_CH0_temp;
                assign data_wen_CH0_int   = data_wen_CH0_i;
                assign data_wdata_CH0_int = data_wdata_CH0_i;
                assign data_be_CH0_int    = data_be_CH0_i;
                assign data_ID_CH0_int    = data_ID_CH0_i;
                assign data_aux_CH0_int   = data_aux_CH0_i;
                assign data_gnt_CH0_o     = data_gnt_CH0_int;
          end



        if(N_CH0 > 1) // Means 2 or more MAster, it requires Arbitration Tree and eires between Arb tree and Test and set interface
        begin : POLY_CH0
            ArbitrationTree_BRIDGE
            #(
                .ADDR_WIDTH  ( ADDR_WIDTH+1 ),
                .ID_WIDTH    ( ID_WIDTH     ),
                .N_MASTER    ( 2**$clog2(N_CH0)        ),
                .DATA_WIDTH  ( DATA_WIDTH   ),
                .BE_WIDTH    ( BE_WIDTH     ),
                .AUX_WIDTH   ( AUX_WIDTH    ),
                .MAX_COUNT   ( N_CH0-1      )
            )
            i_ArbitrationTree_BRIDGE
            (
                .clk          ( clk                ),
                .rst_n        ( rst_n              ),

                // INPUTS
                .data_req_i   ( data_req_CH0_int   ),
                .data_add_i   ( data_add_CH0_int   ),
                .data_wen_i   ( data_wen_CH0_int   ),
                .data_wdata_i ( data_wdata_CH0_int ),
                .data_be_i    ( data_be_CH0_int    ),
                .data_ID_i    ( data_ID_CH0_int    ),
                .data_aux_i   ( data_aux_CH0_int   ),
                .data_gnt_o   ( data_gnt_CH0_int   ),

                // OUTPUTS
                .data_req_o   ( data_req_int       ),
                .data_add_o   ( data_add_int       ),
                .data_wen_o   ( data_wen_int       ),
                .data_wdata_o ( data_wdata_int     ),
                .data_be_o    ( data_be_int        ),
                .data_ID_o    ( data_ID_int        ),
                .data_aux_o   ( data_aux_int       ),
                .data_gnt_i   ( data_gnt_int       )
            );
        end
        else
        begin : MONO_CH0
            assign data_req_int   = data_req_CH0_int;
            assign data_add_int   = data_add_CH0_int;
            assign data_wen_int   = data_wen_CH0_int;
            assign data_wdata_int = data_wdata_CH0_int;
            assign data_be_int    = data_be_CH0_int;
            assign data_ID_int    = data_ID_CH0_int;
            assign data_aux_int   = data_aux_CH0_int;
            assign data_gnt_CH0_int = data_gnt_int;
        end


      if(USE_TEST_SET == "TRUE")
      begin : W_TS
        TestAndSet_BRIDGE
        #(
            .ADDR_MEM_WIDTH  ( ADDR_WIDTH      ),//= 12,
            .ID_WIDTH        ( ID_WIDTH        ),//= 20,
            .DATA_WIDTH      ( DATA_WIDTH      ),//= 32,
            .AUX_WIDTH       ( AUX_WIDTH       ),//= 2,
            .BE_WIDTH        ( BE_WIDTH        ) //= DATA_WIDTH/8
        )
        i_TestAndSet_BRIDGE
        (
            .clk            (  clk             ),
            .rst_n          (  rst_n           ),        

            // From Network Side
            .data_req_i        ( data_req_int                  ), // Data request
            .data_add_i        ( data_add_int[ADDR_WIDTH-1:0]  ), // Data request Address + T&S bit
            .is_test_and_set_i ( data_add_int[ADDR_WIDTH]      ),
            .data_wen_i        ( data_wen_int                  ), // Data request type : 0--> Store, 1 --> Load
            .data_wdata_i      ( data_wdata_int                ), // Data request Wrire data
            .data_be_i         ( data_be_int                   ), // Data request Byte enable 
            .data_ID_i         ( data_ID_int                   ), // Data request ID
            .data_aux_i        ( data_aux_int                  ), 
            .data_gnt_o        ( data_gnt_int                  ), // Data Grant --> to Arbitration Tree

            // From Memory Side
            .data_req_o     ( data_req_o                       ),  // Data request
            .data_ts_set_o  ( data_ts_set_o                    ),  // Is test and set operation
            .data_add_o     ( data_add_o                       ),  // Data request Address (No T&S bit here)
            .data_wen_o     ( data_wen_o                       ),  // Data request type : 0--> Store, 1 --> Load
            .data_wdata_o   ( data_wdata_o                     ),  // Data request Wrire data
            .data_be_o      ( data_be_o                        ),  // Data request Byte enable 
            .data_ID_o      ( data_ID_o                        ),
            .data_aux_o     ( data_aux_o                       ),      
            .data_gnt_i     ( data_gnt_i                       )
        );
      end
      else
      begin : WO_TS
          assign data_req_o    = data_req_int;
          assign data_add_o    = data_add_int[ADDR_WIDTH-1:0];
          assign data_wen_o    = data_wen_int;
          assign data_wdata_o  = data_wdata_int;
          assign data_be_o     = data_be_int;
          assign data_ID_o     = data_ID_int;
          assign data_aux_o    = data_aux_int;
          assign data_gnt_int  = data_gnt_i;
      end


    endgenerate

    AddressDecoder_Resp_BRIDGE
    #(
        .ID_WIDTH(ID_WIDTH),
        .N_MASTER(N_CH0)
    )
    i_AddressDecoder_Resp_PE
    (
      // FROM Test And Set Interface
      .data_r_valid_i  ( data_r_valid_i      ),
      .data_ID_i       ( data_r_ID_i         ),
      // To Response Network
      .data_r_valid_o  ( data_r_valid_CH0_o  )
    );



endmodule
