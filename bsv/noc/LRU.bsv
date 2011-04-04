package LRU;

// This is a simple implementation of a least-recently-used arbiter
// in the style of a matrix arbiter.

import Vector :: *;

// Each channel can make a request and test if it received the grant
interface LRUChannel;
   (* always_ready *)
   method Action request();
   (* always_ready *)
   method Bool grant();
endinterface: LRUChannel

// An LRU module can have any number of channels
interface LRU#(numeric type n);
   (* always_ready *)
   method Action enable();
   interface Vector#(n,LRUChannel) channel;
endinterface: LRU

// This module implements the LRU logic for any number of channels
//
// TODO: Ensure that synthesis minimizes this logic, or hand-optimize
//       it.  We only need to store the upper triangle of the matrix,
//       since the diagonal will always be 0, and m[i][j] = !m[j][i].
//       Also, see if we can reduce logic by not accounting for
//       multiple possible grant matches.

module mkLRU(LRU#(n));

   // A matrix where m[i][j] is True iff i was given the grant more recently
   // than j.
   Reg#(Vector#(n,Vector#(n,Bool))) more_recent_than <- mkReg(replicate(replicate(False)));

   PulseWire enabled <- mkPulseWireOR();

   // Request and grant lines
   Vector#(n,PulseWire) requests <- replicateM(mkPulseWire());
   Vector#(n,PulseWire) grants   <- replicateM(mkPulseWire());

   function Bool readPW(PulseWire pw);
      return pw;
   endfunction

   // To choose the LRU out of all the active requests, examine each request's
   // row, mask it with the set of active requests and choose one which yields
   // all 0s.
   //
   // When a grant is given, the matrix is updated by setting all bits in the
   // grant's row and then clearing all bits in the grant's column.

   (* fire_when_enabled, no_implicit_conditions *)
   rule do_grant if (enabled);

      // Choose the first requestor that has not been given the grant
      // more recently than any other requestor. There may be multiple
      // at first, but once each requester has been given the grant once,
      // there will only be one most recent grantee.

      Bool granted = False;
      Integer grant_to = 0;
      for (Integer i = 0; i < valueOf(n); i = i + 1) begin
         if (requests[i]) begin
            // give up the grant to any requester less recent than ourselves
            let defer_to = zipWith(\&& , more_recent_than[i], map(readPW,requests));
            if (defer_to == replicate(False) && !granted) begin
               // if there is no one to defer to and this is the first such requestor,
               // then grant the request
               grants[i].send();
               granted = True;
               grant_to = i;
            end
         end
      end
      // Update the matrix if a grant has been given
      if (granted) begin
         Vector#(n,Vector#(n,Bool)) new_m = more_recent_than;
         // grantee is more recent than all
         for (Integer i = 0; i < valueOf(n); i = i + 1)
            new_m[grant_to][i] = True;
         // none is more recent than the grantee
         for (Integer i = 0; i < valueOf(n); i = i + 1)
            new_m[i][grant_to] = False;
         more_recent_than <= new_m;
      end
   endrule

   // connect the request and grant PulseWires to the interface

   function LRUChannel mk_channel(Integer n);
      return (interface LRUChannel;
                 method Action request();
                    requests[n].send();
                 endmethod
                 method Bool grant();
                    return grants[n];
                 endmethod
              endinterface);
   endfunction

   method Action enable();
      enabled.send();
   endmethod

   interface channel = genWith(mk_channel);

endmodule: mkLRU

endpackage: LRU
