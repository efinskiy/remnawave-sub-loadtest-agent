# Remnawave subscription load tester

Load-tests the public Remnawave endpoint `GET /api/sub/{shortUuid}/{clientType}`
so you can measure how your **test** panel behaves under load and whether your
DDoS protection (rate-limiting / WAF / CDN) holds.

> ⚠️ **Use only on infrastructure you own or are explicitly authorized to test.**
> A heavy run can take a panel down. Don't point it at production or anything that
> isn't yours. Every binary requires an explicit `-i-own-this-instance` /
> `-i-am-authorized` confirmation flag.


## Distributed mode

```
                 +---------------------------+
   browser  -->  |  coordinator (web admin)  |  <-- agent (VPS #1)
   (admin)       |  :8080  Basic Auth        |  <-- agent (VPS #2)
                 +---------------------------+  <-- agent (VPS #3)
                          target = YOUR test panel
```

Agents only make **outbound** calls to the coordinator (register → poll job →
report metrics), so they work behind NAT/firewalls. Total offered load ≈
per-agent settings × number of agents.

### Run an agent on each load machine

```bash
./agent -coordinator http://CONTROL_HOST:8080 \
  -agent-token SOME_LONG_SHARED_SECRET \
  -i-am-authorized
```

Start as many as you like; each registers automatically and appears in the
dashboard. They pick up the next **Start**, run for the configured duration,
then idle until the next job.

