// FTop_ml605.v - FTop for ml605 with `define `include paramaterization

`ifdef USE_NDW1
`include "../../../mkFTop_ml605_4B.v"
`elsif USE_NDW2
`include "../../../mkFTop_ml605_8B.v"
`elsif USE_NDW4
`include "../../../mkFTop_ml605_16B.v"
`elsif USE_NDW8
`include "../../../mkFTop_ml605_32B.v"
`endif
