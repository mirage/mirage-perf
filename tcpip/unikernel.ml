(*
 * Copyright (C) 2015 University of Nottingham <masoud.koleini@nottingham.ac.uk>
 * Copyright (C) 2015 Balraj Singh <balraj.singh@cl.cam.ac.uk>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 *)

open Lwt
open V1_LWT
open Printf

let red fmt    = sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt  = sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt   = sprintf ("\027[36m"^^fmt^^"\027[m")

let msg = "0000 0001 0002 0003 0004 0005 0006 0007 0008 0009 0010 0011 0012 0013 0014 0015 0016 0017 0018 0019 0020 0021 0022 0023 0024 0025 0026 0027 0028 0029 0030 0031 0032 0033 0034 0035 0036 0037 0038 0039 0040 0041 0042 0043 0044 0045 0046 0047 0048 0049 0050 0051 0052 0053 0054 0055 0056 0057 0058 0059 0060 0061 0062 0063 0064 0065 0066 0067 0068 0069 0070 0071 0072 0073 0074 0075 0076 0077 0078 0079 0080 0081 0082 0083 0084 0085 0086 0087 0088 0089 0090 0091 0092 0093 0094 0095 0096 0097 0098 0099 0100 0101 0102 0103 0104 0105 0106 0107 0108 0109 0110 0111 0112 0113 0114 0115 0116 0117 0118 0119 0120 0121 0122 0123 0124 0125 0126 0127 0128 0129 0130 0131 0132 0133 0134 0135 0136 0137 0138 0139 0140 0141 0142 0143 0144 0145 0146 0147 0148 0149 0150 0151 0152 0153 0154 0155 0156 0157 0158 0159 0160 0161 0162 0163 0164 0165 0166 0167 0168 0169 0170 0171 0172 0173 0174 0175 0176 0177 0178 0179 0180 0181 0182 0183 0184 0185 0186 0187 0188 0189 0190 0191 0192 0193 0194 0195 0196 0197 0198 0199 0200 0201 0202 0203 0204 0205 0206 0207 0208 0209 0210 0211 0212 0213 0214 0215 0216 0217 0218 0219 0220 0221 0222 0223 0224 0225 0226 0227 0228 0229 0230 0231 0232 0233 0234 0235 0236 0237 0238 0239 0240 0241 0242 0243 0244 0245 0246 0247 0248 0249 0250 0251 0252 0253 0254 0255 0256 0257 0258 0259 0260 0261 0262 0263 0264 0265 0266 0267 0268 0269 0270 0271 0272 0273 0274 0275 0276 0277 0278 0279 0280 0281 0282 0283 0284 0285 0286 0287 0288 0289 0290 0291 "

let mlen = String.length msg

let usage_msg = "enter iperf command:
    1- target <server address> <server port> -- send traffic to target
    2- start -- sends traffic from port 1 to port 2
    2- stats -- reads statistics
    3- Reset -- resets port counters \n"
let usage_mlen = String.length usage_msg

let iperf_rx_port = 5001
let cmd_port = 8080

module Main
         (C:CONSOLE)(NCOM: NETWORK)(NLST: NETWORK)(COM:STACKV4)(LST:STACKV4) =
