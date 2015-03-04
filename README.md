# Performance regression testing for Mirage

Test environment
----------------

XenServer with internet/network connection for the performance testing script to download required packages, for the unikernel to request IP address from DHCP server, and for the user machine to send commands and retrieve statistics.

To use
------

Run the following command on the Xen server:

```
chmod +x scripts/*.sh
scripts/mir-perf.sh <XenServer address> <XenServer root password> <library> <duration>
```
or
```
bash scripts/mir-perf.sh <XenServer address> <XenServer root password> <library> <duration>
```

```library``` is the name of mirage library for the performance test. For example, you can use tcpip for the performance test over tcpip library. Performance regression testing continues for the duration time for the maximum of 200'000 packets.
