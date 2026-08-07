/******************************************************************************
 *
 * Testbench : metadata_decoder_tb
 *
 ******************************************************************************/

`timescale 1ns/1ps

module metadata_decoder_tb;

    //----------------------------------------------------------
    // DUT Signals
    //----------------------------------------------------------

    logic [2:0] metadata;

    logic [3:0] enable_mask;

    logic [1:0] index0;
    logic [1:0] index1;

    //----------------------------------------------------------
    // DUT
    //----------------------------------------------------------

    metadata_decoder dut
    (
        .metadata(metadata),

        .enable_mask(enable_mask),

        .index0(index0),
        .index1(index1)
    );

    //----------------------------------------------------------
    // Waveform Dump
    //----------------------------------------------------------

    initial
    begin

        $dumpfile("build/metadata_decoder_tb.vcd");
        $dumpvars(0, metadata_decoder_tb);

    end

    //----------------------------------------------------------
    // Test Stimulus
    //----------------------------------------------------------

    initial
    begin

        $display("");
        $display("-----------------------------------------------");
        $display(" Metadata Decoder Verification");
        $display("-----------------------------------------------");
        $display("");

        //------------------------------------------------------
        // Test every metadata value
        //------------------------------------------------------

        for (int i = 0; i < 8; i++)
        begin

            metadata = i[2:0];

            #10;

            $display("---------------------------------------");
            $display("Metadata    : %03b", metadata);
            $display("Enable Mask : %04b", enable_mask);
            $display("Index0      : %0d", index0);
            $display("Index1      : %0d", index1);

            if(enable_mask == 4'b0000)
                $display("Status      : INVALID METADATA");

            else
                $display("Status      : VALID");

        end

        $display("");
        $display("-----------------------------------------------");
        $display(" Metadata Decoder Test PASSED");
        $display("-----------------------------------------------");

        $finish;

    end

endmodule