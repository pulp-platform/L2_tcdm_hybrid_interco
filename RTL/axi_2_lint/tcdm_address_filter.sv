`include "ulpsoc_defines.sv"

module tcdm_address_filter
#(
   parameter                N_RULES        = 8,
   parameter                DATA_WIDTH     = 32,
   parameter                ADDR_WIDTH     = 32,
   parameter                BE_WIDTH       = DATA_WIDTH/8,

   parameter                L2_BASE        = 32'h1C00_0000,
   parameter                ROM_BASE       = 32'h1A00_0000,
   parameter                APB_BASE       = 32'h1A10_0000,
   parameter                CLUSTER_BASE   = 32'h1000_0000,

   parameter                LSB_CHECK      = 6,
   parameter                MSB_CHECK      = 31,
   parameter                ENABLE_ALIAS_L2 = "FALSE",
   parameter                ENABLE_TEST_AND_SET = "TRUE"
)
(
    input  logic                     clk,
    input  logic                     rst_n,

    input  logic                     supervisor_mode_i,
    input  logic                     filter_en_i,

    input  logic                     req_i,
    input  logic [ADDR_WIDTH-1:0]    add_i,
    input  logic                     wen_i,
    input  logic [DATA_WIDTH-1:0]    wdata_i,
    input  logic [BE_WIDTH-1:0]      be_i,
    input  logic                     size_i,
    output logic                     gnt_o,
    output logic [DATA_WIDTH-1:0]    r_rdata_o,
    output logic                     r_valid_o,

    output logic                     req_o,
    output logic [ADDR_WIDTH-1:0]    add_o,
    output logic                     wen_o,
    output logic [DATA_WIDTH-1:0]    wdata_o,
    output logic [BE_WIDTH-1:0]      be_o,
    output logic                     size_o,
    input  logic                     gnt_i,
    input  logic [DATA_WIDTH-1:0]    r_rdata_i,
    input  logic                     r_valid_i,

    input  logic [N_RULES-1:0][31:0] RULES_i,
    output logic                     error_o
);

   genvar i;
   logic [ADDR_WIDTH-1:0]    add_int;
   // in case of test and set, out address must not be modified
   logic [ADDR_WIDTH-1:0]    add_int_ts;
   
   // remap ALIAS And T&S regions to absolute region
   generate
      if( ENABLE_ALIAS_L2 == "TRUE" )
      begin
          // remap also the test and set area
          if(ENABLE_TEST_AND_SET == "TRUE")
          begin
            assign add_int[19:0]  =   add_i[19:0];
            assign add_int[31:20] = ( add_i[31:20] == 12'h000 ) ? 12'h1C0 : ( add_i[31:16] == 16'h1E00 ) ? 12'h1C0 : add_i[31:20];
            // if we folded 1E00 to 1C0X for mpu, restore correct address for ts
            assign add_int_ts = ( add_i[31:16] == 16'h1E00 ) ? add_i : add_int;
          end
          else
          begin
            assign add_int[19:0]  =   add_i[19:0];
            assign add_int[31:20] = ( add_i[31:20] == 12'h000 ) ? 12'h1C0 : add_i[31:20];
            // t&s isn't enabled, don't care
            assign add_int_ts = add_int;
          end
      end
      else
      begin
          if(ENABLE_TEST_AND_SET == "TRUE")
          begin
            assign add_int[15:0]  =   add_i[15:0];
            assign add_int[31:16] = ( add_i[31:16] == 16'h1E00 ) ? 16'h1C00 : add_i[31:16];
            // if we folded 1E00 to 1C0X for mpu, restore correct address for ts
            assign add_int_ts = ( add_i[31:16] == 16'h1E00 ) ? add_i : add_int;
          end
          else
          begin
            assign add_int = add_i;
            // t&s isn't enabled, don't care
            assign add_int_ts = add_int;
          end
      end
   endgenerate



   int unsigned j,k;

   // ██████╗ ██╗   ██╗██╗     ███████╗███████╗
   // ██╔══██╗██║   ██║██║     ██╔════╝██╔════╝
   // ██████╔╝██║   ██║██║     █████╗  ███████╗
   // ██╔══██╗██║   ██║██║     ██╔══╝  ╚════██║
   // ██║  ██║╚██████╔╝███████╗███████╗███████║
   // ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝
   
   logic                              error_Q;

   logic [N_RULES-1:0]                match_region;

   logic [N_RULES-1:0][31:0]          BASE_start;
   logic [N_RULES-1:0][31:0]          BASE_end;

   logic [N_RULES-1:0][1:0]           A; // AREA
   logic [N_RULES-1:0][14:0]          BASE;
   logic [N_RULES-1:0][13:0]          SIZE;
   logic [N_RULES-1:0]                S; // ACTIVE RULE
   generate

      for(i=0; i<N_RULES; i++)
      begin : RULE_GEN
         assign { A[i], BASE[i], SIZE[i], S[i] } = RULES_i[i];
         always_comb
         begin
              case(A[i])
                `L2_SPACE:
                begin 
                  BASE_start[i] = L2_BASE  +  {BASE[i],6'h00} ;
                  BASE_end[i]   = L2_BASE  +  {BASE[i],6'h00} + {SIZE[i],6'h00};
                end

                `CLUSTER_SPACE:
                begin 
                  BASE_start[i] = CLUSTER_BASE   +  {BASE[i],6'h00} ;
                  BASE_end[i]   = CLUSTER_BASE   +  {BASE[i],6'h00} + {SIZE[i],6'h00};
                end

                `ROM_SPACE:
                begin 
                  BASE_start[i] = ROM_BASE +  {BASE[i],6'h00} ;
                  BASE_end[i]   = ROM_BASE +  {BASE[i],6'h00} + {SIZE[i],6'h00};
                end

                `APB_SPACE: 
                begin 
                  BASE_start[i] = APB_BASE +  {BASE[i],6'h00} ;
                  BASE_end[i]   = APB_BASE +  {BASE[i],6'h00} + {SIZE[i],6'h00};
                end

              endcase // A[i]
              
         end   
      end

   endgenerate


   always_ff @(posedge clk, negedge rst_n) 
   begin 
      if(~rst_n)
      begin
          error_Q <= 0;        
      end
      else
      begin
          error_Q <= error_o;
      end
   end


   always_comb
   begin
      for(j=0;j<N_RULES;j++)
      begin

            if ( ( add_int[MSB_CHECK:LSB_CHECK] >= BASE_start[j][MSB_CHECK:LSB_CHECK])  &&  (add_int[MSB_CHECK:LSB_CHECK] < BASE_end[j][MSB_CHECK:LSB_CHECK])  )
            begin
               match_region[j] = S[j];
            end
            else 
            begin
               match_region[j] = 1'b0;
            end

      end
   end


   always_comb 
   begin
      if((filter_en_i == 1'b1) && (|match_region == 1'b0))
      begin
         req_o   = (supervisor_mode_i) ? req_i  : 1'b0;
         error_o = (supervisor_mode_i) ? 1'b0   : req_i;  
      end
      else
      begin
         req_o   =  req_i;
         error_o =  1'b0;
      end
   end

    assign add_o     = (ENABLE_TEST_AND_SET == "TRUE") ? add_int_ts : add_int;
    assign wdata_o   = wdata_i;
    assign be_o      = be_i;
    assign wen_o     = wen_i;
    assign size_o    = size_i;
    assign gnt_o     = ( error_o ) ? 1'b1 : gnt_i;

    generate
      case(DATA_WIDTH)
        64:      assign  r_rdata_o = ( error_Q ) ? {32'hBADE5505,32'hBADE5505} :  r_rdata_i;
        default: assign  r_rdata_o = ( error_Q ) ? 32'hBADE5505                :  r_rdata_i;
      endcase // DATA_WIDTH
    endgenerate

    assign r_valid_o = ( error_Q ) ? 1'b1         :  r_valid_i; 

endmodule
