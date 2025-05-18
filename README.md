# macos-route-monitor

A hacky thing to dump and watch the MacOS routing table, outputting JSON.

Uses `/usr/bin/ruby`.

It's intended to be run under the control of daemontools `supervise`, but that's not a hard requirement.

```shell
./run
```

Every line produced to standard output is a JSON object. Output is line-buffered.

## Output

(Probably) the first object produced represents the current routing table. Subsequent objects represent routing events.

### Routing table object

- `_raw`: the raw text as produced by `netstat -rn`
- `warnings`: describes any problems encountered parsing `_raw`
- `ipv4_routes` / `ipv6_routes`: arrays of routes, where each route is an object:
  - `destination`
  - `gateway`
  - `flags`
  - `netif`
  - `expire`

### Routing event object

- `_raw`: the raw text as produced by `route -n monitor`
- `time`: the epoch time of the event
- `warnings`: describes any problems encountered parsing `_raw`
- `preamble`: no useful data tbh
- `header`:
  - `_raw`
  - `verb`: `RTM_ADD` and so forth
  - `description` (of the verb)
  - `props`:
    - `_raw`
    - `flags`
    - ...
- `sections`: array of union of:
  - locks\_inits:
    - `type`: "locks\_inits"
    - unsure what this is
  - sockaddrs:
    - `type`: "sockaddrs"
    - something describing socket addresses 🤷🏻‍♀️

## Miscellaneous scripts

- `make-raw` — a filter. Only output `_raw` and `time`
- `no-raw` — a filter. Discard `_raw`.
- `only-json` — a filter. Strip off any leading `tai64n` timestamp, and only output lines starting with `{`
- `reparse`
  - as a filter: Take the `_raw` text and parse it again
  - otherwise (stdin is a tty): run `./tail` (passing along any arguments), and filter, as above
- `summarise`
- `tail [--all] [OPTIONS]` — tails the current log, passing along any options to `tail (1)`. If `--all` is specified, then archived logs are processed too, before the current log.
