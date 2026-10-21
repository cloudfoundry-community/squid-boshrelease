# Squid 7.7, and support for the resolute stemcell

- The release now builds Squid 7.7 instead of Squid 4.10. Squid 7 needs a C++17 compiler, so this release doesn't compile on trusty, xenial, or bionic, and deployments on those stemcells should stay on release 1.1.0. We built and tested it on resolute, and jammy and noble ship compilers new enough for it.

- The job now starts Squid with `setpriv` from util-linux instead of `chpst` from runit, because the resolute stemcell no longer ships runit. Squid still runs as `vcap` from the start.

- The template no longer has a `refresh_pattern` for `gopher:` URLs, because Squid 6 removed Gopher.

- The template no longer defines the `manager` and `localhost` ACLs, because Squid defines both. Squid 7 serves the cache manager only under `/squid-internal-mgr/`, since it dropped the `cache_object:` scheme.

- `shutdown_lifetime` is now 10 seconds. Squid waits that long on every shutdown, even when it's idle, and the default of 30 seconds outlasted the stop script's 20-second limit.

- When Squid outlives that limit, the stop script now kills Squid's worker process along with the master, so the worker no longer keeps holding the port. The script also cancels its watchdog once Squid exits, so the watchdog can't hit a reused process ID.

- An `acl` property written for 1.1.0 still works on this release.
