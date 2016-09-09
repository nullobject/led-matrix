library ieee;

use ieee.math_real.log2;

package automata is
  constant MATRIX_WIDTH  : natural := 8; -- width of the matrix in pixels
  constant MATRIX_HEIGHT : natural := 8; -- height of the matrix in pixels
  constant MATRIX_BPP    : natural := 8; -- number of bits per pixel

  constant DATA_WIDTH : natural := MATRIX_BPP;
  constant ADDR_WIDTH : natural := 6;

  constant MATRIX_HEIGHT_LOG2 : natural := natural(log2(real(MATRIX_HEIGHT)));
  constant MATRIX_WIDTH_LOG2  : natural := natural(log2(real(MATRIX_WIDTH)));
end automata;
