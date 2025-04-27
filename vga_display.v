`timescale 1ns / 1ps

module vga_display
(
    input wire clk, reset,
    output wire Hsync, Vsync,
    input wire [35:0] coloring_array_p1, // Player 1's attack grid state
    input wire [35:0] coloring_array_p2, // Player 2's attack grid state
    input wire [35:0] hitmiss_array_p1,  // Player 1's ship positions
    input wire [35:0] hitmiss_array_p2,  // Player 2's ship positions
    input wire [35:0] cursor_p1,         // Player 1's attack cursor
    input wire [35:0] cursor_p2,         // Player 2's attack cursor
    input wire [35:0] placement_cursor_p1, // Player 1's placement cursor
    input wire [35:0] placement_cursor_p2, // Player 2's placement cursor
    input wire [35:0] placed_ships_p1,   // Player 1's placed ships
    input wire [35:0] placed_ships_p2,   // Player 2's placed ships
    input wire [2:0] game_state,         // Game state to control grid visibility
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue
);

    // VGA timing parameters
    localparam H_DISPLAY       = 640;
    localparam H_L_BORDER      =  48;
    localparam H_R_BORDER      =  16;
    localparam H_RETRACE       =  96;
    localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_RETRACE - 1;
    localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
    localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_RETRACE - 1;

    localparam V_DISPLAY       = 480;
    localparam V_T_BORDER      =  10;
    localparam V_B_BORDER      =  33;
    localparam V_RETRACE       =   2;
    localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_RETRACE - 1;
    localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
    localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_RETRACE - 1;

    // Game states
    localparam STATE_P1_PLACING = 3'b000;
    localparam STATE_P2_PLACING = 3'b001;
    localparam STATE_P1_ATTACK  = 3'b010;
    localparam STATE_P2_ATTACK  = 3'b011;
    localparam STATE_P1_WINS    = 3'b100;
    localparam STATE_P2_WINS    = 3'b101;

    // mod-4 counter to generate 25 MHz pixel tick
    reg [1:0] pixel_reg;
    wire [1:0] pixel_next;
    wire pixel_tick;

    always @(posedge clk, posedge reset)
    if(reset)
        pixel_reg <= 0;
    else
        pixel_reg <= pixel_next;

    assign pixel_next = pixel_reg + 1;
    assign pixel_tick = (pixel_reg == 0);

    // registers to keep track of current pixel location
    reg [9:0] h_count_reg, h_count_next, v_count_reg, v_count_next;

    // register to keep track of vsync and hsync signal states
    reg vsync_reg, hsync_reg;
    wire vsync_next, hsync_next;
     
    always @(posedge clk, posedge reset)
    if(reset)
       begin
            v_count_reg <= 0;
            h_count_reg <= 0;
            vsync_reg   <= 0;
            hsync_reg   <= 0;
       end
    else
       begin
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            vsync_reg   <= vsync_next;
            hsync_reg   <= hsync_next;
       end

    always @*
    begin
        h_count_next = pixel_tick ?
                      h_count_reg == H_MAX ? 0 : h_count_reg + 1
              : h_count_reg;

        v_count_next = pixel_tick && h_count_reg == H_MAX ?
                      (v_count_reg == V_MAX ? 0 : v_count_reg + 1)
              : v_count_reg;
    end

    assign hsync_next = h_count_reg >= START_H_RETRACE && h_count_reg <= END_H_RETRACE;
    assign vsync_next = v_count_reg >= START_V_RETRACE && v_count_reg <= END_V_RETRACE;

    assign video_on = (h_count_reg < H_DISPLAY) && (v_count_reg < V_DISPLAY);

    // Define grid parameters
    parameter cell_size = 30;
    parameter grid_size = 6;
    
    // Define grid positions
    parameter grid1_start_x = 50;  // Player 1 placement grid (top-left)
    parameter grid1_start_y = 50;
    parameter grid2_start_x = 300; // Player 2 placement grid (top-right)
    parameter grid2_start_y = 50;
    parameter grid3_start_x = 50;  // Player 1 attack grid (bottom-left)
    parameter grid3_start_y = 300;
    parameter grid4_start_x = 300; // Player 2 attack grid (bottom-right)
    parameter grid4_start_y = 300;
    
    integer curr_cell;                  
    
    always @(*)
    begin
        vgaRed = 4'b0000;
        vgaGreen = 4'b0000;
        vgaBlue = 4'b0000;
        
        if (v_count_reg >= 0 && v_count_reg < V_DISPLAY)
        begin
            // Grid 1 - Player 1 Placement Grid (only during Player 1 placement)
            if (game_state == STATE_P1_PLACING &&
                h_count_reg >= grid1_start_x && h_count_reg < grid1_start_x + (grid_size * cell_size) &&
                v_count_reg >= grid1_start_y && v_count_reg < grid1_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid1_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid1_start_x) / cell_size);
                
                if ((h_count_reg - grid1_start_x) % cell_size == 0 || 
                    (v_count_reg - grid1_start_y) % cell_size == 0)
                begin
                    vgaRed = 4'b0111;
                    vgaGreen = 4'b0111;
                    vgaBlue = 4'b0111;
                end
                else if (placement_cursor_p1[curr_cell] == 1)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b0000;
                end
                else if (placed_ships_p1[curr_cell] == 1)
                begin
                    vgaRed = 4'b0000;
                    vgaGreen = 4'b0000;
                    vgaBlue = 4'b1111;
                end
                else
                begin
                    vgaRed = 4'b0101;
                    vgaGreen = 4'b0101;
                    vgaBlue = 4'b0101;
                end
            end
            
            // Grid 2 - Player 2 Placement Grid (only during Player 2 placement)
            else if (game_state == STATE_P2_PLACING &&
                     h_count_reg >= grid2_start_x && h_count_reg < grid2_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid2_start_y && v_count_reg < grid2_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid2_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid2_start_x) / cell_size);
                
                if ((h_count_reg - grid2_start_x) % cell_size == 0 || 
                    (v_count_reg - grid2_start_y) % cell_size == 0)
                begin
                    vgaRed = 4'b0111;
                    vgaGreen = 4'b0111;
                    vgaBlue = 4'b0111;
                end
                else if (placement_cursor_p2[curr_cell] == 1)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b0000;
                end
                else if (placed_ships_p2[curr_cell] == 1)
                begin
                    vgaRed = 4'b0000;
                    vgaGreen = 4'b0000;
                    vgaBlue = 4'b1111;
                end
                else
                begin
                    vgaRed = 4'b0101;
                    vgaGreen = 4'b0101;
                    vgaBlue = 4'b0101;
                end
            end
            
            // Grid 3 - Player 1 Attack Grid (Player 1 attacks Player 2)
            else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK || game_state == STATE_P1_WINS || game_state == STATE_P2_WINS) &&
                     h_count_reg >= grid3_start_x && h_count_reg < grid3_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid3_start_y && v_count_reg < grid3_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid3_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid3_start_x) / cell_size);
                
                if ((h_count_reg - grid3_start_x) % cell_size == 0 || 
                    (v_count_reg - grid3_start_y) % cell_size == 0)
                begin
                    vgaRed = 4'b0111;
                    vgaGreen = 4'b0111;
                    vgaBlue = 4'b0111;
                end
                else if (game_state == STATE_P1_ATTACK && cursor_p1[curr_cell] == 1)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b0000;
                end
                else if (coloring_array_p1[curr_cell] == 1 && hitmiss_array_p2[curr_cell] == 1)
                begin
                    vgaRed = 4'b0000;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b0000;
                end
                else if (coloring_array_p1[curr_cell] == 1 && hitmiss_array_p2[curr_cell] == 0)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b0000;
                    vgaBlue = 4'b0000;
                end
                else
                begin
                    vgaRed = 4'b0101;
                    vgaGreen = 4'b0101;
                    vgaBlue = 4'b0101;
                end
            end
            
            // Grid 4 - Player 2 Attack Grid (Player 2 attacks Player 1)
            else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK || game_state == STATE_P1_WINS || game_state == STATE_P2_WINS) &&
                     h_count_reg >= grid4_start_x && h_count_reg < grid4_start_x + (grid_size * cell_size) &&
                     v_count_reg >= grid4_start_y && v_count_reg < grid4_start_y + (grid_size * cell_size))
            begin
                curr_cell = ((v_count_reg - grid4_start_y) / cell_size) * grid_size + 
                            ((h_count_reg - grid4_start_x) / cell_size);
                
                if ((h_count_reg - grid4_start_x) % cell_size == 0 || 
                    (v_count_reg - grid4_start_y) % cell_size == 0)
                begin
                    vgaRed = 4'b0111;
                    vgaGreen = 4'b0111;
                    vgaBlue = 4'b0111;
                end
                else if (game_state == STATE_P2_ATTACK && cursor_p2[curr_cell] == 1)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b0000;
                end
                else if (coloring_array_p2[curr_cell] == 1 && hitmiss_array_p1[curr_cell] == 1)
                begin
                    vgaRed = 4'b0000;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b0000;
                end
                else if (coloring_array_p2[curr_cell] == 1 && hitmiss_array_p1[curr_cell] == 0)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b0000;
                    vgaBlue = 4'b0000;
                end
                else
                begin
                    vgaRed = 4'b0101;
                    vgaGreen = 4'b0101;
                    vgaBlue = 4'b0101;
                end
            end
            
            // Title text area above grids
            else if (h_count_reg >= grid1_start_x && h_count_reg < grid4_start_x + (grid_size * cell_size) &&
                     v_count_reg >= 20 && v_count_reg < 40)
            begin
                // "Player 1 Fleet" over Grid 1 (during Player 1 placement)
                if (game_state == STATE_P1_PLACING &&
                    h_count_reg >= grid1_start_x + 30 && h_count_reg < grid1_start_x + 150)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b1111;
                end
                // "Player 2 Fleet" over Grid 2 (during Player 2 placement)
                else if (game_state == STATE_P2_PLACING &&
                         h_count_reg >= grid2_start_x + 30 && h_count_reg < grid2_start_x + 150)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b1111;
                end
                // "Player 2 Fleet" over Grid 3 (during attack phases)
                else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK || game_state == STATE_P1_WINS || game_state == STATE_P2_WINS) &&
                         h_count_reg >= grid3_start_x + 30 && h_count_reg < grid3_start_x + 150)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b1111;
                end
                // "Player 1 Fleet" over Grid 4 (during attack phases)
                else if ((game_state == STATE_P1_ATTACK || game_state == STATE_P2_ATTACK || game_state == STATE_P1_WINS || game_state == STATE_P2_WINS) &&
                         h_count_reg >= grid4_start_x + 30 && h_count_reg < grid4_start_x + 150)
                begin
                    vgaRed = 4'b1111;
                    vgaGreen = 4'b1111;
                    vgaBlue = 4'b1111;
                end
            end
        end
    end
    
    assign Hsync = hsync_reg;
    assign Vsync = vsync_reg;
endmodule