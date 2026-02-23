import Testing
import Foundation
@testable import Web2App

@Suite("URLValidator Tests")
struct URLValidatorTests {

    @Test("Valid HTTPS URL passes validation")
    func validHTTPSURL() throws {
        let url = try URLValidator.validate("https://example.com")
        #expect(url.absoluteString == "https://example.com")
    }

    @Test("Valid HTTP URL passes validation")
    func validHTTPURL() throws {
        let url = try URLValidator.validate("http://example.com")
        #expect(url.absoluteString == "http://example.com")
    }

    @Test("URL without scheme gets https prepended")
    func urlWithoutScheme() throws {
        let url = try URLValidator.validate("example.com")
        #expect(url.scheme == "https")
        #expect(url.host() == "example.com")
    }

    @Test("URL with path preserved")
    func urlWithPath() throws {
        let url = try URLValidator.validate("https://example.com/path/to/page")
        #expect(url.path() == "/path/to/page")
    }

    @Test("Whitespace is trimmed")
    func whitespaceIsTrimmed() throws {
        let url = try URLValidator.validate("  https://example.com  ")
        #expect(url.absoluteString == "https://example.com")
    }

    @Test("Empty string throws empty error")
    func emptyStringThrows() {
        #expect(throws: URLValidationError.empty) {
            try URLValidator.validate("")
        }
    }

    @Test("Whitespace-only string throws empty error")
    func whitespaceOnlyThrows() {
        #expect(throws: URLValidationError.empty) {
            try URLValidator.validate("   ")
        }
    }

    @Test("FTP scheme throws unsupported scheme error")
    func ftpSchemeThrows() {
        #expect(throws: URLValidationError.unsupportedScheme) {
            try URLValidator.validate("ftp://example.com")
        }
    }

    @Test("File scheme throws unsupported scheme error")
    func fileSchemeThrows() {
        #expect(throws: URLValidationError.unsupportedScheme) {
            try URLValidator.validate("file:///etc/passwd")
        }
    }
}
