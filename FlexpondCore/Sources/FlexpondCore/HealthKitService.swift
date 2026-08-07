//
//  HealthKitService.swift
//  Flexpönd
//
//  Read-only step-count access for the Walk goal's progress bar. No write
//  access is ever requested — Flexpönd only reads today's step count.
//
//  HealthKit doesn't exist on macOS, so the real `HKHealthStore`-backed
//  implementation is gated behind `#if os(iOS)`. On macOS `HealthKitService`
//  still compiles (so `AppViewModel` and everything around it keeps
//  building/testing here) but every call just throws `.unavailable`.
//
//  Protocol-backed (unlike `OuraService`) specifically so a fake conformer
//  can exercise `AppViewModel`'s connect/sync/disconnect logic in tests —
//  the real HealthKit calls can't be exercised outside Xcode at all.

import Foundation
#if os(iOS)
import HealthKit
#endif

public enum HealthKitError: LocalizedError {
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .unavailable: return "Apple Health isn't available on this device."
        }
    }
}

public protocol HealthKitServicing: Sendable {
    /// Requests read-only access to step count. Per Apple's own documented
    /// HealthKit limitation, read-authorization status can't be reliably
    /// introspected after the fact — completing this call means the user
    /// went through the system prompt, not that access was necessarily
    /// granted. A denied read just makes `fetchTodaySteps()` return 0.
    func requestAuthorization() async throws

    /// Today's cumulative step count (00:00 to now, device-local calendar).
    func fetchTodaySteps() async throws -> Int
}

public final class HealthKitService: HealthKitServicing {
    #if os(iOS)
    private let store = HKHealthStore()
    #endif

    public init() {}

    public func requestAuthorization() async throws {
        #if os(iOS)
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthKitError.unavailable }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: [stepType])
        #else
        throw HealthKitError.unavailable
        #endif
    }

    public func fetchTodaySteps() async throws -> Int {
        #if os(iOS)
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthKitError.unavailable }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.unavailable
        }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let datePredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: stepType, predicate: datePredicate),
            options: .cumulativeSum
        )
        let statistics = try await descriptor.result(for: store)
        let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
        return Int(steps)
        #else
        throw HealthKitError.unavailable
        #endif
    }
}
