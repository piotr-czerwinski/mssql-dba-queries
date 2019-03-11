--a allocation by broker. All limits
SELECT pool_id,
	memory_broker_type,
	allocations_kb,
	allocations_kb_per_sec,
	predicted_allocations_kb,
	target_allocations_kb,
	future_allocations_kb,
	overall_limit_kb,
	last_notification
FROM sys.dm_os_memory_brokers