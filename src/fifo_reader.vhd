-----------------------------------------------------------------------------
-- Scaler main guts are here.
--
-- 720p timing generator
-- read fifo, demux 4:2:2, deinterlace/interpolate Y, interpolate X,

-- timing generator code based on Mike Field work

--Copyright (C) 2017  rrk

--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.

--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.

--    You should have received a copy of the GNU General Public License
--   along with this program. If not, see <http://www.gnu.org/licenses/>.
-----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity fifo_reader is
  port (
    clk        : in     std_logic;
    pal_ntsc   : in     std_logic;         -- PAL=1 NTSC=0
    fifo_data  : in     std_logic_vector (15 downto 0);
    fifo_rden  : out    std_logic := '1';
    blank      : buffer std_logic;
    hsync      : out    std_logic;
    vsync_in   : in     std_logic;
    vsync_stop : in     std_logic;         -- hard sync on VSYNC or use DPLL
    vsync      : out    std_logic;
    fid        : in     std_logic;
    Y_out      : out    std_logic_vector (7 downto 0);
    Cr_out     : out    std_logic_vector (7 downto 0);
    Cb_out     : out    std_logic_vector (7 downto 0);
    x_pos      : out    std_logic_vector(11 downto 0);
    y_pos      : out    std_logic_vector(11 downto 0);
    ps_request : out    std_logic := '0';  -- DPLL adjust command
    inc_dec    : out    std_logic := '0'   -- DPLL direction
    );

end fifo_reader;

architecture Behavioral of fifo_reader is

  constant vsync_delay       : integer                       := 40;
  type line_buffer_720 is array (722 downto 1) of std_logic_vector (23 downto 0);
  signal deinterlacer_buffer : line_buffer_720               := (others => (others => '0'));
  signal vsync_dly1          : std_logic                     := '0';
  signal vsync_dly2          : std_logic                     := '0';
  signal vsync_dly3          : std_logic                     := '0';
  signal vsync_delay_timer   : unsigned(11 downto 0)         := (others => '0');
  signal Y_dly               : std_logic_vector (7 downto 0) := (others => '0');
  signal C_dly1              : std_logic_vector (7 downto 0) := (others => '0');
  signal C_dly2              : std_logic_vector (7 downto 0) := (others => '0');
  signal x                   : unsigned(11 downto 0)         := (others => '0');
  signal y                   : unsigned(11 downto 0)         := (others => '0');
  -- PAL/NTSC deinterlacer buffer readout position
  signal x_720               : unsigned(11 downto 0)         := X"001";  -- range 1 to 720
  signal fill_position_720   : unsigned (11 downto 0)        := X"001";
  signal filling_enabled     : std_logic                     := '0';
  signal filling_request     : std_logic                     := '0';

  attribute MARK_DEBUG      : string;
  attribute MARK_DEBUG of y : signal is "TRUE";
  attribute MARK_DEBUG of x : signal is "TRUE";

begin

  v_synchronizer : process (clk) is
  -- forced VSYNC to timing generator OR digital PLL detecor based on which 720p line input VSYNC will hit
  begin
    if rising_edge(clk) then

      if x = 1650-1 then
        vsync_delay_timer <= (vsync_delay_timer + 1);
        -- count end of lines, hope it will not overrun if vsyncs are here
        -- when it will reach vsync_delay we will fire vsync at main HDTV raster generator
        -- when it will reach filling_start: we will fire line buffer filling
      end if;

      vsync_dly1 <= vsync_in;
      vsync_dly2 <= vsync_dly1;
      vsync_dly3 <= vsync_dly2;

      if vsync_dly2 = '1' and vsync_dly3 = '0' then  -- find synchronous edge of vsync

        vsync_delay_timer <= x"000";    -- then fire vsync delay timer

        -- DO our cool DPLL :)

        -- if PAL / NTSC derived VSYNC hits HDTV line 710, fine, do nothing.
        -- earlier/later - will command to bump HDTV MMCM frequency up/down

        if (y < 710) and (y > 355) then
          ps_request <= '1';
          inc_dec    <= '0';
        elsif (y > 710) or (y < 356) then
          ps_request <= '1';
          inc_dec    <= '1';
        else
          ps_request <= '0';
          inc_dec    <= '0';
        end if;

      end if;

    end if;

  end process;

  buffer_reader_X_scaler : process(clk) is
  -- we are reading YCrCb from line buffer to HDTV output using 1280/720 nearest-neighbour interpolation
  begin

    if rising_edge(clk) then
      if blank = '0' then
        Cb_out <= deinterlacer_buffer(to_integer (x_720))(7 downto 0);
        Cr_out <= deinterlacer_buffer(to_integer (x_720))(15 downto 8);
        Y_out  <= deinterlacer_buffer(to_integer (x_720))(23 downto 16);
      else
        Cb_out <= x"80";                -- do blanking
        Cr_out <= x"80";
        Y_out  <= x"10";
      end if;

    end if;
  end process;

  Y_scaler_controller : process (clk)

-- BOB deinterlacer and Y interpolation logic here
-- requests (or not) SDTV deinterlacer buffer fill from FIFO
-- when fill not requested, SDTV buffer just repeats on HDTV out,
-- multiplying the same SDTV line
-- buffer filling is done faster than HDTV output, so display readout will not overrun it
--
-- depends on HDTV line number and deinterlacing/line multiplying logic here
-- BOB deinterlacer does line tripling for NTSC
-- or linedoubling and linetripling for PAL

