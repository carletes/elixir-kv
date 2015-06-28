defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link
    {:ok, bucket: bucket}
  end
  
  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 42)
    assert KV.Bucket.get(bucket, "milk") == 42
  end

  test "deletes by key", %{bucket: bucket} do
    assert KV.Bucket.delete(bucket, "no_such_key") == nil

    KV.Bucket.put(bucket, "milk", 42)
    assert KV.Bucket.delete(bucket, "milk") == 42
    assert KV.Bucket.get(bucket, "milk")== nil
  end
end
