import Testing
@testable import CLICore

@Suite("Chart")
struct ChartTests {

    // MARK: - bar()

    @Test("bar width matches exactly")
    func barWidth() {
        // Non-TTY: isTerminal is false in test runner, so we get ASCII format
        let result = bar(0.5, width: 20)
        let stripped = result.strippingANSI
        // ASCII format: [####....] where inner = width - 2
        #expect(stripped.hasPrefix("["))
        #expect(stripped.hasSuffix("]"))
        #expect(stripped.count == 20)
    }

    @Test("bar at zero is all empty")
    func barZero() {
        let result = bar(0, width: 10).strippingANSI
        // [........] — 8 dots inside brackets
        #expect(result == "[........]")
    }

    @Test("bar at one is all filled")
    func barFull() {
        let result = bar(1.0, width: 10).strippingANSI
        #expect(result == "[########]")
    }

    @Test("bar clamps above 1.0")
    func barClampHigh() {
        let result = bar(2.0, width: 10).strippingANSI
        #expect(result == "[########]")
    }

    @Test("bar clamps below 0.0")
    func barClampLow() {
        let result = bar(-1.0, width: 10).strippingANSI
        #expect(result == "[........]")
    }

    @Test("bar at half fills half")
    func barHalf() {
        let result = bar(0.5, width: 12).strippingANSI
        // inner = 10, filled = 5, empty = 5
        #expect(result == "[#####.....]")
    }

    // MARK: - BarChart

    @Test("BarChart renders correct number of lines")
    func barChartLineCount() {
        let items = [
            BarChart.Item("en0", value: 1900, display: "1.9 GB"),
            BarChart.Item("lo0", value: 158, display: "158 MB"),
            BarChart.Item("utun8", value: 4.5, display: "4.5 MB"),
        ]
        let chart = BarChart(items: items, barWidth: 20)
        let lines = chart.render().split(separator: "\n")
        #expect(lines.count == 3)
    }

    @Test("BarChart labels are aligned")
    func barChartAlignment() {
        let items = [
            BarChart.Item("en0", value: 100, display: "100"),
            BarChart.Item("bridge100", value: 50, display: "50"),
        ]
        let chart = BarChart(items: items, barWidth: 10)
        let lines = chart.render().split(separator: "\n").map { String($0).strippingANSI }
        // "bridge100" is 9 chars — en0 should be padded to 9
        #expect(lines[0].hasPrefix("en0       "))
        #expect(lines[1].hasPrefix("bridge100 "))
    }

    @Test("BarChart empty items returns empty string")
    func barChartEmpty() {
        let chart = BarChart(items: [])
        #expect(chart.render() == "")
    }

    @Test("BarChart max item gets full bar")
    func barChartMaxFull() {
        let items = [
            BarChart.Item("a", value: 100, display: "100"),
            BarChart.Item("b", value: 0, display: "0"),
        ]
        let chart = BarChart(items: items, barWidth: 12)
        let lines = chart.render().split(separator: "\n").map { String($0).strippingANSI }
        // First line's bar should be all filled (10 # inside [])
        #expect(lines[0].contains("[##########]"))
        // Second line's bar should be all empty
        #expect(lines[1].contains("[..........]"))
    }

    // MARK: - Sparkline

    @Test("Sparkline character count matches value count")
    func sparklineLength() {
        let spark = Sparkline([1, 2, 3, 4, 5])
        let stripped = spark.render().strippingANSI
        #expect(stripped.count == 5)
    }

    @Test("Sparkline equal values produce mid-height")
    func sparklineEqual() {
        let spark = Sparkline([5, 5, 5])
        let stripped = spark.render().strippingANSI
        #expect(stripped == "▄▄▄")
    }

    @Test("Sparkline ascending values produce ascending blocks")
    func sparklineAscending() {
        let spark = Sparkline([0, 1, 2, 3, 4, 5, 6, 7])
        let chars = Array(spark.render().strippingANSI)
        // Each successive char should be >= previous
        for i in 1..<chars.count {
            #expect(chars[i] >= chars[i - 1])
        }
        // First should be lowest block, last should be highest
        #expect(chars.first == "▁")
        #expect(chars.last == "█")
    }

    @Test("Sparkline empty returns empty string")
    func sparklineEmpty() {
        let spark = Sparkline([])
        #expect(spark.render() == "")
    }

    @Test("Sparkline single value uses mid-height")
    func sparklineSingle() {
        let spark = Sparkline([42])
        let stripped = spark.render().strippingANSI
        #expect(stripped == "▄")
    }
}
