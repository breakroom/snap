ExUnit.configure(exclude: [integration: true])

Mox.defmock(HTTPClientMock, for: Snap.HTTPClient)

ExUnit.start()

url = "http://localhost:9200"

{:ok, _} = Snap.Test.Cluster.start_link(url: url)
