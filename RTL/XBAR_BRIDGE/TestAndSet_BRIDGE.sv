// Copyright 2014-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module TestAndSet_BRIDGE
#(
    parameter ADDR_MEM_WIDTH  = 12,
    parameter ID_WIDTH        = 20,
    parameter DATA_WIDTH      = 32,
    parameter AUX_WIDTH       = 2,
    parameter BE_WIDTH        = DATA_WIDTH/8
)
(
    input  logic                                 clk,
    input  logic                                 rst_n,        

    // From Network Side
    input  logic                                 data_req_i,   // Data request
    input  logic [ADDR_MEM_WIDTH-1:0]            data_add_i,   // Data request Address + T&S bit
    input  logic                                 is_test_and_set_i,

    input  logic                                 data_wen_i,   // Data request type : 0--> Store, 1 --> Load
    input  logic [DATA_WIDTH-1:0]                data_wdata_i, // Data request Wrire data
    input  logic [BE_WIDTH-1:0]                  data_be_i,    // Data request Byte enable 
    input  logic [ID_WIDTH-1:0]                  data_ID_i,    // Data request ID
    input  logic [AUX_WIDTH-1:0]                 data_aux_i, 
    output logic                                 data_gnt_o, // Data Grant --> to Arbitration Tree


    // From Memory Side
    output logic                                 data_req_o,    // Data request
    output logic                                 data_ts_set_o, // Is test and set operation
    output logic [ADDR_MEM_WIDTH-1:0]            data_add_o,    // Data request Address (No T&S bit here)
    output logic                                 data_wen_o,    // Data request type : 0--> Store, 1 --> Load
    output logic [DATA_WIDTH-1:0]                data_wdata_o,  // Data request Wrire data
    output logic [BE_WIDTH-1:0]                  data_be_o,     // Data request Byte enable 
    output logic [ID_WIDTH-1:0]                  data_ID_o,
    output logic [AUX_WIDTH-1:0]                 data_aux_o,      
    input  logic                                 data_gnt_i
);

    enum logic { LOAD_STORE, SET_STORE }       CS, NS;                // Current State and Next State
    logic                                      Enable;                // Signal Used to store the ByteEn and Address

    // Internal signal used to switch between LOAD_STORE and SET_STORE
    logic                                      TestAndSet;

    // SAMPLED INPUTS used in the SET_STORE state to comple the test and set opertation
    logic [ADDR_MEM_WIDTH-1:0]                 data_add_S;
    logic [BE_WIDTH-1:0]                       data_be_S;


    logic [ID_WIDTH-1:0]                       data_ID_S;
    logic [AUX_WIDTH-1:0]                      data_aux_S;


    assign TestAndSet = ( is_test_and_set_i & data_wen_i ) ;
    assign data_ts_set_o = (CS == SET_STORE);

    always_ff @(posedge clk, negedge  rst_n)
    begin : TestAndSet_UpdataState
      if(rst_n == 1'b0)
        begin
          CS <= LOAD_STORE;
          data_add_S   <= '0;
          data_be_S    <= '0;
          data_ID_S    <= '0;
          data_aux_S   <= '0;
        end
      else
        begin
          CS <= NS;


          if(Enable == 1'b1) // Sample Inputs for T&S
            begin
              data_add_S   <= data_add_i[ADDR_MEM_WIDTH-1:0];
              data_be_S    <= data_be_i;
              data_ID_S    <= data_ID_i;
              data_aux_S   <= data_aux_i;
            end

        end
    end


    always_comb
    begin : TestAndSet_ComputeState

      case(CS)

          LOAD_STORE: 
          begin : LOAD_STORE_STATE
              data_req_o   = data_req_i;
              data_gnt_o   = data_gnt_i;
              data_add_o   = data_add_i[ADDR_MEM_WIDTH-1:0];
              data_be_o    = data_be_i;
              data_wdata_o = data_wdata_i;
              data_wen_o   = data_wen_i;
              data_ID_o    = data_ID_i;
              data_aux_o   = data_aux_i;

              if((TestAndSet == 1'b1) && (data_req_i == 1'b1))
              begin
                  if(data_gnt_i  == 1'b1)
                  begin
                    NS = SET_STORE;
                    Enable = 1'b1;
                  end
                  else
                  begin
                    NS = LOAD_STORE;
                    Enable = 1'b0;
                  end
              end
              else
              begin
                  NS = LOAD_STORE;
                  Enable = 1'b0;
              end

          end

          SET_STORE:
          begin : SET_STORE_STATE
              data_req_o   = 1'b1;

              data_gnt_o = 1'b0;

              data_add_o   = data_add_S;
              data_be_o    = data_be_S;
              data_wdata_o = '1;
              data_wen_o   = 1'b0;
              data_ID_o    = data_ID_S;
              data_aux_o   = data_aux_S;
              Enable       = 1'b0;

              if(data_gnt_i  == 1'b1)
              begin
                    NS = LOAD_STORE;
              end
              else
              begin
                    NS = SET_STORE;
              end
          end



          default:
          begin
              data_req_o = 1'b0;
              data_gnt_o = data_gnt_i;

              data_add_o   = data_add_i[ADDR_MEM_WIDTH-1:0];
              data_be_o    = data_be_i;
              data_wdata_o = data_wdata_i;
              data_wen_o   = data_wen_i;
              data_ID_o    = data_ID_i;
              data_aux_o   = data_aux_i;

              Enable     = 1'b0;
              NS         = LOAD_STORE;
          end

      endcase
    end

endmodule
