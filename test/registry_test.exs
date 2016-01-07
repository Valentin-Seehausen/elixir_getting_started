defmodule KV.RegistryTest do
	use ExUnit.Case, async: true

	setup context do
		{:ok, registry} = KV.Registry.start_link(context.test)
		{:ok, registry: context.test}
	end

	test "spawns buckets", %{registry: registry} do
		assert KV.Registry.lookup(registry, "shopping") == :error

		KV.Registry.create(registry, "shopping")
		assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

		KV.Bucket.put(bucket, "milk", 1)
		assert KV.Bucket.get(bucket, "milk") == 1
	end

	test "removes buckets on exit", %{registry: registry} do
		KV.Registry.create(registry, "shopping")
		{:ok, bucket} = KV.Registry.lookup(registry, "shopping")
		Agent.stop(bucket)
		# Do a call to ensure the registry processed the down message
		_ = KV.Registry.create(registry, "bogus")
		assert KV.Registry.lookup(registry, "shopping") == :error
	end

	test "removes bucket on crash", %{registry: registry} do
		KV.Registry.create(registry, "shopping")
		{:ok, bucket} = KV.Registry.lookup(registry, "shopping")

		# Kill the bucket and wait for the notification
		Process.exit(bucket, :shutdown)

		# I think the documentation online is misleading/wrong about this test case because
		# according to fishcakez_ there is no way to actually sync this... but this works
		:timer.sleep(2)
		# Do a sync to ensure the registry processed the down message
		_ = KV.Registry.create(registry, "bogus")
		# assert_receive {:exit, "shopping", ^bucket}


		assert KV.Registry.lookup(registry, "shopping") == :error
	end
end
