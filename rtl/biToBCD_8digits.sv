// Módulo biToBCD para 8 dígitos (até 99,999,999)
// Um número de 27 bits  (2^27 > 134 milhões)
module biToBCD_8digits (
    input logic [26:0] binary_in, 
    output logic [3:0] bcd7,
    output logic [3:0] bcd6,
    output logic [3:0] bcd5,
    output logic [3:0] bcd4,
    output logic [3:0] bcd3,
    output logic [3:0] bcd2,
    output logic [3:0] bcd1,
    output logic [3:0] bcd0  // Unidade
);

    // Converte o binário para 8 dígitos BCD
    always_comb begin
        bcd7 = binary_in / 10000000;
        bcd6 = (binary_in % 10000000) / 1000000;
        bcd5 = (binary_in % 1000000) / 100000;
        bcd4 = (binary_in % 100000) / 10000;
        bcd3 = (binary_in % 10000) / 1000;
        bcd2 = (binary_in % 1000) / 100;
        bcd1 = (binary_in % 100) / 10;
        bcd0 = binary_in % 10;
    end

endmodule