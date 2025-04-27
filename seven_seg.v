module seven_seg(
    input [2:0] digit,
    output reg [6:0] seg
);
 
    always @* begin
        case(digit)
            3'b000: seg = 7'b0001100; // "P 1" (Player 1 placing)
            3'b001: seg = 7'b0001100; // "P 2" (Player 2 placing, simplified to "P")
            3'b010: seg = 7'b0001000; // "A 1" (Player 1 attacking, simplified to "A")
            3'b011: seg = 7'b0001000; // "A 2" (Player 2 attacking, simplified to "A")
            3'b100: seg = 7'b1111001; // "1" (Player 1 wins)
            3'b101: seg = 7'b0100100; // "2" (Player 2 wins)
            default: seg = 7'b1111111; // Default (off)
        endcase
    end
endmodule