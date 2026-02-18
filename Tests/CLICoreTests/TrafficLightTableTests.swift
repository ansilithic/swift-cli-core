import Testing
@testable import CLICore

@Suite("TrafficLightTable")
struct TrafficLightTableTests {

    /// Split render output into lines, dropping the leading blank line from the standard newline prefix.
    private func lines(_ output: String, stripANSI: Bool = true) -> [String] {
        let text = stripANSI ? output.strippingANSI : output
        let all = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        // Drop leading empty line from the standard table prefix newline
        if let first = all.first, first.isEmpty {
            return Array(all.dropFirst())
        }
        return all
    }

    // MARK: - Column Width Calculation

    @Test("Auto column sized to content")
    func autoColumnSizing() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("ID", sizing: .auto())),
            .column(TextColumn("Name", sizing: .auto())),
        ], columnPadding: 2)

        let rows = [
            TrafficLightRow(indicators: [], values: ["1", "Alice"]),
            TrafficLightRow(indicators: [], values: ["22", "Bob"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        // Auto: max("ID"=2, "22"=2) + 2 = 4
        // Auto: max("Name"=4, "Alice"=5) + 2 = 7
        // Data row "22" should be padded to 4, then "Bob" starts at offset 4
        let dataLine = lines[2]
        #expect(dataLine.hasPrefix("1   "))

        let dataLine2 = lines[3]
        #expect(dataLine2.hasPrefix("22  "))

        // "Bob" and "Alice" should start at the same offset
        let aliceOffset = lines[2].distance(
            from: lines[2].startIndex,
            to: lines[2].range(of: "Alice")!.lowerBound
        )
        let bobOffset = lines[3].distance(
            from: lines[3].startIndex,
            to: lines[3].range(of: "Bob")!.lowerBound
        )
        #expect(aliceOffset == bobOffset)
        #expect(aliceOffset == 4)
    }

    @Test("Fixed column width")
    func fixedColumnWidth() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("A", sizing: .fixed(10))),
            .column(TextColumn("B", sizing: .auto())),
        ], columnPadding: 2)

        let rows = [
            TrafficLightRow(indicators: [], values: ["hi", "there"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        // Fixed(10) + padding 2 = 12. "there" should start at offset 12.
        let dataLine = lines[2]
        let thereOffset = dataLine.distance(
            from: dataLine.startIndex,
            to: dataLine.range(of: "there")!.lowerBound
        )
        #expect(thereOffset == 12)
    }

    @Test("Flexible column takes remaining width")
    func flexibleColumnWidth() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("A", sizing: .fixed(5))),
            .column(TextColumn("B", sizing: .flexible(minWidth: 10))),
        ], columnPadding: 2)

        let rows = [
            TrafficLightRow(indicators: [], values: ["x", "hello world"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 40)
        let lines = lines(output)

        // Fixed: 5 + 2 = 7. Flexible: 40 - 7 = 33.
        let dataLine = lines[2]
        let helloOffset = dataLine.distance(
            from: dataLine.startIndex,
            to: dataLine.range(of: "hello world")!.lowerBound
        )
        #expect(helloOffset == 7)
    }

    @Test("Auto column with maxWidth cap")
    func autoMaxWidthCap() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("Label", sizing: .auto(maxWidth: 8))),
            .column(TextColumn("Other", sizing: .auto())),
        ], columnPadding: 2)

        let rows = [
            TrafficLightRow(indicators: [], values: [
                "a-very-long-label-exceeding-cap", "ok",
            ]),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        // Auto capped: min(31+2, 8+2) = 10. "ok" starts at offset 10.
        let dataLine = lines[2]
        let okRange = dataLine.range(of: "ok")
        #expect(okRange != nil)
        if let range = okRange {
            let offset = dataLine.distance(from: dataLine.startIndex, to: range.lowerBound)
            #expect(offset == 10)
        }
    }

    @Test("Auto columns shrink proportionally when over budget")
    func autoColumnShrinking() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("A", sizing: .auto())),
            .column(TextColumn("B", sizing: .auto())),
            .column(TextColumn("C", sizing: .flexible(minWidth: 60))),
        ], columnPadding: 2)

        let rows = [
            TrafficLightRow(indicators: [], values: [
                String(repeating: "x", count: 30),
                String(repeating: "y", count: 30),
                "flex",
            ]),
        ]

        // Terminal 80, flexible min 60, so auto budget = 80 - 60 = 20.
        // Ideal: 32 + 32 = 64, exceeds 20. Both shrink proportionally.
        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        // "flex" should appear somewhere in the data line
        let dataLine = lines[2]
        #expect(dataLine.contains("flex"))

        // Both auto columns should be roughly equal (10 each)
        let flexOffset = dataLine.distance(
            from: dataLine.startIndex,
            to: dataLine.range(of: "flex")!.lowerBound
        )
        #expect(flexOffset == 20)
    }

    // MARK: - Indicator Rendering

    @Test("Indicator on/off rendering")
    func indicatorStates() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("a", color: .red),
                Indicator("b", color: .green),
                Indicator("c", color: .blue),
            ]),
            .column(TextColumn("Val", sizing: .auto())),
        ])

        let rows = [
            TrafficLightRow(
                indicators: [[.on, .off, .on]],
                values: ["test"]
            ),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        let dataLine = lines[2]
        // on, off, on → "● ●"
        #expect(dataLine.hasPrefix("\u{25CF} \u{25CF}"))
    }

    @Test("Custom indicator symbol")
    func customSymbol() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("starred", color: .yellow, symbol: "\u{2605}"),
            ]),
            .column(TextColumn("X", sizing: .auto())),
        ])

        let rows = [
            TrafficLightRow(indicators: [[.on]], values: ["v"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        // Star symbol should appear in both header and data row
        #expect(lines[0].contains("\u{2605}"))
        #expect(lines[2].contains("\u{2605}"))
    }

    // Removed: indicatorColorOverride — referenced .colored() which was never added to IndicatorState

    @Test("Missing indicator states default to off")
    func missingIndicatorStates() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("a", color: .red),
                Indicator("b", color: .green),
            ]),
            .column(TextColumn("X", sizing: .auto())),
        ])

        // Only provide 1 state for a 2-indicator group
        let rows = [
            TrafficLightRow(indicators: [[.on]], values: ["test"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let lines = lines(output)

        // First indicator on, second defaults to off
        let dataLine = lines[2]
        #expect(dataLine.hasPrefix("\u{25CF} "))
    }

    // MARK: - Legend

    @Test("Single group legend wiring")
    func singleGroupLegend() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("loaded", color: .green),
                Indicator("running", color: .blue),
                Indicator("healthy", color: .yellow),
            ]),
            .column(TextColumn("Label", sizing: .auto())),
        ])

        let output = table.render(
            rows: [],
            counts: [[5, 3, 2]],
            terminalWidth: 80
        )
        let plain = output.strippingANSI

        // Wiring characters
        #expect(plain.contains("\u{250C}"))
        #expect(plain.contains("\u{2502}"))
        #expect(plain.contains("\u{2500}"))

        // Counts
        #expect(plain.contains("(5)"))
        #expect(plain.contains("(3)"))
        #expect(plain.contains("(2)"))

        // Labels
        #expect(plain.contains("loaded"))
        #expect(plain.contains("running"))
        #expect(plain.contains("healthy"))
    }

    @Test("Legend wiring pattern for 3 slots")
    func legendWiringPattern() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("a", color: .red),
                Indicator("b", color: .green),
                Indicator("c", color: .blue),
            ]),
            .column(TextColumn("X", sizing: .auto())),
        ])

        let output = table.render(rows: [], counts: [[1, 2, 3]], terminalWidth: 80)
        let lines = lines(output)

        // Line 0: slot 0 → ┌── + ─ (wiring)
        #expect(lines[0].hasPrefix("\u{250C}\u{2500}\u{2500}\u{2500}"))
        // Line 1: slot 1 → │┌─ + ─
        #expect(lines[1].hasPrefix("\u{2502}\u{250C}\u{2500}\u{2500}"))
        // Line 2: slot 2 → ││┌ + ─
        #expect(lines[2].hasPrefix("\u{2502}\u{2502}\u{250C}\u{2500}"))
        // Line 3: footer pipes → │││
        #expect(lines[3].hasPrefix("\u{2502}\u{2502}\u{2502}"))
    }

    @Test("Multiple group legend alignment")
    func multipleGroupLegend() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("a", color: .red),
                Indicator("b", color: .green),
            ]),
            .column(TextColumn("Col1", sizing: .fixed(10))),
            .indicators([
                Indicator("c", color: .blue),
            ]),
            .column(TextColumn("Col2", sizing: .auto())),
        ])

        let output = table.render(
            rows: [],
            counts: [[1, 2], [3]],
            terminalWidth: 80
        )
        let plain = output.strippingANSI

        // Both groups should have their labels and counts
        #expect(plain.contains("a"))
        #expect(plain.contains("b"))
        #expect(plain.contains("c"))
        #expect(plain.contains("(1)"))
        #expect(plain.contains("(2)"))
        #expect(plain.contains("(3)"))

        // Second group should be offset from the first
        let lines = lines(output)
        // Group 2 starts after: group1 dots (2+2=4) + col1 (10+2=12) = 16
        let line0 = lines[0]
        let cOffset = line0.distance(
            from: line0.startIndex,
            to: line0.range(of: "c")!.lowerBound
        )
        // The "c" label appears after wiring for group 2 at offset 16
        #expect(cOffset > 14)
    }

    @Test("No legend when counts is nil")
    func noLegend() {
        let table = TrafficLightTable(segments: [
            .indicators([Indicator("x", color: .red)]),
            .column(TextColumn("Col", sizing: .auto())),
        ])

        let output = table.render(rows: [], terminalWidth: 40)
        let plain = output.strippingANSI

        // Should NOT contain legend wiring
        #expect(!plain.contains("\u{250C}"))
        #expect(!plain.contains("\u{2502}"))
    }

    // MARK: - Header

    @Test("Header has dots and column names")
    func headerRendering() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("x", color: .red),
                Indicator("y", color: .green),
            ]),
            .column(TextColumn("Name", sizing: .auto())),
            .column(TextColumn("Status", sizing: .auto())),
        ])

        let output = table.render(
            rows: [TrafficLightRow(indicators: [[.on, .off]], values: ["test", "ok"])],
            terminalWidth: 80
        )
        let lines = lines(output)

        // Header line has dots and column names
        #expect(lines[0].contains("\u{25CF}"))
        #expect(lines[0].contains("Name"))
        #expect(lines[0].contains("Status"))

        // Rule line
        #expect(lines[1].allSatisfy { $0 == "\u{2500}" })
        #expect(lines[1].count == 80)
    }

    @Test("Indicator group width in header")
    func indicatorGroupHeaderWidth() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("a", color: .red),
                Indicator("b", color: .green),
                Indicator("c", color: .blue),
            ]),
            .column(TextColumn("Col", sizing: .auto())),
        ], columnPadding: 2)

        let output = table.render(
            rows: [TrafficLightRow(indicators: [[.on, .on, .on]], values: ["val"])],
            terminalWidth: 80
        )
        let lines = lines(output)

        // Header: 3 dots + 2 padding = 5, then "Col"
        let header = lines[0]
        let colOffset = header.distance(
            from: header.startIndex,
            to: header.range(of: "Col")!.lowerBound
        )
        #expect(colOffset == 5)
    }

    // MARK: - Full Table Layouts

    @Test("Plaid layout: 1 group + 3 columns")
    func plaidLayout() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("loaded", color: .green),
                Indicator("running", color: .blue),
                Indicator("healthy", color: .yellow),
            ]),
            .column(TextColumn("Label", sizing: .auto(maxWidth: 40))),
            .column(TextColumn("Schedule", sizing: .auto())),
            .column(TextColumn("Program", sizing: .flexible(minWidth: 7))),
        ])

        let rows = [
            TrafficLightRow(
                indicators: [[.on, .on, .on]],
                values: ["com.apple.ftp-proxy", "Every hour", "/usr/libexec/ftpd"]
            ),
            TrafficLightRow(
                indicators: [[.on, .off, .off]],
                values: ["com.example.backup", "Every day at 02:00", "backup.sh"]
            ),
        ]

        let output = table.render(rows: rows, terminalWidth: 100)
        let plain = output.strippingANSI

        #expect(plain.contains("Label"))
        #expect(plain.contains("Schedule"))
        #expect(plain.contains("Program"))
        #expect(plain.contains("com.apple.ftp-proxy"))
        #expect(plain.contains("backup.sh"))

        let lines = plain.split(separator: "\n").map(String.init)
        // Leading newline + header + rule + 2 data rows = 5 lines (4 non-empty)
        #expect(lines.count == 4)
    }

    @Test("Saddle layout: 3 groups + 4 columns")
    func saddleLayout() {
        let table = TrafficLightTable(segments: [
            .indicators([
                Indicator("public", color: .red),
                Indicator("archived", color: .gray),
                Indicator("starred", color: .yellow, symbol: "\u{2605}"),
            ]),
            .column(TextColumn("Origin", sizing: .auto())),
            .indicators([
                Indicator("equipped", color: .cyan),
                Indicator("hooked", color: .magenta),
                Indicator("unhealthy", color: .red),
            ]),
            .column(TextColumn("Local Path", sizing: .auto())),
            .indicators([
                Indicator("dirty", color: .red),
                Indicator("ahead", color: .cyan),
                Indicator("behind", color: .orange),
            ]),
            .column(TextColumn("Last Commit", sizing: .fixed(14))),
            .column(TextColumn("Description", sizing: .flexible(minWidth: 10))),
        ])

        let rows = [
            TrafficLightRow(
                indicators: [[.on, .off, .on], [.on, .on, .off], [.on, .off, .off]],
                values: ["github.com/org/repo", "org/repo", "3 days ago", "A cool project"]
            ),
        ]

        let output = table.render(
            rows: rows,
            counts: [[3, 1, 2], [5, 3, 0], [2, 1, 0]],
            terminalWidth: 120
        )
        let plain = output.strippingANSI

        // Column headers present
        #expect(plain.contains("Origin"))
        #expect(plain.contains("Local Path"))
        #expect(plain.contains("Last Commit"))
        #expect(plain.contains("Description"))

        // Star symbol in header
        #expect(plain.contains("\u{2605}"))

        // Data values present
        #expect(plain.contains("github.com/org/repo"))
        #expect(plain.contains("org/repo"))
        #expect(plain.contains("3 days ago"))
        #expect(plain.contains("A cool project"))

        // Legend labels and counts
        #expect(plain.contains("public"))
        #expect(plain.contains("equipped"))
        #expect(plain.contains("dirty"))
        #expect(plain.contains("(3)"))
        #expect(plain.contains("(5)"))
        #expect(plain.contains("(2)"))
    }

    // MARK: - Edge Cases

    @Test("Zero rows renders header and rule only")
    func zeroRows() {
        let table = TrafficLightTable(segments: [
            .indicators([Indicator("x", color: .red)]),
            .column(TextColumn("Col", sizing: .auto())),
        ])

        let output = table.render(rows: [], terminalWidth: 40)
        let lines = lines(output)

        // Header + rule + trailing empty line, no data
        #expect(lines.count == 3)
        #expect(lines[0].contains("Col"))
        #expect(lines[1].contains("\u{2500}"))
        #expect(lines[2].isEmpty)
    }

    @Test("ANSI-aware padding preserves alignment")
    func ansiAwarePadding() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("A", sizing: .fixed(10))),
            .column(TextColumn("B", sizing: .auto())),
        ], columnPadding: 2)

        // Manually construct ANSI string to bypass isTerminal check
        let ansiValue = "\u{001B}[38;2;224;108;117mhello\u{001B}[0m"
        let rows = [
            TrafficLightRow(indicators: [], values: [ansiValue, "end"]),
            TrafficLightRow(indicators: [], values: ["plain", "end"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 40)
        let lines = lines(output, stripANSI: false)

        let row1Plain = lines[2].strippingANSI
        let row2Plain = lines[3].strippingANSI

        // "end" should appear at the same column in both rows
        let endOffset1 = row1Plain.distance(
            from: row1Plain.startIndex,
            to: row1Plain.range(of: "end")!.lowerBound
        )
        let endOffset2 = row2Plain.distance(
            from: row2Plain.startIndex,
            to: row2Plain.range(of: "end")!.lowerBound
        )
        #expect(endOffset1 == endOffset2)
    }

    @Test("Text truncated with ellipsis when exceeding column width")
    func textTruncation() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("X", sizing: .fixed(5))),
            .column(TextColumn("Y", sizing: .auto())),
        ], columnPadding: 2)

        let rows = [
            TrafficLightRow(indicators: [], values: ["longerthancolumn", "ok"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 80)
        let plain = output.strippingANSI

        // Value should be truncated with ellipsis
        #expect(plain.contains("\u{2026}"))
        // Original full string should NOT appear
        #expect(!plain.contains("longerthancolumn"))
    }

    @Test("Indicator group with zero indicators")
    func emptyIndicatorGroup() {
        let table = TrafficLightTable(segments: [
            .indicators([]),
            .column(TextColumn("X", sizing: .auto())),
        ])

        let rows = [
            TrafficLightRow(indicators: [[]], values: ["hello"]),
        ]

        let output = table.render(rows: rows, terminalWidth: 40)
        let plain = output.strippingANSI
        #expect(plain.contains("hello"))
    }

    @Test("Render returns string, not side effects")
    func renderReturnsString() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("A", sizing: .auto())),
        ])

        let output = table.render(
            rows: [TrafficLightRow(indicators: [], values: ["val"])],
            terminalWidth: 40
        )

        #expect(!output.isEmpty)
        #expect(output.contains("val"))
        #expect(output.hasSuffix("\n"))
    }

    @Test("Render starts with leading newline")
    func renderLeadingNewline() {
        let table = TrafficLightTable(segments: [
            .column(TextColumn("A", sizing: .auto())),
        ])

        let output = table.render(
            rows: [TrafficLightRow(indicators: [], values: ["val"])],
            terminalWidth: 40
        )

        #expect(output.hasPrefix("\n"))
    }
}
