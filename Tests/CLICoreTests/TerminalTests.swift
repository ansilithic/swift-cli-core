import Testing
@testable import CLICore

@Suite("Terminal")
struct TerminalTests {

    @Test("RGB hex initialization")
    func rgbHex() {
        let red = RGB(hex: "E06C75")
        #expect(red.r == 224)
        #expect(red.g == 108)
        #expect(red.b == 117)
    }

    @Test("RGB hex with hash prefix")
    func rgbHexHash() {
        let green = RGB(hex: "#98C379")
        #expect(green.r == 152)
        #expect(green.g == 195)
        #expect(green.b == 121)
    }

    @Test("RGB component initialization")
    func rgbComponents() {
        let color = RGB(255, 128, 0)
        #expect(color.r == 255)
        #expect(color.g == 128)
        #expect(color.b == 0)
    }

    @Test("RGB foreground escape sequence")
    func rgbFg() {
        let color = RGB(100, 200, 50)
        #expect(color.fg == "\u{001B}[38;2;100;200;50m")
    }

    @Test("String.strippingANSI removes escape sequences")
    func strippingANSI() {
        let colored = "\u{001B}[38;2;224;108;117mhello\u{001B}[0m"
        #expect(colored.strippingANSI == "hello")
    }

    @Test("String.strippingANSI preserves plain text")
    func strippingANSIPlain() {
        #expect("hello world".strippingANSI == "hello world")
    }

    @Test("String.padded accounts for ANSI width")
    func paddedANSI() {
        let plain = "hello"
        let padded = plain.padded(to: 10)
        #expect(padded == "hello     ")
        #expect(padded.count == 10)

        let colored = "\u{001B}[38;2;224;108;117mhello\u{001B}[0m"
        let colorPadded = colored.padded(to: 10)
        #expect(colorPadded.strippingANSI == "hello     ")
    }

    @Test("String.padded does not truncate wider strings")
    func paddedNoTruncate() {
        let text = "hello world"
        #expect(text.padded(to: 5) == "hello world")
    }

    @Test("String.repeating")
    func repeatingString() {
        #expect("─".repeating(3) == "───")
        #expect("ab".repeating(0) == "")
    }

    @Test("Color enum covers One Dark palette")
    func colorPalette() {
        let cases: [Color] = [.red, .green, .yellow, .blue, .cyan, .white, .gray, .orange, .magenta, .lightGray, .darkGray]
        for color in cases {
            #expect(color.rawValue.hasPrefix("\u{001B}[38;2;"))
        }
        #expect(Color.reset.rawValue == "\u{001B}[0m")
        #expect(Color.bold.rawValue == "\u{001B}[1m")
        #expect(Color.dim.rawValue == "\u{001B}[2m")
    }
}
