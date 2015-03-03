# Performance regression test scrip for Mirage libraries

Test environment
----------------

XenServer with internet/network connection for the performance test script to download required packages, for the unikernel to request IP address from DHCP server, and for the user machine to send commands and retrieve statistics.

To use
------

Run the following command on the Xen server:

```
bash mir-perf.sh <XenServer address> <XenServer root password> <library> <Run time>
```

```library``` is the name of mirage library for the performance test. For example, you can use tcpip for the performance test over tcpip library. 
