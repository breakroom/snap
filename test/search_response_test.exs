defmodule Snap.SearchResponseTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.SearchResponse

  test "new/1 without extra fields" do
    json = fixture_json("search_response")

    response = SearchResponse.new(json)
    assert response.took == 5
    assert response.timed_out == false
    assert response.shards == %{"total" => 5, "successful" => 5, "skipped" => 0, "failed" => 0}
    assert Enum.count(response) == 10
    assert is_nil(response.aggregations)

    assert response.hits.total == %{"value" => 10_000, "relation" => "gte"}
    assert response.hits.max_score == 1.0
    assert Enum.count(response.hits.hits) == 10

    hit = Enum.at(response.hits.hits, 0)
    assert hit.index == "dev-vacancies-v1-1610549150278184"
    assert hit.type == "_doc"
    assert hit.id == "adz-2553823"
    assert hit.score == 1.0
    assert hit.matched_queries == ["query_a"]
    assert hit.highlight == %{"message" => [" with the <em>number</em>", " <em>1</em>"]}
    assert hit.sort == nil

    assert hit.source == %{
             "adzuna_url" =>
               "https://www.adzuna.co.uk/jobs/details/1922923955?se=oMlhYylR6xGMhMp5avH9Cg&utm_medium=api&utm_source=0b5c6a90&v=1F37F0DE2CAA738178B918040AA403B42178B4A7",
             "contract_time" => "full_time",
             "contract_type" => "permanent",
             "description" =>
               "Science teacher required in Chelmsford September start MPS/UPS Are you a newly qualified Science teacher looking to kick-start your career? Are you an experienced Science teacher looking for the next step in your career? TLTP are currently working with a Secondary school based in Chelmsford that is seeking to appoint an enthusiastic Teacher of Science to join them in September. The school are graded 'Good' by Ofsted and currently have 1130 students in school. For the right candidate there would…",
             "employer_name" => "TLTP",
             "id" => "adz-2553823",
             "job_title" => "Science teacher",
             "location" => %{"lat" => 51.735802, "lon" => 0.469708},
             "timestamp" => "1610052006"
           }
  end

  test "new/1 with aggregations" do
    json = fixture_json("search_response_agg")

    response = SearchResponse.new(json)
    assert Enum.count(response.aggregations) == 4

    assert response.aggregations["season_values"] == %Snap.Aggregation{
             buckets: [%{"doc_count" => 69_406, "key" => "summer"}],
             doc_count_error_upper_bound: 0,
             sum_other_doc_count: 0
           }

    assert response.aggregations["people"] == %Snap.MetricsAggregation{
             value: %{"value" => 8}
           }

    assert response.aggregations["things"] == %Snap.MetricsAggregation{
             value: %{"doc_count" => 9}
           }

    assert response.aggregations["histogram"] == %Snap.Aggregation{
             buckets: [
               %{
                 "doc_count" => 10,
                 "key_as_string" => "2022-03-12T21:00:00.000Z",
                 "key" => 1_647_118_800_000
               }
             ],
             interval: "30m"
           }
  end

  test "new/1 with inner_hits" do
    json = fixture_json("search_response_inner_hits")

    response = SearchResponse.new(json)
    first_hit = Enum.at(response.hits, 0)

    comments = first_hit.inner_hits["comments"]

    assert Enum.count(comments) == 1
  end

  test "new/1 with sorted" do
    json = fixture_json("search_response_sorted")

    response = SearchResponse.new(json)
    first_hit = Enum.at(response.hits, 0)

    assert [123, "456"] == first_hit.sort
  end

  defp fixture_json(name) do
    Path.join([__DIR__, "fixtures", "#{name}.json"])
    |> File.read!()
    |> Jason.decode!()
  end
end
