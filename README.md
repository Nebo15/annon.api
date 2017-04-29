# Annon

[![Coverage Status](https://coveralls.io/repos/github/Nebo15/annon.api/badge.svg?branch=master&t=y562b4)](https://coveralls.io/github/Nebo15/annon.api?branch=master) [![Build Status](https://travis-ci.com/Nebo15/annon.api.svg?token=zWpL5QGwyvH4Pcxi8Vav&branch=master)](https://travis-ci.org/Nebo15/annon.api)

# Annon API Gateway

Annon is a configurable API gateway that acts as a reverse proxy with a plugin system. Plugins allow to reduce boilerplate that must be done in each service, making overall development faster. Also it stores all requests, responses and key metrics, making it easy to debug your application. Inspired by [Kong](https://getkong.org/).

It's free. Source code is available on [GitHub](https://github.com/Nebo15/annon.api).

> "Annon" translates from the Sindarin word for 'Great Door or Gate'. Sindarin is one of the many languages spoken by the immortal Elves.

Annon consist of multiple main parts:

- [Annon API Gateway](https://github.com/Nebo15/annon.api).
- [Annon Dashboard](https://github.com/Nebo15/annon.web) - UI that allows to manage Annon settings, review and analyze Requests.
- [EView](https://hex.pm/packages/eview) - hex package that allows to receive and modify client responses from Elixir application to match [Nebo #15 API Manifest](http://docs.apimanifest.apiary.io/). So your back-ends will respond in a same way as Annon does.
- [Mithril](https://github.com/Nebo15/mithril.api) - authentication and role management service.

## Goals of the Project

- Provide single management/monitoring system for medium-to-large scale applications.
- Reduce amount of work needed in other componens by orchestrating common functionalities.
- Control response time and get answer "what happened" even in a single request perspective. Provide data for in-deepth service analysis.
- Improve platform scalability.

## General Features

### Caching and Perfomance

For perfomance issues Annon has build-in cache manager, it will load data from DB only once, all futher work will be based on this cached data.

Whenever a single node receives request that changes cached data, it's responsible to notify all other nodes in cluster about change, and they should reload configurations from DB.

Whenever new node joins to a cluster, all other nodes should drop their cache, to resolve consistency issues.

This feature is done via [skycluster](https://github.com/Nebo15/skycluster) package. All gateway nodes is connected via Erlang distribution protocol.
It support different discovery strategies:

- `kubernetes` - selecting pods via Kubernetes API;
- `gossip` - multicast UDP gossip, using a configurable port/multicast address;
- `epmd` - using standart Erlang Port Mapper Daemon.

### Request ID's

When receiving request gateway will generate unique `request_id`. It is used to log request and this request is sent to all upstream, so whole back-ends that is affected by a request will create logs with same request id's.

Optionally, you can send `X-Request-ID` header with your own request id, but you need to make sure that its length not less than 20 characters. Also, if should be unique, or you will receive error response.

### Request Logger

Annon stores all requests and responses by their unique Request ID's in a Cassandra database. You use this information to query requests and get base analytics via [Requests API](#reference/requests/collection/get-all-requests).

API consumers may provide a custom request ID by sending `X-Request-ID: <request_id>` header. Thus, your Front-End and upstream back-ends can log information with a single unique ID.

Also, idempotency plug is relying on this logs to privide idempotency guaratees for requests with same `X-Idempotency-Key: <idempotency_key>` headers.

### Monitoring

To monitor services status we will use DogStatsD integration, that will receive following metrics:

- `request_count` - (counter) [API](#reference/apis) hit rate.
- `request_size` - (gauge) HTTP request size.
- `response_count` - (counter) same as `request_count` but sent after request dispatch and additionally tagged with `http_status`.
- `latency` (gauge) - total request latency for a API consumer, additionally tagged with `http_status`.

All metrics have tags: `http_host`, `http_port`, `http_method`, `api_name` and `api_id` (if matches any), `request_id`. This allows to set different aggregated views on counter data.

We recommend you to try [DataDog](https://www.datadoghq.com/) for collecting and displaying perfomance metrics. But this is not a hard containt, instead you can use any StatsD collector.

### Requests Idempotency

Annon guarantess that replayed requests with same `X-Idempotency-Key: <key>` and same request will get permanent response. This is useful in a financial application, where you need good protection from duplicate user actions.

### Requests Tracing

Annon supports [OpenTracing](http://opentracing.io/) in Erlang via [Otter](https://github.com/Bluehouse-Technology/otter) libruary. This means that by implementing OpenTracing API in other services you can trace complete request impact for each of your services.

## Installation

Annon can be installed by compiling it from sources, but we recommend you to use our pre-build Docker containers:

- [Annon API Gateway](https://hub.docker.com/r/nebo15/annon.api/);
- [Annon Dashboard](https://hub.docker.com/r/nebo15/annon.web/);
- [Cassandra](https://hub.docker.com/r/nebo15/alpine-cassandra/).

Our containers are based on Alpine Linux wich is a security-oriented, lightweight Linux distribution based on musl libc and busybox.

### Kubernetes

You can deploy it to Kubernetes using [example configs from Annon's Infra repo](https://github.com/Nebo15/annon.infra/blob/master/kubernetes).

### Docker Compose

For local environments we provide an example Docket Compose configuration, that will allow you to spin all containers in just a few commands.

## Documentation

You can find full documentation on official [Apiary](http://docs.annon.apiary.io/) page.

Also there are auto-generated code documentation [available here](https://nebo15.github.io/annon.api/api-reference.html#content).

## License

See [LICENSE.md](LICENSE.md).
