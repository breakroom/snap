ExUnit.configure(exclude: [integration: true])

Logger.put_application_level(:snap, :warning)

url = "http://localhost:9200"
{:ok, _} = Snap.Test.Cluster.start_link(url: url, index_namespace: "snap-test")

ExUnit.start()
