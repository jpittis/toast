# Toast

A simple layer 4, network failure testing proxy.

# Usage

The following line creates a proxy listening on port `1234` and forwarding to port `4321`.

````elixir
Toast.start(%Toast.Config{
  listen_port: 1234,
  upstream_port: 4321,
  latency: 0,
  blackhole: false
})
````


- The `latency` parameter delays data by the given number of milliseconds.

- The `blackhole` parameter stops all data from being forwarded.

- There is currently no way to force a connection to be killed. The easiest way to do this
  would be to simply kill a given connections `Proxy` process.
