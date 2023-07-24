ExUnit.configure(exclude: [integration: true])

url = "http://localhost:9200"
{:ok, _} = Snap.Test.Cluster.start_link(url: url)

ExUnit.start()
