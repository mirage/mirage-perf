# Performance regression testing for Mirage

Test environment
----------------

XenServer with internet/network connection for the performance testing script to
download required packages, for the unikernel to request IP address from DHCP
server, and for the user machine to send commands and retrieve statistics.

To use
------

Run the following command on the Xen server:

```
scripts/mir-perf.sh <address> <password> <library> <duration>
```

+ `address` is the IP address of the XenServer.
+ `password` is the root password for the XenServer.
+ `library` is the name of the MirageOS library for the performance test, e.g., `tcpip` tests the @mirage/tcpip
library.
+ `duration` Performance regression testing continues for the duration time for the
maximum of 200,000 packets.
