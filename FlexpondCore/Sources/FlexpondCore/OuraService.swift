//
//  OuraService.swift
//  Flexpönd
//
//  Real Oura Ring API v2 integration for a single-user app.
//  Pairs with the Readiness page in the Flexpönd design prototype
//  (see the doc comment block in "Flexpönd Workout.dc.html").
//
//  AUTH MODEL
//  ----------
//  Uses a Personal Access Token (PAT) — any Oura account holder can
//  generate one at https://cloud.ouraring.com/personal-access-tokens
//  for their OWN data, no developer-program approval needed. Perfect
//  for a one-user learning app. The PAT is stored in the iOS Keychain
//  (never UserDefaults — it grants full read access to health data).
//
//  USAGE
//  -----
//      let service = OuraService()
//      try service.saveToken("PASTE_PAT_HERE")          // once, from the Connect screen
//      let day = try await service.fetchLatestReadiness() // then, on refresh
//      // day.score          -> overall 0–100 ring value
//      // day.contributors   -> the 8 contributor scores for the metric cards
//
//  Dropped in essentially verbatim from the design handoff package
//  (design_handoff_flexpond/OuraService.swift) — only `public` access
//  modifiers were added so the app target (a separate module) can use it.

import Foundation
import Security

// MARK: - Models (field names match Oura's JSON exactly)

public struct OuraReadinessResponse: Codable, Sendable {
    public let data: [OuraReadinessDay]
    public let nextToken: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextToken = "next_token"
    }
}

public struct OuraReadinessDay: Codable, Sendable {
    public let day: String            // "2026-07-09"
    public let score: Int             // 0–100 overall readiness
    public let contributors: OuraContributors
    public let temperatureDeviation: Double?

    enum CodingKeys: String, CodingKey {
        case day, score, contributors
        case temperatureDeviation = "temperature_deviation"
    }

    public init(day: String, score: Int, contributors: OuraContributors, temperatureDeviation: Double? = nil) {
        self.day = day
        self.score = score
        self.contributors = contributors
        self.temperatureDeviation = temperatureDeviation
    }
}

/// The 8 contributor scores (each 0–100). These map 1:1 to the metric
/// cards on the Readiness screen. "Focus today" = the two LOWEST scores
/// (computed client-side; Oura does not provide this).
public struct OuraContributors: Codable, Sendable, Equatable {
    public let activityBalance: Int
    public let bodyTemperature: Int
    public let hrvBalance: Int
    public let previousDayActivity: Int
    public let previousNight: Int       // = the "Sleep" card
    public let recoveryIndex: Int
    public let restingHeartRate: Int
    public let sleepBalance: Int

    enum CodingKeys: String, CodingKey {
        case activityBalance = "activity_balance"
        case bodyTemperature = "body_temperature"
        case hrvBalance = "hrv_balance"
        case previousDayActivity = "previous_day_activity"
        case previousNight = "previous_night"
        case recoveryIndex = "recovery_index"
        case restingHeartRate = "resting_heart_rate"
        case sleepBalance = "sleep_balance"
    }

    public init(activityBalance: Int, bodyTemperature: Int, hrvBalance: Int, previousDayActivity: Int, previousNight: Int, recoveryIndex: Int, restingHeartRate: Int, sleepBalance: Int) {
        self.activityBalance = activityBalance
        self.bodyTemperature = bodyTemperature
        self.hrvBalance = hrvBalance
        self.previousDayActivity = previousDayActivity
        self.previousNight = previousNight
        self.recoveryIndex = recoveryIndex
        self.restingHeartRate = restingHeartRate
        self.sleepBalance = sleepBalance
    }

    /// Ordered list for rendering: (displayLabel, score)
    public var all: [(label: String, score: Int)] {
        [("Resting Heart Rate", restingHeartRate),
         ("HRV Balance", hrvBalance),
         ("Body Temperature", bodyTemperature),
         ("Recovery Index", recoveryIndex),
         ("Sleep", previousNight),
         ("Sleep Balance", sleepBalance),
         ("Previous Day Activity", previousDayActivity),
         ("Activity Balance", activityBalance)]
    }
}

/// The non-secret snapshot cached locally so the Readiness screen renders
/// without a network round-trip (the PAT itself lives only in Keychain,
/// via `OuraService.saveToken`/`loadToken`).
public struct OuraSnapshot: Codable, Sendable, Equatable {
    public let score: Int
    public let contributors: OuraContributors
    public let day: String
    public let syncedAt: Date

    public init(score: Int, contributors: OuraContributors, day: String, syncedAt: Date) {
        self.score = score
        self.contributors = contributors
        self.day = day
        self.syncedAt = syncedAt
    }

    public init(day: OuraReadinessDay, syncedAt: Date) {
        self.score = day.score
        self.contributors = day.contributors
        self.day = day.day
        self.syncedAt = syncedAt
    }
}

// MARK: - Status thresholds (match the design)

public enum ReadinessStatus: String, Sendable {
    case optimal = "Optimal"           // green  #5FD08A
    case balanced = "Balanced"         // blue   #4CA6FF
    case payAttention = "Pay attention" // amber #E8B44D

    public init(score: Int) {
        switch score {
        case 85...: self = .optimal
        case 70..<85: self = .balanced
        default: self = .payAttention
        }
    }
}

// MARK: - Errors

public enum OuraError: LocalizedError {
    case noToken
    case badURL
    case httpError(Int)     // 401 = bad/expired token
    case noData

    public var errorDescription: String? {
        switch self {
        case .noToken: return "No Oura token saved — connect your ring first."
        case .badURL: return "Could not build the Oura API URL."
        case .httpError(let code):
            return code == 401
                ? "Oura rejected the token — generate a new one and reconnect."
                : "Oura API error (HTTP \(code))."
        case .noData: return "Oura returned no readiness data for the date range."
        }
    }
}

// MARK: - Service

public final class OuraService: Sendable {

    private let keychainKey = "com.flexpond.oura.pat"

    public init() {}

    // MARK: Token (Keychain)

    public func saveToken(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]
        SecItemDelete(query as CFDictionary) // replace if present
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attrs as CFDictionary, nil)
        guard status == errSecSuccess else { throw OuraError.noToken }
    }

    public func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else { return nil }
        return token
    }

    public func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: Fetch

    /// Fetches the last 7 days of readiness and returns the most recent day.
    /// No CORS concerns here — that's a browser-only restriction; URLSession
    /// talks to api.ouraring.com directly.
    public func fetchLatestReadiness() async throws -> OuraReadinessDay {
        guard let token = loadToken() else { throw OuraError.noToken }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!

        var comps = URLComponents(string: "https://api.ouraring.com/v2/usercollection/daily_readiness")
        comps?.queryItems = [
            URLQueryItem(name: "start_date", value: formatter.string(from: start)),
            URLQueryItem(name: "end_date", value: formatter.string(from: end)),
        ]
        guard let url = comps?.url else { throw OuraError.badURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw OuraError.httpError(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(OuraReadinessResponse.self, from: data)
        guard let latest = decoded.data.last else { throw OuraError.noData }
        return latest
    }

    /// "Focus today" = the two lowest-scoring contributors (matches the design).
    public func focusContributors(for day: OuraReadinessDay) -> [(label: String, score: Int)] {
        Array(day.contributors.all.sorted { $0.score < $1.score }.prefix(2))
    }
}