-- filler process will get 720 pixels and then stop itself untill kicked for the next time

  begin

    if rising_edge(clk) then
      if (x = 1430) then  -- sync filler controller to ~~about HDTV hsync time

        if (y = 25) or (y > 745) then
          -- do buffer prefill for first line.
          -- also flush fifo by dummy reads after frame ends just in case...
          filling_request <= '1';

        elsif (y >= 26) and (y < 720 + 26) then

          -- rules for active parts of HDTV frame
          if pal_ntsc = '0' then        --- logic for NTSC sdeinterlacer-scaler

            if fid = '0' then           -- first NTSC frame is EVEN
              if (y < 27) then
                null;  --repeat prefilled buffer on first 2 lines
              elsif ((y-26) rem 3) = 1 then  -- (! adjust!!!)
                -- request next SDTV line and repeat 3 times
                filling_request <= '1';
              end if;
            else                        -- do odd NTSC frame
              if (((y-28) rem 3) = 1) or (y = 26) or (y = 27) then
                -- request next SDTV line and repeat 3 times
                filling_request <= '1';
              end if;
            end if;  -- ntsc fid 0/1

          else                          -- logic for PAL deinterlacer-scaler

            if fid = '0' then
              if (((y-26) rem 5) = 1) or (((y-26) rem 5) = 4) then
                -- request next SDTV line and repeat 2 or 3 times
                filling_request <= '1';
              end if;
            else
              if (y = 26) or (y = 27) then
                null;  --repeat prefilled buffer on first 3 lines
              elsif (((y-27) rem 5) = 1) or (((y-27) rem 5) = 4) then
                -- request next SDTV line and repeat 3 times
                filling_request <= '1';
              end if;
            end if;  -- pal fid 0/1

          end if;  --pal/ntsc

        end if;  -- active frame

      else
        filling_request <= '0';
      end if;  -- x=1430

    end if;  -- clk
  end process;

  Buffer_filler : process (clk)
  -- quickly fill deinterlacer buffer from FIFO
  begin
    if rising_edge(clk) then

      if filling_request = '1' then
        filling_enabled   <= '1';
        fifo_rden         <= '1';
        fill_position_720 <= x"000";
      end if;

      if filling_enabled = '1' then
        Y_dly  <= fifo_data (7 downto 0);
        C_dly1 <= fifo_data (15 downto 8);
        C_dly2 <= C_dly1;

        -- do demux YCrCb 422 to 444
        if fill_position_720 > 0 then  -- position 0 is a pre-read, 1-720 are real indexes
          if fill_position_720(0 downto 0) = 0 then
            deinterlacer_buffer (to_integer (fill_position_720)) <= (Y_dly & C_dly1 & C_dly2);  --odd pixel
          else
            deinterlacer_buffer (to_integer (fill_position_720)) <= (Y_dly & (fifo_data(15 downto 8)) & C_dly1);  --even pixel
          end if;
        end if;

        fill_position_720 <= fill_position_720 + 1;

        if fill_position_720 = 719 then
          -- auto stop filler process & reset pointer after we got 720 pixels from FIFO
          fill_position_720 <= x"000";
          filling_enabled   <= '0';
          fifo_rden         <= '0';
        end if;
      end if;

    end if;  -- clk
  end process;

  HDTV_raster_generator : process(clk)
  -- HDTV 720p50 / 720p60 timing generator is here
  -- x range 0 to 1650-1 for 720p60 or 1980-1 for 720p50
  -- y range 1 to 750 (+ 5 dummy lines in case no input vsync arrived!)
  begin
    if rising_edge(clk) then

      if x = 1280-1 then
        blank <= '1';
      elsif ((x = (1650-1) and (pal_ntsc = '0')) or (x = (1980-1) and (pal_ntsc = '1'))) and (y < 720 and y >= 25) then
        blank <= '0';
      end if;

      if ((x = 1390) and (pal_ntsc = '0')) or ((x = 1720) and (pal_ntsc = '1')) then
        hsync <= '1';
      elsif ((x = 1430) and (pal_ntsc = '0')) or ((x = 1760) and (pal_ntsc = '1'))then
        hsync <= '0';
      end if;

      x_pos <= std_logic_vector (x);
      y_pos <= std_logic_vector (y);

      if (x = (1650-1) and pal_ntsc = '0') or (x = (1980-1) and pal_ntsc = '1') then
        x     <= (others => '0');
        x_720 <= x"001";  -- also reset deinterlacer buffer readout counter

        if y = 1 then
          vsync <= '1';
        elsif y = 5 then
          vsync <= '0';
        end if;

        if (((y = 755) or (vsync_delay_timer = vsync_delay)) and vsync_stop = '0') or ((y >= 750) and (vsync_stop = '1')) then
          -- reset y at max 755 or when real vsync arrived (when hard sync enabled) or at line 750 when DPLL works
          y     <= X"001";
          vsync <= '1';
        else
          y <= y + 1;
        end if;

      else
        x <= x + 1;

        -- shitty shameful nearest neighbour 720 to 1280 interpolation kernel
        -- generate index for 720pixels SDTV buffer readout
        -- pattern repeats each 16 HDTV pixels
        -- skipping increments or not

        case (std_logic_vector (x (3 downto 0))) is
          --    when "0000" => null ;
          when "0001" => x_720 <= x_720+1;
          --    when "0010" => null ;
          when "0011" => x_720 <= x_720+1;
          --    when "0100" => null;
          when "0101" => x_720 <= x_720+1;
          --    when "0110" =>  null;
          when "0111" => x_720 <= x_720+1;
          when "1000" => x_720 <= x_720+1;
          --   when "1001" => null;
          when "1010" => x_720 <= x_720+1;
          --    when "1011" => null;
          when "1100" => x_720 <= x_720+1;
          --    when "1101" => null;
          when "1110" => x_720 <= x_720+1;
          when "1111" => x_720 <= x_720+1;
          when others => null;
        end case;

      end if;
    end if;
  end process;
end behavioral;
