ExUnit.configure(exclude: [integration: true])

Logger.configure(level: :warning)

url = "http://localhost:9200"
{:ok, _} = Snap.Test.Cluster.start_link(url: url, index_namespace: "snap-test")

# Just make sure we're dealing with an empty cluster in this namespace before we start
:ok = Snap.Test.drop_indexes(Snap.Test.Cluster)

ExUnit.start()
