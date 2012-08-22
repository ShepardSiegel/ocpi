// CTop.v - CTop with `define `include paramaterization

`ifdef USE_NDW1
`include "../../../mkCTop4B.v"
`elsif USE_NDW2
`include "../../../mkCTop8B.v"
`elsif USE_NDW4
`include "../../../mkCTop16B.v"
`elsif USE_NDW8
`include "../../../mkCTop32B.v"
`endif
