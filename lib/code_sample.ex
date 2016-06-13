defmodule CodeSample do
  @moduledoc """
  This module has functionality for examining and modifying the comments on files in BOX
  """

  @doc """
    
  """
  @spec get_comments!(String.t, String.t) :: integer
  def get_comments!(file_id, token) do
    case HTTPoison.get! "https://api.box.com/2.0/files/#{file_id}/comments", %{Authorization: "Bearer #{token}"} do
      %{status_code: 200, body: body} ->
        body
        |> Poison.decode!
        |> Map.get("entries")
      %{status_code: code, body: body} ->
        raise "Failed to get comments.  Received #{code}: #{body}"
    end
  end


  
  @doc """
    Adds a comment onto a file or another comment 
    type can be either "file" or "comment" and the id should be
    of the appropriate type.

    Returns the id of the new comment if successful
    And throws an error if the target doesn't exist
  """ 
  @spec add_comment!(String.t, integer, String.t, String.t) :: {:ok, String.t}
  def add_comment!(type, id, comment, token) do
    encoded_comment = 
    # comment tags another user
    if String.contains?(comment, "@") do
      Poison.encode!(%{item: %{type: type, id: id}, tagged_message: comment } )
    else
      Poison.encode!(%{item: %{type: type, id: id}, message: comment } )
    end
    case HTTPoison.post! "https://api.box.com/2.0/comments", encoded_comment,
    #Poison.encode!(%{item: %{type: "file", id: file_id}, message: comment } ),
      %{Authorization: "Bearer #{token}"} do

      %{status_code: 201, body: body} ->
        comment_id = body
                     |> Poison.decode!
                     |> Map.get("id")
        {:ok, comment_id}
      # TODO: Research output
      #
      %{status_code: 409, body: body} ->
        raise "Failed to add comment.  Received 409: #{body}"
      %{status_code: code, body: body} ->
        raise "Failed to add comment.  Received #{code}: #{body}"
    end
  end

  @doc """
    Adds a comment to the file with given id, is equivalent to calling
    add_comment!/4 with type "file"

    Will raise an error if the file isn't found
    Otherwise, returns the comment
  """
  @spec add_comment!(integer, String.t, String.t) :: {:ok, String.t}
  def add_comment!(file_id, comment, token) do
    add_comment!("file", file_id, comment, token)
  end


  @doc """
    Deletes the comment with the given id

    If the comment is found, it is deleted and :ok is returned
    If the deletion fails due to a not finding the comment, :notfound is returned 
    Otherwise an error will be thrown
    
    Returning :notfound instead of an error is a deliberate choice: no return
    values are expected, the post-condition is the same (the file doesn't exist)
    and the event can occur in standard usage through doubled requests
  """
  @spec delete_comment!(integer, String.t) :: :ok | :notfound
  def delete_comment!(comment_id, token) do
    case HTTPoison.delete! "https://api.box.com/2.0/comments/#{comment_id}",
      %{Authorization: "Bearer #{token}"} do
      %{status_code: 204, body: _} -> :ok
      # TODO: Undocumented what other status errors will be
      # Test which status codes will be received
      %{status_code: 404, body: _} -> :notfound
      %{status_code: code, body: body} ->
        raise "Failed to delete comment.  Received #{code}: #{body}"
    end
  end

end
