 `define STREAM_NP_FLAG_VEC      87:85
 `define STREAM_MSI_IF           84:76
 `define STREAM_TX_IF            75:0
 `define STREAM_NP_REQ_FLAG      87
 `define STREAM_NP_WRREQ_FLAG    86
 `define STREAM_NP_SOP_FLAG      85
 `define STREAM_APP_MSI_NUM      84:80
 `define STREAM_MSI_TC           79:77
 `define STREAM_MSI_VALID        76
 `define STREAM_TX_CPL_PEND      75
 `define STREAM_TX_ERR           74
 `define STREAM_SOP              73      // first cycle of transfer. always descriptor_hi cycle.
 `define STREAM_EOP              72      // last cycle of transfer
 `define STREAM_BYTEENA_BITS     81:74   // muxed be/bar bus. valid when data phase
 `define STREAM_BAR_BITS         71:64   // muxed be/bar bus. valid when descriptor phase
 `define STREAM_DATA_BITS        63:0    // muxed data/descriptor bus


