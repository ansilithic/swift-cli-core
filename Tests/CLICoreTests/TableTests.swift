import Testing
@testable import CLICore

@Suite("TableFormatter")
struct TableTests {

    @Test("Column widths calculated from data")
    func widthCalculation() {
        let table = TableFormatter(columns: [
            .init("Name"),
            .init("Status"),
        ], padding: 4)

        let rows = [
            ["short", "ok"],
            ["a-much-longer-name", "running"],
        ]

        let widths = table.widths(for: rows)
        // "a-much-longer-name" = 18, + 4 padding = 22
        #expect(widths[0] == 22)
        // "running" = 7, but header "Status" = 6, so 7 + 4 = 11
        #expect(widths[1] == 11)
    }

    @Test("Column minWidth is respected")
    func minWidth() {
        let table = TableFormatter(columns: [
            .init("ID", minWidth: 20),
        ], padding: 2)

        let rows = [["1"], ["2"]]
        let widths = table.widths(for: rows)
        // minWidth 20 + 2 padding = 22
        #expect(widths[0] == 22)
    }

    @Test("Empty rows use header widths")
    func emptyRows() {
        let table = TableFormatter(columns: [
            .init("Repository"),
            .init("Branch"),
        ], padding: 4)

        let widths = table.widths(for: [])
        #expect(widths[0] == "Repository".count + 4)
        #expect(widths[1] == "Branch".count + 4)
    }
}
