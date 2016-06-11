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
    Adds a comment onto the file with the given id
    
    This function only supports adding comments to files, Use add_reply! for
    adding comments onto other commments
  """
  @spec add_comment!(String.t, String.t, String.t) :: {:ok, String.t}
  def add_comment!(file_id, comment, token) do
    case HTTPoison.post! "https://api.box.com/2.0/files/#{file_id}/comments", 
      Poison.encode!(%{item: %{type: "file", id: file_id}, message: comment } ),
      %{Authorization: "Bearer #{token}"} do

      %{status_code: code, body: body} ->
        comment_id = body
                     |> Poison.decode!
                     |> Map.get("id")
        {:ok, comment_id}
      %{status_code: code, body: body} ->
        raise "Failed to add comment.  Received #{code}: #{body}"
    end
  end
end
