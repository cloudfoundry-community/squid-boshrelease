# Bug Fixes

- The `squid` job now forcibly terminates the squid process if it
  doesn't shutdown gracefully from the SIGTERM within 20s.  This
  should stop the errors reported by bosh-agent when trying to
  `monit stop squid`.
