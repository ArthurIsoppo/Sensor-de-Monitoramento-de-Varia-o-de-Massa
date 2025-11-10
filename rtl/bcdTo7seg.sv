module bcdTo7seg (
    input  logic [3:0] bcd_in,     // A entrada BCD (ex: 4'b0000)
    output logic [7:1] segmentos  // A saída para os DDP[7:1]
);
          // Display:
          //
          //   aaaaaaa   <- Segmento 'a' (DDP[7])
          //  f       b
          //  f       b  <- Segmento 'f' (DDP[2]) | Segmento 'b' (DDP[6])
          //  f       b
          //   ggggggg   <- Segmento 'g' (DDP[1])
          //  e       c
          //  e       c  <- Segmento 'e' (DDP[3]) | Segmento 'c' (DDP[5])
          //  e       c
          //   ddddddd   <- Segmento 'd' (DDP[4])
    
    // Mapeamento (Ânodo Comum: 0=Acende, 1=Apaga)
    always_comb begin
        case (bcd_in)
            4'b0000: segmentos = 7'b0000001; // 0

            4'b0001: segmentos = 7'b1001111; // 1

            4'b0010: segmentos = 7'b0010010; // 2

            4'b0011: segmentos = 7'b0000110; // 3

            4'b0100: segmentos = 7'b1001100; // 4

            4'b0101: segmentos = 7'b0100100; // 5

            4'b0110: segmentos = 7'b0100000; // 6

            4'b0111: segmentos = 7'b0001111; // 7

            4'b1000: segmentos = 7'b0000000; // 8

            4'b1001: segmentos = 7'b0000100; // 9

            default: segmentos = 7'b1111111; // Tudo apagado
        endcase
    end

endmodule