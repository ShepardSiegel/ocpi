// FTop_ml605.v - OCInf with `define `include paramaterization

`ifdef USE_NDW1
`include "../../../mkOCInf4B.v"
`elsif USE_NDW2
`include "../../../mkOCInf8B.v"
`elsif USE_NDW4
`include "../../../mkOCInf16B.v"
`elsif USE_NDW8
`include "../../../mkOCInf32B.v"
`endif
