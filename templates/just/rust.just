

# List all recipes
default:
    just --list

# Build the application
build:
    cargo build

# Clean the compilation files
clean:
    cargo clean

# Run the application
run:
    cargo run

# Clean build the application
rebuild:
    clean
    build

# Run all tests
test $RUST_BACKTRACE="1":
    # will print a stack trace if it crashes
    cargo test

# Count the number of code lines
sloc:
  @echo "`wc -l *.rs` lines of code"
