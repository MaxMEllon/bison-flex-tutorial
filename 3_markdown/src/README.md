## Build Targets

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build native binary |
| `make clean` | Remove build artifacts |
| `make distclean` | Remove all generated files |
| `make rebuild` | Clean and rebuild from scratch |
| `make run` | Build and run with sample.md |
| `make test` | Run tests |
| `make wasm` | Build WebAssembly for Node.js |
| `make wasm-browser` | Build WebAssembly for browser |
| `make help` | Show all available targets |

### Build Options

```bash
make DEBUG=1    # Build with debug symbols
```