# swift-cli-core — Swift library for building CLI tools on macOS

Terminal styling, ANSI color output, table formatting, and structured messaging for Swift command-line tools. Used across [Ansilithic](https://github.com/ansilithic) tools.

## Usage

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ansilithic/swift-cli-core.git", from: "1.0.0")
]
```

Then import in your target:

```swift
.executableTarget(name: "mytool", dependencies: [
    .product(name: "CLICore", package: "swift-cli-core")
])
```

## Modules

### Terminal

One Dark color palette with automatic TTY detection.

```swift
import CLICore

print(styled("success", .green))       // Colored in terminal, plain when piped
print(styled("bold red", .bold, .red))  // Multiple styles

let padded = "hello".padded(to: 20)    // ANSI-aware padding
let plain = colored.strippingANSI      // Strip escape sequences
```

### Table

ANSI-aware table formatting with dynamic column widths.

```swift
let table = TableFormatter(columns: [
    .init("Name"), .init("Status"), .init("Branch")
], padding: 4)

let rows = [["myrepo", "clean", "main"], ["other", "dirty", "feature"]]
let widths = table.widths(for: rows)
table.printHeader(widths: widths)
for row in rows {
    table.printRow(row, widths: widths)
}
```

### Output

Structured messaging with correct stream routing.

```swift
Output.info("Processing files...")      // stdout
Output.success("All done")             // stdout
Output.warning("Skipped 2 files")      // stderr
Output.error("File not found")         // stderr
Output.printSummary([
    styled("3 synced", .green),
    styled("1 skipped", .yellow)
])
```

### ExitCode

Standard exit codes.

```swift
CLIExitCode.success.exit()  // 0
CLIExitCode.warning.exit()  // 1
CLIExitCode.error.exit()    // 2
```

## Requirements

- macOS 14+ (Sonoma)
- Swift 6.0

## License

MIT
