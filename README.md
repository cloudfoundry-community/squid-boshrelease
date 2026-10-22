# BOSH Release for Squid

This release deploys the [Squid](https://www.squid-cache.org/) caching web proxy as a forward proxy for HTTP and HTTPS traffic. The `squid` job runs one Squid instance on port 3128 by default, and its `acl` property holds the access control list that decides who can use the proxy and where they can go.

## Versions and stemcells

Release 2.0.0 builds Squid 7.7, which needs a C++17 compiler, and we support it on ubuntu-noble and later stemcells. We built and tested it on the ubuntu-noble 1.562 stemcell, where it compiled and served traffic, and on the resolute userland with GCC 15. It doesn't compile on trusty, xenial, or bionic, and we don't support it on jammy. Release 1.1.0, which builds Squid 4.10, is the last release for those older stemcells.

Release 1.1.0 starts Squid with `chpst`, which comes with runit. The resolute stemcell no longer ships runit, so release 1.1.0 can't start there. Release 2.0.0 starts Squid with `setpriv` from util-linux instead, which every stemcell has. Squid runs as `vcap` from the start, with the `vcap` group and no supplementary groups, so it doesn't pick up the other groups that `vcap` belongs to on a stemcell, such as `adm`, `cdrom`, and `sudo`. `setpriv` also sets the no-new-privileges flag, so Squid and its helpers can't gain privileges through a setuid program.

Squid runs without any capabilities, so it can't bind a port below 1024. The template refuses such a port when BOSH renders it, so the deploy fails with a clear message instead of a proxy that never listens.

## Upgrading from 1.1.0

The job's template changed in a few ways for Squid 7:

- Squid 6 removed Gopher, so the template no longer has a `refresh_pattern` for `gopher:` URLs.

- Squid 7 dropped the `cache_object:` URL scheme and serves the cache manager only under `/squid-internal-mgr/`. The template no longer defines the `manager` ACL, because Squid defines it already.

- The template no longer defines the `localhost` ACL either, because Squid defines it already, and Squid 7 warns when a config redefines it.

- `shutdown_lifetime` is now 10 seconds. Squid waits that long for open connections on every shutdown, even when it is idle, and the default of 30 seconds outlasted the stop script's 20-second limit.

- When Squid is still running 20 seconds after the stop script asks it to exit, the script now kills Squid's worker process along with the master. Before, it killed only the master, so the worker could keep holding the port.

- The start and stop scripts now look for leftover processes from the squid package and kill them. When something kills the master with SIGKILL, its worker keeps running on its own and keeps the port, and before this change nothing ever stopped it. The scripts find these processes by the path of the binary they run, not by name.

- The scripts no longer trust the pidfile on its own. They check that its process runs the squid binary before they signal it, so a process that reused the PID of a dead Squid is never touched. A stop with no pidfile now exits 0, and every stop logs when it finishes and how long it took.

- The template now denies requests to loopback and link-local destinations, using Squid's built-in `to_localhost` and `to_linklocal` ACLs, and to the VM's own address through a `to_self` ACL, before any rule that allows clients. A client that the `acl` property allows can no longer reach services on the proxy's own interfaces or the cloud metadata service at 169.254.169.254 through the proxy.

- Squid's cache log now goes to `/var/vcap/sys/log/squid/cache.log` instead of `/dev/null`, so startup failures, such as a port that won't bind, are visible. The BOSH agent rotates it with the other job logs, and `logfile_rotate 0` keeps Squid from renaming its own logs.

- The log directory is now owned by root. Squid's own logs, `access.log` and `cache.log`, still belong to `vcap`, while `squid.log`, which holds the start and stop scripts' output, belongs to root. Before, `vcap` owned the directory, so a compromised Squid could have replaced `squid.log` with a symlink and made the scripts append to any file on the VM.

The default `acl` property from 1.1.0 works unchanged. If it defines `acl CONNECT method CONNECT`, Squid 7 accepts the line as a harmless repeat of its built-in ACL. An `acl` that uses an authentication helper for LDAP, Kerberos, or SASL, or any TLS option, won't work, because this build leaves those libraries out, and an `acl` that uses a directive Squid has since removed won't parse.

The build turns off OpenSSL, GnuTLS, Kerberos, LDAP, and SASL by name. A forward proxy tunnels HTTPS with CONNECT, and that needs no TLS library in Squid. Release 1.1.0 ran `configure` without those flags, so its build used whichever of those libraries the compiling stemcell happened to have.

Moving a deployment from xenial to resolute changes the stemcell, so BOSH recreates the VM, and nothing from release 1.1.0 is left running on it. On jammy or noble, the upgrade stops 1.1.0 in place, and the new start script kills any 1.1.0 process that is still running before it starts Squid 7.

## Usage

Upload the release to your director, and then deploy it with a manifest that uses the `squid` job:

```
bosh upload-release squid-2.0.0.tgz
bosh -d squid deploy squid.yml
```

The [Squid Genesis kit](https://github.com/genesis-community/squid-genesis-kit) builds that manifest for you, and its `resolute` feature selects this release on the resolute stemcell.

## Development

To build a dev release from this checkout and upload it, run:

```
bosh create-release --force --tarball /tmp/squid-dev.tgz
bosh upload-release /tmp/squid-dev.tgz
```

To bump the Squid version, download the new tarball from squid-cache.org, check its signature, and replace the blob:

```
bosh remove-blob squid/squid-7.7.tar.gz
bosh add-blob squid-7.8.tar.gz squid/squid-7.8.tar.gz
```

Then update the file name in `packages/squid/spec` and the version in `packages/squid/packaging`.

Cutting a final release needs `config/private.yml` with the blobstore credentials. Run `bosh upload-blobs` first, and then `bosh create-release --final --version <version>`.
