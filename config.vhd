library ieee;

use ieee.math_real.log2;

package automata is
  constant DISPLAY_WIDTH  : natural := 8; -- width of the display in pixels
  constant DISPLAY_HEIGHT : natural := 8; -- height of the display in pixels
  constant DISPLAY_BPP    : natural := 8; -- number of bits per pixel

  constant DATA_WIDTH : natural := DISPLAY_BPP;
  constant ADDR_WIDTH : natural := 6;

  constant DISPLAY_HEIGHT_LOG2 : natural := natural(log2(real(DISPLAY_HEIGHT)));
  constant DISPLAY_WIDTH_LOG2  : natural := natural(log2(real(DISPLAY_WIDTH)));
end automata;
