# Streaming in Elixir

Elixir's `Stream` module provides lazy, memory-efficient processing for large or infinite data. Unlike `Enum` (which processes everything immediately), `Stream` only computes values when needed.

---

## Quick Start: Streaming a File

```elixir
"large_file.txt"
|> File.stream!()
|> Stream.map(&String.trim/1)
|> Stream.filter(&(&1 != ""))
|> Enum.each(&IO.puts/1)
```

`File.stream!/1` reads one line at a time, so even a 10GB file uses minimal memory.

---

## Stream vs Enum

| Aspect | `Enum` (Eager) | `Stream` (Lazy) |
|--------|----------------|-----------------|
| Execution | Immediate | On-demand |
| Memory | Loads all data | One item at a time |
| Intermediate lists | Yes | No |
| Best for | Small collections | Large/infinite data |

```elixir
# Enum - creates intermediate lists at each step
1..1_000_000
|> Enum.map(&(&1 * 2))      # Creates a 1M element list
|> Enum.filter(&(&1 > 100)) # Creates another huge list
|> Enum.take(5)             # All that work for just 5 items!

# Stream - builds a pipeline, executes only when needed
1..1_000_000
|> Stream.map(&(&1 * 2))      # Returns a Stream (no computation yet)
|> Stream.filter(&(&1 > 100)) # Still just a Stream
|> Enum.take(5)               # NOW it runs, stops after finding 5
#=> [102, 104, 106, 108, 110]
```

---

## Terminating a Stream

Streams are lazy — nothing happens until you terminate them:

| Function | Purpose |
|----------|---------|
| `Enum.to_list/1` | Collect all results into a list |
| `Enum.take/2` | Take first n items |
| `Enum.each/2` | Process each item for side effects |
| `Enum.count/1` | Count items |
| `Enum.reduce/3` | Reduce to a single value |
| `Stream.run/1` | Run for side effects only, returns `:ok` |

---

## Common Patterns

### Filter and Collect

```elixir
File.stream!("application.log")
|> Stream.map(&String.trim/1)
|> Stream.filter(&String.contains?(&1, "ERROR"))
|> Enum.to_list()
```

### Take First N Matches

```elixir
File.stream!("application.log")
|> Stream.filter(&String.contains?(&1, "ERROR"))
|> Enum.take(10)
```

### Process in Batches

```elixir
File.stream!("data.csv")
|> Stream.drop(1)                    # Skip header
|> Stream.map(&parse_csv_line/1)
|> Stream.chunk_every(100)           # Batch into groups of 100
|> Stream.each(&insert_to_database/1)
|> Stream.run()
```

### Count Without Loading

```elixir
line_count = File.stream!("huge.txt") |> Enum.count()
```

---

## Stream Functions Reference

### Transformations (mirrors `Enum`)

```elixir
Stream.map(enum, fun)           # Transform each element
Stream.filter(enum, fun)        # Keep elements matching predicate
Stream.reject(enum, fun)        # Remove elements matching predicate
Stream.flat_map(enum, fun)      # Map and flatten results
Stream.uniq(enum)               # Remove duplicates
Stream.dedup(enum)              # Remove consecutive duplicates
```

### Slicing

```elixir
Stream.take(enum, n)            # First n elements
Stream.drop(enum, n)            # Skip first n elements
Stream.take_while(enum, fun)    # Take while predicate is true
Stream.drop_while(enum, fun)    # Drop while predicate is true
```

### Combining

```elixir
Stream.zip(enum1, enum2)        # Pair elements from two streams
Stream.chunk_every(enum, n)     # Group into chunks of n
Stream.concat(enum1, enum2)     # Concatenate streams
```

### Generators (Stream-specific)

```elixir
Stream.cycle(enum)              # Infinite repetition: [1,2,3,1,2,3,...]
Stream.repeatedly(fun)          # Infinite calls: fun.(), fun.(), ...
Stream.iterate(start, fun)      # Infinite iteration: start, fun.(start), ...
Stream.unfold(acc, fun)         # Generate from accumulator
Stream.resource(start, next, cleanup)  # External resources with cleanup
```

---

## Infinite Sequences

Streams can represent infinite data — just don't try to `Enum.to_list/1` them!

```elixir
# Natural numbers
naturals = Stream.iterate(1, &(&1 + 1))
naturals |> Enum.take(5)
#=> [1, 2, 3, 4, 5]

# Fibonacci sequence
fibs = Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
fibs |> Enum.take(10)
#=> [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

# Infinite cycle
Stream.cycle([:red, :green, :blue]) |> Enum.take(7)
#=> [:red, :green, :blue, :red, :green, :blue, :red]
```

---

## Resource Management

Use `Stream.resource/3` when you need setup and cleanup (similar to Java's try-with-resources):

```elixir
Stream.resource(
  # Setup: open the resource
  fn -> File.open!("data.txt") end,

  # Generate: produce items one at a time
  fn file ->
    case IO.read(file, :line) do
      :eof -> {:halt, file}
      line -> {[String.trim(line)], file}
    end
  end,

  # Cleanup: always runs, even on error
  fn file -> File.close(file) end
)
|> Enum.take(10)
```

---

## Advanced: Parallel Processing

For CPU-intensive work on large datasets, consider these libraries:

### Flow (Parallel Streams)

```elixir
# Add to mix.exs: {:flow, "~> 1.0"}

"huge_file.log"
|> File.stream!()
|> Flow.from_enumerable()
|> Flow.filter(&String.contains?(&1, "ERROR"))
|> Flow.partition()
|> Flow.reduce(fn -> %{} end, fn line, acc ->
  Map.update(acc, extract_error_type(line), 1, &(&1 + 1))
end)
|> Enum.to_list()
```

### GenStage (Back-pressure)

```elixir
# Add to mix.exs: {:gen_stage, "~> 1.0"}
# Use for producer-consumer pipelines with controlled throughput
```

---

## When to Use What

| Scenario | Use |
|----------|-----|
| Small collections (< 10K items) | `Enum` |
| Large files | `Stream` + `File.stream!/1` |
| Only need first N results | `Stream` |
| Infinite sequences | `Stream` |
| Memory-constrained environment | `Stream` |
| Simple, readable code | `Enum` |
| Parallel CPU-bound processing | `Flow` |
| Producer-consumer with back-pressure | `GenStage` |
