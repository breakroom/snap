# Changelog

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
