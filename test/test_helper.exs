ExUnit.configure(exclude: [integration: true])
ExUnit.start()

url = "http://localhost:9200"
auth = Snap.Auth.Plain

{:ok, _} = Snap.Test.Cluster.start_link(url: url, auth: auth)
