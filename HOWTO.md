# Running a simulation

First, we need some aliases

```elixir
iex(1)> alias Disssim.Model.Resource
Disssim.Model.Resource
iex(2)> alias Disssim.Model.Service
Disssim.Model.Service
iex(3)> alias Disssim.Model.Client
Disssim.Model.Client
```

Next we create 3 rsources sharing the same configuration

```elixir
iex(4)> resource_opts = [min_latency: 10, max_latency: 100, fail_rate: 0.25, concurrency: 10]
[min_latency: 10, max_latency: 100, fail_rate: 0.25, concurrency: 10]
iex(5)> {:ok, res_1} = Resource.start resource_opts
{:ok, #PID<0.234.0>}
iex(6)> {:ok, res_2} = Resource.start resource_opts
{:ok, #PID<0.248.0>}
iex(7)> {:ok, res_3} = Resource.start resource_opts
{:ok, #PID<0.262.0>}
```

Now we create a single service which is is going to use our 3 resources

```elixir
iex(8)> svc_opts = [resources: [res_1, res_2, res_3], concurrency: 10]
[resources: [#PID<0.234.0>, #PID<0.248.0>, #PID<0.262.0>], concurrency: 10]
iex(9)> {:ok, svc} = Service.start svc_opts
{:ok, #PID<0.278.0>}
```

Now we need a client to invoke our service. Request rate is given in reqs/sec. This is important to understand de last example in this guide.

```elixir
iex(10)> client_opts = [service: svc, request_rate: 50]
[service: #PID<0.278.0>, request_rate: 50]
iex(11)> {:ok, client} = Client.start client_opts
{:ok, #PID<0.282.0>}
```

We are ready to go!

We'll start by sending a single request from our client

```elixir
iex(12)> Client.call_once client, {:request, "hello"}

10:56:22.032 [debug] Handling svc request from #PID<0.277.0>

10:56:22.041 [debug] Handling res request from #PID<0.233.0>

10:56:22.093 [debug] Handling res request from #PID<0.247.0>

10:56:22.187 [debug] Handling res request from #PID<0.261.0>
{:response,
 "call from #PID<0.277.0>-98 || call from #PID<0.277.0>-94 || call from #PID<0.277.0>-89",
 [req_time: 187]}
```

In the logs you can see that de request was handled once from a service proces and there were 3 different calls to resource procesess.

Lets send more than one request in a single shot. Remember de `request_rate` parameter we used for our client? it is set `50 reqs/sec`. Because of this, there will be a `20 ms` delay between each request from our client.

```elixir
iex(13)> Client.call_n_times client, {:request, "hello"}, 3

11:01:06.917 [debug] Calling service #PID<0.278.0> from client #PID<0.282.0> n: 1

11:01:06.926 [debug] Client #PID<0.282.0> waiting for 20 ms

11:01:06.926 [debug] Handling svc request from #PID<0.276.0>

11:01:06.926 [debug] Handling res request from #PID<0.232.0>

11:01:06.947 [debug] Calling service #PID<0.278.0> from client #PID<0.282.0> n: 2

11:01:06.947 [debug] Client #PID<0.282.0> waiting for 20 ms

11:01:06.948 [debug] Handling svc request from #PID<0.275.0>

11:01:06.948 [debug] Handling res request from #PID<0.231.0>

11:01:06.967 [debug] Handling res request from #PID<0.246.0>

11:01:06.968 [debug] Calling service #PID<0.278.0> from client #PID<0.282.0> n: 3

11:01:06.968 [debug] Client #PID<0.282.0> waiting for 20 ms

11:01:06.969 [debug] Handling svc request from #PID<0.274.0>

11:01:06.969 [debug] Handling res request from #PID<0.230.0>

11:01:06.989 [debug] Handling res request from #PID<0.245.0>

11:01:07.024 [debug] Handling res request from #PID<0.260.0>

11:01:07.060 [debug] Handling res request from #PID<0.244.0>

11:01:07.079 [debug] Handling res request from #PID<0.259.0>

11:01:07.090 [debug] Handling res request from #PID<0.258.0>

:ok
iex(14)>

```

Besides the logs from the service and resource processes, this time we can see some logs from our client, informing us in which request it is working on and the delay between requsts.

And there you have it. Go on and try some simulations yourself!
