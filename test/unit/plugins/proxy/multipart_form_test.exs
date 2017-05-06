defmodule Annon.Plugins.Proxy.MultipartFormTest do
  @moduledoc false
  use Annon.UnitCase, async: true

  import Annon.Plugins.Proxy.MultipartForm, only: [reconstruct_using: 1]

  describe "reconstruct_using/1" do
    test "returns a list of tuples for multipart form" do
      upload = %Plug.Upload{
        content_type: "some-mime-type",
        filename: "some-file-name.bson",
        path: "/some/path/to/file"
      }

      original_form = %{
        "originator" => "vivus.lt",
        "loans_count" => "1",
        "loans" => %{
          "file" => upload,
          "thing" => "value",
          "maybe" => %{
            "something" => %{
              "else" => "thing"
            }
          }
        }
      }

      expected_file_part =
        {
          :file,
          "/some/path/to/file",
          {"form-data", [{"name", ~S("loans[file]")}, {"filename", ~S("some-file-name.bson")}]},
          [{"Content-Type", "some-mime-type"}]
        }

      expected_form = [
        expected_file_part,
        {"loans[maybe][something][else]", "thing"},
        {"loans[thing]", "value"},
        {"loans_count", "1"},
        {"originator", "vivus.lt"}
      ]

      assert expected_form == reconstruct_using(original_form)
    end
  end
end