struct

  module TCOM  = COM.TCPV4
  module TLST  = LST.TCPV4

  let start console ncom nlst com lst =

    let buf = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 mlen in
    Cstruct.blit_from_string msg 0 buf 0 mlen;

    let usage_buf = Cstruct.sub (Io_page.(to_cstruct (get 1))) 0 usage_mlen in
    Cstruct.blit_from_string usage_msg 0 usage_buf 0 usage_mlen;

    Lwt_list.iter_s (fun ip ->
        C.log_s console
          (sprintf "IP address: %s\n"
             (Ipaddr.V4.to_string ip))) (COM.IPV4.get_ip (COM.ipv4 com))
    >>
    C.log_s console
      (green "ready to receive command connections on port %d" cmd_port)
    >>= fun () ->
    COM.listen_tcpv4 com cmd_port (

      let rec snd outfl n = match n with
        | 0 -> C.log_s console (red "iperf client: done") >> TCOM.close outfl
        | _ ->
          TCOM.write outfl buf >>
          snd outfl (n - 1)
      in

      let sendth dst port =
        COM.TCPV4.create_connection (COM.tcpv4 com) (dst, port) >>= function
        | `Ok outfl -> C.log_s console (red "connected") >> snd outfl 200000
        | `Error e -> C.log_s console (red "connect: error")
      in

      let rec cmd_loop n f =
        TCOM.read f
        >>= function
        | `Ok b ->
          let msg = (Cstruct.to_string
                       (Cstruct.sub b 0 ((Cstruct.len b) - 2))) in
          let i =
            String.(if contains msg ' ' then index msg ' ' else (length msg))
          in
          let cmd = String.sub msg 0 i in
          (
            match cmd with
            | "target" ->
              let msg_s = String.sub msg (i+1) ((String.length msg) - i-1) in
              let i = String.index msg_s ' ' in
              let d_ip_s = String.sub msg_s 0 i in
              let d_prt_s = String.sub msg_s (i+1) ((String.length msg_s) - i-1) in
              let dst = (Ipaddr.V4.of_string_exn d_ip_s) in
              let dst_p = int_of_string d_prt_s in

              let _ = NCOM.reset_stats_counters ncom in
              let _ = NLST.reset_stats_counters nlst in

              let _ = sendth dst dst_p in
              C.log_s console
                (yellow "attempting iperf connection to: %s:%s\n"
                   d_ip_s d_prt_s
                )
              >>
              cmd_loop (n + (Cstruct.len b)) f

            | "start" ->
              let ip = List.hd (LST.IPV4.get_ip (LST.ipv4 lst)) in
              let _ = sendth ip iperf_rx_port in
              C.log_s console
                (yellow "attempting iperf connection to: %s:%d\n"
                   (Ipaddr.V4.to_string ip) iperf_rx_port
                )
              >>
              cmd_loop (n + (Cstruct.len b)) f

            | "stats" ->
              C.log_s console (yellow "information requested\n")
              >>
              let stats_s = NCOM.get_stats_counters ncom in
              let stats_r = NLST.get_stats_counters nlst in
              let msg_stat =
                String.concat " "
                  ["rx_bytes: "; Int64.to_string stats_r.rx_bytes; "\n";
                   "rx_pkts: " ; Int32.to_string stats_r.rx_pkts;  "\n";
                   "tx_bytes: "; Int64.to_string stats_s.tx_bytes; "\n";
                   "tx_pkts: " ; Int32.to_string stats_s.tx_pkts;  "\n"]
              in
              C.log_s console (yellow "%s\n" msg_stat) >>
              let stats_buf =
                Cstruct.sub
                  (Io_page.(to_cstruct (get 1))) 0 (String.length msg_stat)
              in
              Cstruct.blit_from_string msg_stat 0 stats_buf 0 (String.length msg_stat);
              TCOM.write f stats_buf >>
              cmd_loop (n + (Cstruct.len b)) f

            | "reset" ->
              C.log_s console (yellow "Reset statistics requested\n")
              >>
              let _ = NCOM.reset_stats_counters ncom in
              let _ = NLST.reset_stats_counters nlst in
              let stats_s = NCOM.get_stats_counters ncom in
              let stats_r = NLST.get_stats_counters nlst in
              let msg_stat =
                String.concat " "
                  ["rx_bytes: "; Int64.to_string stats_r.rx_bytes; "\n";
                   "rx_pkts: " ; Int32.to_string stats_r.rx_pkts;  "\n";
                   "tx_bytes: "; Int64.to_string stats_s.tx_bytes; "\n";
                   "tx_pkts: " ; Int32.to_string stats_s.tx_pkts;  "\n"]
              in
              C.log_s console (yellow "%s\n" msg_stat) >>
              let stats_buf =
                Cstruct.sub (Io_page.(to_cstruct (get 1)))
                  0 (String.length msg_stat)
              in
              Cstruct.blit_from_string msg_stat 0 stats_buf 0 (String.length msg_stat);
              TCOM.write f stats_buf >>
              cmd_loop (n + (Cstruct.len b)) f

            | c ->
              C.log_s console (red "uknown command - %s - read: %d bytes " c n)
              >> cmd_loop (n + (Cstruct.len b)) f

          )
        | `Eof -> TCOM.close f >>
          C.log_s console
            (red "cmd connection closed - read: %d bytes " n)
        | `Error e -> C.log_s console (red "read: error")
      in
      fun flow ->
        let dst, dst_port = TCOM.get_dest flow in
        TCOM.write flow usage_buf >>
        C.log_s console
          (green "new command connection from %s %d"
             (Ipaddr.V4.to_string dst) dst_port
          )
        >>
        C.log_s console
          (green "%s" usage_msg)
        >>
        cmd_loop 0 flow
    );


    C.log_s console
      (green "ready to receive iperf connections on port %d" iperf_rx_port)
    >>= fun () ->
    LST.listen_tcpv4 lst iperf_rx_port (
      let rec iperf_rx_loop n f =
        fun () ->
          TLST.read f
          >>= function
          | `Ok b ->
            return() >>= iperf_rx_loop (n + (Cstruct.len b)) f
          | `Eof ->
            TLST.close f >> C.log_s console (red "iperf received: %d bytes" n)
          | `Error e -> C.log_s console (red "read: error")
      in
      fun flow ->
        let dst, dst_port = TLST.get_dest flow in
        C.log_s console
          (green "new iperf connection from %s %d"
             (Ipaddr.V4.to_string dst) dst_port
          )
        >>=
        iperf_rx_loop 0 flow
    );

    let periodic_print time =
      while_lwt true do
        OS.Time.sleep time >>
        let ip = List.hd (COM.IPV4.get_ip (COM.ipv4 com)) in
        C.log_s console (sprintf "IP address: @%s@\n" (Ipaddr.V4.to_string ip))
      done
    in

    lwt _ = (COM.listen com) <&> (LST.listen lst) <&> (periodic_print 1.0) in
    return ()
end
