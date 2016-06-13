Code.require_file "../scaffold_helper.exs", __DIR__

defmodule CodeSampleIntegrationTest do
  use ExUnit.Case

  setup do
    CodeSample.Authentication.start_link

    # Build up "./test/resources/pp_doc.txt" in a platform agnostic way
    test_file = Path.join [".", "test", "resources", "pp_doc.txt"]
    current_token = CodeSample.Authentication.get_token

    # If there is an exists version of this file, we want to delete it
    # We'll create a new version to run our tests against after this block
    # It is unusual that this file will actually exist, as it *normally* gets cleaned up by the on_exit callback
    case ScaffoldHelper.get_file_id("pp_doc.txt", current_token) do
      nil ->
        nil
      file_id ->
        ScaffoldHelper.delete_file!(file_id, current_token)
    end

    # Uploads a fresh copy of our example file.  pp_file_id will be passed into each test via the context map
    pp_file_id = ScaffoldHelper.upload_file!(test_file, current_token)

    # After each test finishes, we'll delete the file
    on_exit fn ->
      ScaffoldHelper.delete_file!(pp_file_id, current_token)
    end

    # Metadata to be passed to the tests
    {:ok, file_id: pp_file_id}
  end

  test "A fresh file has no comments", context do
    assert CodeSample.get_comments!(context[:file_id], CodeSample.Authentication.get_token) == []
  end

  test "Getting comments from a non-existant file raises an exception", _ do
    assert_raise RuntimeError, fn ->
      CodeSample.get_comments!("1234", CodeSample.Authentication.get_token)
    end
  end

  test "We can add a comment to a file", context do
    {:ok, id} = CodeSample.add_comment!(context[:file_id], "Test comment", CodeSample.Authentication.get_token)
    
    # Verify via searching all the comments that the comment is present
    # get_comment!/2 appears later in modification
    comments = CodeSample.get_comments!(context[:file_id], CodeSample.Authentication.get_token)
    assert Enum.find(comments, fn(c) -> Map.get(c, "id") == id end)
  end

  test "Adding duplicate comments raises an exception appropriately", context do
    CodeSample.add_comment!(context[:file_id], "Test comment 2", CodeSample.Authentication.get_token)
    assert_raise RuntimeError, fn ->
      CodeSample.add_comment!(context[:file_id], "Test comment 2", CodeSample.Authentication.get_token)
    end
  end

  test "Adding a comment to a non-existing file raises an exception", _ do
    assert_raise RuntimeError, fn ->
      CodeSample.add_comment!("1234", "Test comment 5", CodeSample.Authentication.get_token)
    end
  end

  test "We can delete a comment from a file", context do
    {:ok, id} = CodeSample.add_comment!(context[:file_id], "Test comment 3", CodeSample.Authentication.get_token)
    is_empty = case CodeSample.delete_comment!(id, CodeSample.Authentication.get_token) do
      :ok -> [] == CodeSample.get_comments!(context[:file_id], CodeSample.Authentication.get_token)
      _ -> false
    end
    assert is_empty
  end

  test "We can modify a comment on a file", context do
    {:ok, id} = CodeSample.add_comment!(context[:file_id], "Test comment 4", CodeSample.Authentication.get_token)
    assert (case CodeSample.update_comment!(id, "Modified comment", CodeSample.Authentication.get_token) do
      :ok -> "Modified comment" == Map.get(CodeSample.get_comment!(id, CodeSample.Authentication.get_token), "message")
      _ -> false # We shouldn't reach this case as failure is an exception instead
    end)
  end

  test "Modifying a non-existing comment raises an exception", _ do
    assert_raise RuntimeError, fn -> 
      CodeSample.update_comment!("1234", "Modified comment 2", CodeSample.Authentication.get_token)
    end
  end
end
