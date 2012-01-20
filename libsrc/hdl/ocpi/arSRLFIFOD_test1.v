// arSRLFIFOD_test1
// Copyright (c) 2012 Atomic Rules LLC - ALL RIGHTS RESERVED

module arSRLFIFOD_test1 # (
  parameter  width    = 128,
  parameter  l2depth  = 4)
  (
  input              CLK,
  input              RST_N,
  input              CLR,
  input              ENQ,
  input              DEQ,
  output             FULL_N,
  output             EMPTY_N,
  input [width-1:0]  D_IN,
  output[width-1:0]  D_OUT
);

 arSRLFIFOD # (
    .width    (width),
    .l2depth  (l2depth)
   )
 arSRLFIFOD_i0 (
    .CLK      (CLK),
    .RST_N    (RST_N),
    .CLR      (CLR),
    .ENQ      (ENQ),
    .DEQ      (DEQ),
    .FULL_N   (FULL_N),
    .EMPTY_N  (EMPTY_N),
    .D_IN     (D_IN),
    .D_OUT    (D_OUT)
   );

endmodule
