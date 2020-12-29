ExUnit.start()

url = "http://localhost:9200"

{:ok, _} = Elasticsearcher.Test.Cluster.start_link(%{url: url})
