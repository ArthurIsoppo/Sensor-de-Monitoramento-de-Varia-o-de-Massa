// Módulo anodeDriver para 8 dígitos
module anodeDriver_8digits (
    input logic clk,
    input logic rst,
    output logic [2:0] anode_sel, // Agora com 3 bits (0-7)
    output logic [7:0] anodos    // Agora com 8 bits (para os 8 anodos)
);
    logic [19:0] counter; 
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) counter <= 0;
        else     counter <= counter + 1;
    end

    assign anode_sel = counter[19:17]; // Pega 3 bits do contador

    // Ativa o anodo selecionado (lógica ANODO COMUM - 0 = ativo)
    always_comb begin
        anodos = 8'hFF; // Desliga todos
        anodos[anode_sel] = 1'b0; // Liga apenas o selecionado
        
        // Se a sua placa for catodo comum, use:
        // anodos = 8'h00;
        // anodos[anode_sel] = 1'b1;
    end
endmodule