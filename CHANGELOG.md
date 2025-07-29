# Changelog

## 0.12.2

- Added `Search.delete_by_query` function to perform delete operations against an index

## 0.12.1

- Support parsing the extra fields in suggest options that come back from a completion query

## 0.12.0

- Relax Finch dependency to 0.17, which is the lowest version that emit pool metrics

## 0.11.3

- Added new fields to telemetry measurements, `request_body_bytes` and `response_body_bytes`, for logging the size of the request and response

## 0.11.2

- Added new `Snap.Indexes` utility functions to get and set mappings, settings and more (thanks @warmwaffles)
- Added Elixir 1.17 to CI matrix

## 0.11.1

- Added `sort` field to `Snap.Hit` struct
- Added `routing` param to `Snap.Bulk` actions
- Added `get_mapping` and `update_mapping` functions to `Snap.Indexes`
- Added `status` attribute to telemetry metadata, representing the HTTP status code of the response, if any

## 0.11.0

- Breaking change: changed the field names in `Snap.Bulk` actions to drop underscore prefix
- Added support for pluggable JSON libraries. Continues to default to `Jason`, but you may see encoding/decoding performance improvements from switching to `Jsonrs`
- Allowed `nil` for the `type` in `Snap.Hit` as ElasticSearch >= 8 does not return this

## 0.10.0

- Enabled gzip compression in default HTTP adapter using `Accept-Heading` header, which speeds up large response objects

## 0.9.0

- Added `Snap.Document` for interacting with individual documents
- Added `count/3` to `Snap.Search` for performing counts with or without a query
- Added support for index namespacing to isolate different Snap application, environments and even process from seeing each other's indexes - see `Snap.Cluster.Namespace` and `Snap.Test` for details

## 0.8.1

- Upgrade `finch`, which allows use of `castore` 1.0
- Set minimum Elixir version to 1.12

## 0.8.0

- Add a high level interface for the [Multi Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html)

## 0.7.0

- Changed `inner_hits` to be `Snap.Hits` struct to make it consistent with the `hits` at the top level
- Added support for `suggest` (thanks @maennchen)
- Relaxed telemetry dependency to allow the use of 0.4 as well as 1.0 (thanks @dershodan)

## 0.6.0

- Added support for modular HTTP client adapters, allowing mock HTTP clients in a test environment (thanks @jotaviobiondo)
- Added extra fields to `Snap.Aggregation` (thanks @megalithic)

## 0.5.2

- Return `Snap.HTTPError` when ElasticSearch returns an error HTTP status
  without any accompanying JSON
- Expose `inner_hits` field on `Snap.Hit` struct

## 0.5.1

- Accept `conn_opts` config options to configure the underlying HTTP transport
  (thanks @danielxvu)

## 0.5.0

- Update `telemetry` dependency to 1.0

## 0.4.5

- Allow extra options on `Snap.Bulk.perform/4` which are passed into the underlying request
- Added `matched_queries` and `highlight` fields on the `Snap.Hit` struct.

## 0.4.1

- Added the `host` and `port` to the Telemetry metadata.

## 0.4.0

- Drop the underscore from the response struct keys, as it's just annoying to
  work with.

## 0.3.0

- Added `Snap.Search` to wrap making searches and parsing the response into
  structs.

## 0.2.4

- Fixed behaviour of `max_errors` when it's set to `0`.

## 0.2.3

- Added support for an optional `max_errors` parameter in
  `Snap.Bulk.perform`, which aborts the operation if the number of errors
  accumulated exceedes this count.

## 0.2.2

- Pass extra opts, such as `pipeline: "foo"` in `Snap.Bulk.perform` to the
  Bulk API endpoint.

## 0.2.1

- Added support in `Snap.Auth.Plain` for defining the username and password in
  the configured URL.

## 0.2.0

- Introduce `Snap.BulkError` to wrap a list of errors produced from
  `Snap.Bulk`.

## 0.1.1

- Documentation formatting fix.

## 0.1.0

- First release.
