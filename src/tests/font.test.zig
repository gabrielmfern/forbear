const std = @import("std");
const LRU = @import("../font.zig").LRU;

test "LRU cache - set_first" {
    const LRUIntString = LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32));
    var lru = try LRUIntString.init(std.testing.allocator);
    defer lru.deinit();

    lru.entries[0] = LRUIntString.Entry{ .key = 1, .value = "one" };
    lru.entries[1] = LRUIntString.Entry{ .key = 2, .value = "two" };
    lru.entries[2] = LRUIntString.Entry{ .key = 3, .value = "three" };

    lru.first = 0;
    lru.last = 2;

    lru.set_first(2);

    try std.testing.expectEqual(2, lru.first.?);
    try std.testing.expectEqual(3, lru.entries[lru.first.?].key);
    try std.testing.expectEqualSlices(u8, "three", lru.entries[lru.first.?].value);
}

test "LRU Cache" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);

    defer lru.deinit();

    _ = lru.put(1, "1");
    _ = lru.put(2, "2");
    _ = lru.put(3, "3");
    std.debug.print("After inserting all three entries:\n", .{});
    lru.print();

    const entry_2 = lru.get(2);
    try std.testing.expect(entry_2 != null);
    try std.testing.expectEqual(2, entry_2.?.key);
    try std.testing.expectEqualSlices(u8, "2", entry_2.?.value);
    try std.testing.expectEqual(entry_2.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 2:\n", .{});
    lru.print();

    const entry_1 = lru.get(1);
    try std.testing.expect(entry_1 != null);
    try std.testing.expectEqual(1, entry_1.?.key);
    try std.testing.expectEqualSlices(u8, "1", entry_1.?.value);
    try std.testing.expectEqual(entry_1.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 1:\n", .{});
    lru.print();

    const entry_3 = lru.get(3);
    try std.testing.expect(entry_3 != null);
    try std.testing.expectEqual(3, entry_3.?.key);
    try std.testing.expectEqualSlices(u8, "3", entry_3.?.value);
    try std.testing.expectEqual(entry_3.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 3:\n", .{});
    lru.print();

    // Adding a new value should evict the least recently used value
    const entry_4 = lru.put(4, "4");
    std.debug.print("After adding the entry '4' beyond the capacity of the LRU:\n", .{});
    lru.print();
    try std.testing.expectEqual(entry_4.index, lru.first.?);
    // The entry for 2 should have been discarded completely
    try std.testing.expectEqual(entry_1.?, &lru.entries[lru.last.?]);
    try std.testing.expect(lru.get(2) == null);
}

test "LRU cache - update existing key" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Update existing key should replace value and move to front
    const updated_index = lru.put(2, "TWO");

    const entry = lru.get(2);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "TWO", entry.?.value);
    try std.testing.expectEqual(updated_index.index, lru.first.?);
    try std.testing.expectEqual(2, lru.entries[lru.first.?].key);
    try std.testing.expectEqual(3, lru.length);
}

test "LRU cache - empty cache operations" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    // Get from empty cache should return null
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.peek(1) == null);
    try std.testing.expectEqual(false, lru.contains(1));
    try std.testing.expectEqual(null, lru.first);
    try std.testing.expectEqual(null, lru.last);
    try std.testing.expectEqual(0, lru.length);
}

test "LRU cache - single item cache" {
    var lru = try LRU(i32, []const u8, 1, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    try std.testing.expectEqual(1, lru.length);
    try std.testing.expectEqual(0, lru.first.?);
    try std.testing.expectEqual(0, lru.last.?);

    const entry = lru.get(1);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "one", entry.?.value);

    // Adding another item should evict the first
    _ = lru.put(2, "two");
    try std.testing.expectEqual(1, lru.length);
    try std.testing.expect(lru.get(1) == null);

    const entry2 = lru.get(2);
    try std.testing.expect(entry2 != null);
    try std.testing.expectEqualSlices(u8, "two", entry2.?.value);
}

test "LRU cache - multiple accesses same key" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Access same key multiple times
    _ = lru.get(2);
    _ = lru.get(2);
    _ = lru.get(2);

    // Should still be at front
    try std.testing.expectEqual(1, lru.first.?);
    try std.testing.expectEqual(2, lru.entries[lru.first.?].key);

    // Add new item, key 2 was most recently used, so 1 should be evicted
    _ = lru.put(4, "four");
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.get(2) != null);
}

test "LRU cache - peek does not affect order" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Peek at key 1 (currently at back)
    const peeked = lru.peek(1);
    try std.testing.expect(peeked != null);
    try std.testing.expectEqualSlices(u8, "one", peeked.?.value);

    // Key 3 should still be at front
    try std.testing.expectEqual(2, lru.first.?);
    try std.testing.expectEqual(3, lru.entries[lru.first.?].key);

    // Add new item, key 1 should be evicted (not moved to front by peek)
    _ = lru.put(4, "four");
    try std.testing.expect(lru.get(1) == null);
}

test "LRU cache - contains" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");

    try std.testing.expectEqual(true, lru.contains(1));
    try std.testing.expectEqual(true, lru.contains(2));
    try std.testing.expectEqual(false, lru.contains(3));
}

test "LRU cache - clear" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    try std.testing.expectEqual(3, lru.length);

    lru.clear();

    try std.testing.expectEqual(0, lru.length);
    try std.testing.expectEqual(null, lru.first);
    try std.testing.expectEqual(null, lru.last);
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.get(2) == null);
    try std.testing.expect(lru.get(3) == null);

    // Should be able to add new items after clear
    _ = lru.put(4, "four");
    const entry = lru.get(4);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "four", entry.?.value);
}

test "LRU cache - getMut allows modification" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");

    const entry = lru.getMut(1);
    try std.testing.expect(entry != null);
    entry.?.value = "modified";

    const retrieved = lru.get(1);
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqualSlices(u8, "modified", retrieved.?.value);
}

test "LRU cache - eviction order with mixed access" {
    var lru = try LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Access pattern: 1, 3, (2 not accessed)
    _ = lru.get(1);
    _ = lru.get(3);

    // Add new item, 2 should be evicted as least recently used
    _ = lru.put(4, "four");

    try std.testing.expect(lru.get(1) != null);
    try std.testing.expect(lru.get(2) == null);
    try std.testing.expect(lru.get(3) != null);
    try std.testing.expect(lru.get(4) != null);
}
