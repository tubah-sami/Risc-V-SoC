
`timescale 1ns/1ps

class soc_axi_monitor;

    virtual soc_if vif;

    mailbox #(soc_transaction) axi2scb;

    //========================================================
    // Pending WRITE information
    //========================================================

    bit        write_aw_pending;
    bit        write_w_pending;

    bit [31:0] pending_awaddr;
    bit [31:0] pending_wdata;
    bit [3:0]  pending_wstrb;

    //========================================================
    // Pending READ information
    //========================================================

    bit        read_ar_pending;
    bit [31:0] pending_araddr;

    //========================================================
    // Constructor
    //========================================================

    function new(
        virtual soc_if vif,
        mailbox #(soc_transaction) axi2scb
    );

        this.vif     = vif;
        this.axi2scb = axi2scb;

        write_aw_pending = 1'b0;
        write_w_pending  = 1'b0;

        read_ar_pending  = 1'b0;

        pending_awaddr   = 32'h0;
        pending_wdata    = 32'h0;
        pending_wstrb    = 4'h0;

        pending_araddr   = 32'h0;

    endfunction


    //========================================================
    // AXI MONITOR
    //========================================================

    task run();

        soc_transaction tr;

        forever begin

            @(posedge vif.clk);

            //================================================
            // WRITE ADDRESS CHANNEL
            //================================================

            if (vif.m_axi_awvalid &&
                vif.m_axi_awready) begin

                write_aw_pending = 1'b1;
                pending_awaddr   = vif.m_axi_awaddr;

                $display(
                    "[AXI MONITOR] AW HANDSHAKE addr=%08h",
                    vif.m_axi_awaddr
                );

            end


            //================================================
            // WRITE DATA CHANNEL
            //================================================

            if (vif.m_axi_wvalid &&
                vif.m_axi_wready) begin

                write_w_pending = 1'b1;
                pending_wdata   = vif.m_axi_wdata;
                pending_wstrb   = vif.m_axi_wstrb;

                $display(
                    "[AXI MONITOR] W HANDSHAKE data=%08h strb=%b",
                    vif.m_axi_wdata,
                    vif.m_axi_wstrb
                );

            end


 //================================================
// WRITE RESPONSE
//
// AW + W + B are combined into ONE transaction
//================================================

if (vif.m_axi_bvalid &&
    vif.m_axi_bready) begin

    tr = new();

    tr.axi_write   = 1'b1;

    tr.axi_address = pending_awaddr;
    tr.axi_wdata   = pending_wdata;
    tr.axi_wstrb   = pending_wstrb;
    tr.axi_bresp   = vif.m_axi_bresp;

    //================================================
    // CLASSIFY TRANSACTION
    //================================================

    if (pending_awaddr == 32'hFFFF_F000) begin

        tr.test_type = soc_transaction::INVALID_ACCESS;

        $display(
            "[AXI MONITOR] INVALID WRITE COMPLETE addr=%08h data=%08h resp=%b",
            pending_awaddr,
            pending_wdata,
            vif.m_axi_bresp
        );

    end
    else begin

        tr.test_type = soc_transaction::AXI_TEST;

        $display(
            "[AXI MONITOR] WRITE COMPLETE addr=%08h data=%08h resp=%b",
            pending_awaddr,
            pending_wdata,
            vif.m_axi_bresp
        );

    end

    axi2scb.put(tr);

    write_aw_pending = 1'b0;
    write_w_pending  = 1'b0;

end

            //================================================
            // READ ADDRESS CHANNEL
            //================================================

            if (vif.m_axi_arvalid &&
                vif.m_axi_arready) begin

                read_ar_pending = 1'b1;
                pending_araddr  = vif.m_axi_araddr;

                $display(
                    "[AXI MONITOR] AR HANDSHAKE addr=%08h",
                    vif.m_axi_araddr
                );

            end


            //================================================
            // READ RESPONSE
            //
            // AR + R are combined into ONE transaction
            //================================================

            if (vif.m_axi_rvalid &&
                vif.m_axi_rready) begin

                tr = new();

                tr.test_type = soc_transaction::AXI_TEST;

                tr.axi_read = 1'b1;

                tr.axi_address = pending_araddr;
                tr.axi_rdata   = vif.m_axi_rdata;
                tr.axi_rresp   = vif.m_axi_rresp;

                $display(
                    "[AXI MONITOR] READ COMPLETE addr=%08h data=%08h resp=%b",
                    pending_araddr,
                    vif.m_axi_rdata,
                    vif.m_axi_rresp
                );

                axi2scb.put(tr);

                read_ar_pending = 1'b0;

            end

        end

    endtask

endclass


