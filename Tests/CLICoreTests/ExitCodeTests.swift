import Testing
@testable import CLICore

@Suite("CLIExitCode")
struct ExitCodeTests {

    @Test("Exit code raw values")
    func rawValues() {
        #expect(CLIExitCode.success.rawValue == 0)
        #expect(CLIExitCode.warning.rawValue == 1)
        #expect(CLIExitCode.error.rawValue == 2)
    }
}
