# BOSH Release for Squid

This release deploys the [Squid](https://www.squid-cache.org/) caching web proxy as a forward proxy for HTTP and HTTPS traffic. The `squid` job runs one Squid instance on port 3128 by default, and its `acl` property holds the access control list that decides who can use the proxy and where they can go.

## Versions and stemcells

Release 2.0.0 builds Squid 7.7, which needs a C++17 compiler. We built and tested it on the resolute userland with GCC 15 and OpenSSL 3.5. The jammy and noble stemcells ship compilers new enough for C++17, so it should build there too, but we haven't tried. It doesn't compile on trusty, xenial, or bionic. If you deploy on one of those older stemcells, stay on release 1.1.0, which builds Squid 4.10.

Release 1.1.0 starts Squid with `chpst`, which comes with runit. The resolute stemcell no longer ships runit, so release 1.1.0 can't start there. Release 2.0.0 starts Squid with `setpriv` from util-linux instead, which every stemcell has, and Squid still runs as `vcap` from the start.

## Upgrading from 1.1.0

The job's template changed in a few ways for Squid 7:

- Squid 6 removed Gopher, so the template no longer has a `refresh_pattern` for `gopher:` URLs.

- Squid 7 dropped the `cache_object:` URL scheme and serves the cache manager only under `/squid-internal-mgr/`. The template no longer defines the `manager` ACL, because Squid defines it already.

- The template no longer defines the `localhost` ACL either, because Squid defines it already, and Squid 7 warns when a config redefines it.

- `shutdown_lifetime` is now 10 seconds. Squid waits that long for open connections on every shutdown, even when it is idle, and the default of 30 seconds outlasted the stop script's 20-second limit.

- When Squid is still running 20 seconds after the stop script asks it to exit, the script now kills Squid's worker process along with the master. Before, it killed only the master, so the worker could keep holding the port.

An `acl` property written for 1.1.0 still works. If it defines `acl CONNECT method CONNECT`, Squid 7 accepts the line as a harmless repeat of its built-in ACL.

The build leaves OpenSSL, GnuTLS, Kerberos, LDAP, and SASL out, as release 1.1.0 did. A forward proxy tunnels HTTPS with CONNECT, and that needs no TLS library in Squid.

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
