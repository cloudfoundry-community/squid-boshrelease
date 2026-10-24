# Squid 7.7, and support for the resolute stemcell

- The release now builds Squid 7.7 instead of Squid 4.10. Squid 7 needs a C++17 compiler, so this release doesn't compile on trusty, xenial, or bionic, and deployments on those stemcells should stay on release 1.1.0. We built and tested it on resolute and noble, and we support it on ubuntu-noble and later stemcells. Jammy's compiler can build it, but we don't support jammy, so deployments there should stay on release 1.1.0 as well.

- The job now starts Squid with `setpriv` from util-linux instead of `chpst` from runit, because the resolute stemcell no longer ships runit. Squid runs as `vcap` from the start, with the `vcap` group and no supplementary groups, and with the no-new-privileges flag set.

- The template no longer has a `refresh_pattern` for `gopher:` URLs, because Squid 6 removed Gopher.

- The template no longer defines the `manager` and `localhost` ACLs, because Squid defines both. Squid 7 serves the cache manager only under `/squid-internal-mgr/`, since it dropped the `cache_object:` scheme.

- `shutdown_lifetime` is now 10 seconds. Squid waits that long on every shutdown, even when it's idle, and the default of 30 seconds outlasted the stop script's 20-second limit.

- When Squid outlives that limit, the stop script now kills Squid's worker process along with the master, so the worker no longer keeps holding the port.

- The start and stop scripts kill leftover processes from the squid package, which they find by the path of the binary. A worker left behind when the master dies by SIGKILL used to keep the port and the old configuration forever.

- The scripts check that the pidfile's process runs the squid binary before they trust it, so a reused PID is never signalled. A stop with no pidfile exits 0, and each stop logs when it finishes.

- The template denies requests to loopback and link-local destinations, through Squid's built-in `to_localhost` and `to_linklocal` ACLs, and to the VM's own address through a `to_self` ACL, before any rule that allows clients. Clients can no longer reach the proxy's own services or the cloud metadata service at 169.254.169.254 through it.

- Squid's cache log goes to `/var/vcap/sys/log/squid/cache.log` instead of `/dev/null`, and the BOSH agent rotates it with the other job logs.

- The log directory belongs to root, and `squid.log`, which holds the scripts' output, belongs to root too, so `vcap` can no longer redirect root's writes with a symlink.

- The template refuses a port below 1024, because Squid runs as `vcap` without any capabilities and can't bind one.

- The default `acl` property from 1.1.0 works on this release. An `acl` that uses an LDAP, Kerberos, or SASL authentication helper or a TLS option won't, because this build leaves those libraries out.

- Moving a deployment from xenial to resolute recreates the VM. On noble, the upgrade stops 1.1.0 in place, and the new start script kills any 1.1.0 process still running.
