# prometheus-lite

A product-neutral slim fork of [Prometheus](https://github.com/prometheus/prometheus),
pinned to upstream `v3.14.0` (Apache-2.0).

This repository keeps only Prometheus metric and query semantics: the label
model, PromQL parser and query engine, storage query/append interfaces, and the
pure chunk codecs. The server, web UI, scrape and service discovery, rules and
notifier, remote storage, agent, WAL, local TSDB, and filesystem backends are
removed. Storage is supplied by consumers through injected interfaces.

The fork imports no product-specific packages.
