# Changelog

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
