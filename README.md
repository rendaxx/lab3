# Streaming Interpolation Lab (Elixir)

CLI escript that streams input points, interpolates them with selected algorithms, and emits sampled points as soon as enough data is available. The core pipeline is built from plain processes using `spawn` and `send`/`receive`; interpolation math is pure and IO-free.

## Algorithms
- **Linear**: segment-by-segment piecewise linear interpolation.
- **Newton (sliding window)**: configurable window `N` (default 4). Each window owns an interval based on window centers; windows are finalized and flushed as soon as the next window appears, with the tail flushed on EOF.

## Building
```
mix deps.get      # no external deps, but keeps mix happy
mix escript.build # produces ./my_lab3
```

## Running
Pipe points into the escript; results stream out immediately once enough data is present.
```
cat points.txt | ./my_lab3 --linear --step 0.7
cat points.txt | ./my_lab3 --newton --window 4 --step 0.5
cat points.txt | ./my_lab3 --linear --newton --step 1.0
```

### CLI flags
- `--linear` enable linear interpolation (default when no algorithm flags are given)
- `--newton` enable Newton sliding window interpolation
- `-n, --window N` window size for Newton (default 4)
- `--step S` sampling step for output x values (float > 0, default 0.5)
- `--delimiter auto|comma|semicolon|tab|space` input delimiter (default auto)
- `--precision K` significant digits for output formatting (default 12)
- `--format space|csv|tsv` output separator (default space)
- `--help` show usage

## Input and output
Input: lines with `x y` pairs, sorted by increasing `x`. Delimiters may be space, tab, comma, or semicolon (auto-detected by default). Empty lines and lines starting with `#` are ignored. If `x` is non-increasing, an error is written to stderr and the run exits non-zero.

Output: each emitted line contains the algorithm name and the interpolated point, e.g.:
```
linear: 0.7 0.7
newton: 2.5 6.25
```
Within each algorithm stream, `x` never decreases and duplicates are avoided.

## Streaming + windowing rules
- Each algorithm tracks its own sampling grid (`next_x`) based on the first interval boundary (`ceil(left/step)*step`).
- Linear treats each segment `[x0, x1)` as a window of size 2 and samples that open interval.
- Newton windows:
  - Center = middle point (odd N) or average of the two middles (even N).
  - Left boundary = midpoint to previous window center (or first `x` for the first window).
  - Right boundary = midpoint to next center; on EOF the final window ends at the last input `x` (inclusive if aligned to the grid).
  - When a new point creates a new window, the previous window’s right boundary is known and it is finalized immediately.

## Process architecture
All coordination uses bare processes with `spawn` and message passing:
- **Reader**: reads stdin, parses lines into `{:point, x, y}`; sends `:eof` at end.
- **Coordinator**: validates monotonic `x`, forwards points to workers, broadcasts `:eof`, handles errors, and terminates on completion.
- **Workers (Linear/Newton)**: maintain window state, sample intervals, and emit `{:out, algo, x, y}` plus `{:algo_done, algo}`.
- **Printer**: formats and writes output lines, exits after all workers report done or on abort.

## Tests
```
mix test
```
Covers parsing across delimiters, linear interpolation, Newton divided differences/evaluation, and a streaming integration scenario that verifies monotonic, non-duplicated outputs per algorithm.

## CI
GitHub Actions workflow at `.github/workflows/ci.yml` runs:
1. `mix deps.get`
2. `mix compile --warnings-as-errors`
3. `mix format --check-formatted`
4. `mix test`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `lab3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:lab3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/lab3>.
