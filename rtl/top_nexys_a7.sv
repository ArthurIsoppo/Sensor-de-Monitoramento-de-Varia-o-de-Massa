module top_nexys_a7 (
    input logic clk,         
    input logic btnC,        
    input logic hx711_data_in,   
    output logic hx711_sclk_out, 

    output logic [7:0] catodos, // 8 catodos (CA-CG + DP)
    output logic [7:0] anodos    // 8 anodos
);

    // --- [1. Instância do Driver HX711] ---
    logic [23:0] s_hx711_raw_data;     
    logic        s_hx711_data_ready;   
    logic        s_driver_start_pulse; 
    logic        s_driver_ready;       
    localparam logic [15:0] HX711_DVSR = 16'd5000; // Divisor para o clock do HX711 

    hx711driver inst_hx711_driver (
        .clk(clk), .reset(1'b0), .dvsr(HX711_DVSR), .start(s_driver_start_pulse),
        .dout(s_hx711_raw_data), .hx711_done_tick(s_hx711_data_ready),
        .ready(s_driver_ready), .sclk(hx711_sclk_out), .hx711_in(hx711_data_in)
    );

    // --- [2. Lógica de "Cola" e Calibração com 10kg] ---
    
    logic signed [23:0] s_tare_offset;       
    logic signed [23:0] s_weight_calibrated; 
    logic [26:0]        s_final_display_value; // Saída final (0-99,999,999)

    // !! IMPORTANTE: NOVO FATOR DE CALIBRAÇÃO !!
    // Este é o valor bruto (s_weight_calibrated) lido quando 
    // você coloca exatamente 10kg (10000g) na balança.
    // Exemplo: 4100000 (um valor grande)
    localparam signed [23:0] RAW_VALUE_FOR_10KG = 4100000; // <-- VOCÊ VAI MUDAR ISSO

    always_ff @(posedge clk) begin
        // Lógica de start (sempre pedindo novos dados)
        s_driver_start_pulse <= 1'b0; 
        if (s_driver_ready) begin     
            s_driver_start_pulse <= 1'b1; 
        end
        // Lógica de Tara
        if (btnC) begin 
            s_tare_offset <= signed'(s_hx711_raw_data);
        end
        
        // Lógica de Cálculo (quando um novo dado chega)
        if (s_hx711_data_ready) begin
            // a. Subtrai a tara
            s_weight_calibrated <= signed'(s_hx711_raw_data) - s_tare_offset;
            
            // b. Nova Calibração para o formato XX.XXXXXX (kg)
            // Queremos transformar o valor bruto de 10kg (RAW_VALUE_FOR_10KG) 
            // no número 10,000,000 (que o display mostrará como 10.000000)
            
            // Formula: display = (raw_calibrated * 10,000,000) / RAW_VALUE_FOR_10KG
            
            logic signed [47:0] temp_calc; // 24 bits + 24 bits (para 10,000,000)
            temp_calc = s_weight_calibrated * 10000000;

            // Evita divisão por zero se o fator não foi setado
            if (RAW_VALUE_FOR_10KG != 0)
                s_final_display_value <= 27'(temp_calc / RAW_VALUE_FOR_10KG);
            else
                s_final_display_value <= 0;
            
            // Saturação (para 8 dígitos, máx 99,999,999)
            if (temp_calc < 0)
                s_final_display_value <= 27'd0;
            else if (s_final_display_value > 99999999) 
                s_final_display_value <= 27'd99999999;
        end
    end

    // --- [3. Sistema de Display (8 dígitos)] ---
    
    logic [3:0] bcd7, bcd6, bcd5, bcd4, bcd3, bcd2, bcd1, bcd0;
    logic [2:0] s_anode_sel; // Seletor 0 a 7
    logic [3:0] s_bcd_mux;   // Saída do MUX BCD
    logic [6:0] s_seg_out;   // Saída dos 7 segmentos

    // Instancia conversor de 8 dígitos
    biToBCD_8digits inst_biToBCD (
        .binary_in(s_final_display_value), 
        .bcd7(bcd7), .bcd6(bcd6), .bcd5(bcd5), .bcd4(bcd4),
        .bcd3(bcd3), .bcd2(bcd2), .bcd1(bcd1), .bcd0(bcd0)
    );
    
    // Instancia o driver de 8 anodos
    anodeDriver_8digits inst_anode_driver (
        .clk(clk),
        .rst(1'b0), 
        .anode_sel(s_anode_sel), // Fio [2:0]
        .anodos(anodos)         // Saída [7:0]
    );

    always_comb begin
        case(s_anode_sel)
            3'd7:    s_bcd_mux = bcd7;
            3'd6:    s_bcd_mux = bcd6;
            3'd5:    s_bcd_mux = bcd5;
            3'd4:    s_bcd_mux = bcd4;
            3'd3:    s_bcd_mux = bcd3;
            3'd2:    s_bcd_mux = bcd2;
            3'd1:    s_bcd_mux = bcd1;
            3'd0:    s_bcd_mux = bcd0;
            default: s_bcd_mux = 4'hF; // Apaga (valor BCD inválido)
        endcase
    end

    // Instancia o conversor BCD para 7 segmentos
    bcdTo7seg inst_bcdTo7seg (
        .bcd_in(s_bcd_mux),
        .seg_out(s_seg_out) // Saída de 7 bits
    );
    
    // Conexão final dos CATODOS (incluindo o Ponto Decimal)
    assign catodos[6:0] = s_seg_out; // Conecta os 7 segmentos
    
    // Acende o ponto decimal
    // Formato: A7 A6. A5 A4 A3 A2 A1 A0
    assign catodos[7] = (s_anode_sel == 3'd6) ? 1'b0 : 1'b1; // 0 = Acende, 1 = Apaga

endmodule