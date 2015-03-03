open Mirage

let handler = foreign "Unikernel.Main" (console @-> network @-> network @-> stackv4 @-> stackv4 @-> job)

let net =
  try match Sys.getenv "NET" with
    | "direct" -> `Direct
    | "socket" -> `Socket
    | _ -> `Direct
  with Not_found -> `Direct

let dhcp =
  try match Sys.getenv "DHCP" with
    | "" -> false
    | _ -> true
  with Not_found -> false

let stack1 =
  match net, dhcp with
  | `Direct, true -> direct_stackv4_with_dhcp default_console tap0
  | `Direct, false -> direct_stackv4_with_default_ipv4 default_console tap0
  | `Socket, _ -> socket_stackv4 default_console [Ipaddr.V4.any]

let stack2 =
  match net, dhcp with
  | `Direct, true -> direct_stackv4_with_dhcp default_console (netif "1")
  | `Direct, false -> direct_stackv4_with_default_ipv4 default_console (netif "1")
  | `Socket, _ -> socket_stackv4 default_console [Ipaddr.V4.any]

let () =
  add_to_opam_packages ["mirage-http"];
  add_to_ocamlfind_libraries ["mirage-http"];
  register "stackv4" [
    handler $ default_console $ tap0 $ (netif "1") $ stack1 $ stack2;
  ]

