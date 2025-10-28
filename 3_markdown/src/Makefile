# Markdown Parser Makefile
# Improved version with dependency tracking and clean targets

# Compiler and tools
CC = gcc
YACC = yacc
LEX = lex
EMCC = emcc

# Directories
BUILD_DIR = build
SRC_DIR = .

# Compilation flags
CFLAGS = -Wall -Wextra -std=c11 -O2 -D_GNU_SOURCE
DEBUG ?= 0
ifeq ($(DEBUG),1)
	CFLAGS += -g -DYYDEBUG=1
	YFLAGS = --debug -dv
else
	YFLAGS = -dv
endif
LFLAGS =
EMCCFLAGS = -O2 -s EXIT_RUNTIME

# Source files
PARSER_SRC = lexer.y
LEXER_SRC = tokenizer.l
C_SOURCES = ast.c generators.c
HEADERS = ast.h generators.h types.h token.h

# Generated files (in build/ directory)
PARSER_C = $(BUILD_DIR)/y.tab.c
PARSER_H = $(BUILD_DIR)/y.tab.h
LEXER_C = $(BUILD_DIR)/lex.yy.c

# Object files
PARSER_OBJ = $(BUILD_DIR)/y.tab.o
LEXER_OBJ = $(BUILD_DIR)/lex.yy.o
C_OBJECTS = $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SOURCES))
OBJECTS = $(PARSER_OBJ) $(LEXER_OBJ) $(C_OBJECTS)

# Output binary
TARGET = markdown

# WASM outputs
WASM_TARGET = $(TARGET).wasm
WASM_BROWSER_TARGET = $(TARGET).html

# Phony targets (not files)
.PHONY: all clean distclean rebuild help run wasm wasm-browser test

# Default target
all: $(TARGET)

# Build the main binary
$(TARGET): $(OBJECTS)
	@echo "Linking $@..."
	$(CC) $(CFLAGS) $^ -o $@

# Generate parser C and header files from Yacc
$(PARSER_C) $(PARSER_H): $(PARSER_SRC)
	@mkdir -p $(BUILD_DIR)
	@echo "Generating parser from $<..."
	$(YACC) $(YFLAGS) -b $(BUILD_DIR)/y $<

# Generate lexer C file from Lex
$(LEXER_C): $(LEXER_SRC) $(PARSER_H)
	@mkdir -p $(BUILD_DIR)
	@echo "Generating lexer from $<..."
	$(LEX) $(LFLAGS) -o $@ $<

# Compile parser C to object
$(PARSER_OBJ): $(PARSER_C) $(HEADERS)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -I. -I$(BUILD_DIR) -c $< -o $@

# Compile lexer C to object
$(LEXER_OBJ): $(LEXER_C) $(HEADERS)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -I. -I$(BUILD_DIR) -c $< -o $@

# Compile C source files to objects
$(BUILD_DIR)/%.o: %.c $(HEADERS)
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -I. -I$(BUILD_DIR) -c $< -o $@

# WebAssembly build for Node.js
wasm: $(PARSER_C) $(LEXER_C)
	@echo "Building WebAssembly version..."
	$(EMCC) $(EMCCFLAGS) -I$(BUILD_DIR) $(PARSER_C) $(LEXER_C) $(C_SOURCES) -o $(WASM_TARGET)

# WebAssembly build for browser
wasm-browser: $(PARSER_C) $(LEXER_C)
	@echo "Building WebAssembly version for browser..."
	$(EMCC) $(EMCCFLAGS) -I$(BUILD_DIR) $(PARSER_C) $(LEXER_C) $(C_SOURCES) \
		-o $(WASM_BROWSER_TARGET) \
		-sINVOKE_RUN=0 -sWASM=1 \
		-sEXPORTED_FUNCTIONS=_parse_markdown,_parse_markdown_as_ast \
		-sEXPORTED_RUNTIME_METHODS=ccall,cwrap

# Clean build artifacts (keep generated parser/lexer)
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(OBJECTS)
	rm -f $(TARGET)
	rm -f *.wasm *.js *.html a.out
	rm -f $(BUILD_DIR)/*.o

# Clean everything including generated files
distclean: clean
	@echo "Cleaning all generated files..."
	rm -f $(BUILD_DIR)/y.tab.c $(BUILD_DIR)/y.tab.h
	rm -f $(BUILD_DIR)/lex.yy.c
	rm -f $(BUILD_DIR)/y.output
	rm -f y.tab.c y.tab.h lex.yy.c y.output lexer.tab.c lexer.tab.h
	@if [ -d $(BUILD_DIR) ] && [ -z "$$(ls -A $(BUILD_DIR))" ]; then rmdir $(BUILD_DIR); fi

# Clean and rebuild
rebuild: distclean all

# Build and run with sample.md
run: $(TARGET)
	@echo "Running $(TARGET) with sample.md..."
	@./$(TARGET) < sample.md

# Run tests (placeholder - add your test commands here)
test: $(TARGET)
	@echo "Running tests..."
	@./$(TARGET) < sample.md > /dev/null && echo "✓ sample.md test passed"

# Display help
help:
	@echo "Markdown Parser - Available targets:"
	@echo ""
	@echo "  make [all]        - Build the native binary (default)"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make distclean    - Remove all generated files"
	@echo "  make rebuild      - Clean and rebuild from scratch"
	@echo "  make run          - Build and run with sample.md"
	@echo "  make test         - Run tests"
	@echo "  make wasm         - Build WebAssembly version for Node.js"
	@echo "  make wasm-browser - Build WebAssembly version for browser"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Options:"
	@echo "  DEBUG=1           - Build with debug symbols and YYDEBUG enabled"
	@echo ""
	@echo "Examples:"
	@echo "  make              # Build release version"
	@echo "  make DEBUG=1      # Build debug version"
	@echo "  make clean all    # Clean build"
	@echo "  make run          # Build and test"
