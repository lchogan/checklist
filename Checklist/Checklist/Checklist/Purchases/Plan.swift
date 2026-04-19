/// Plan.swift
/// Purpose: One entry in the plan catalog — maps a StoreKit product ID (or
///   nil for the free plan) to a display name and a FeatureLimits.
/// Dependencies: Foundation (Codable).
/// Key concepts:
///   - `productID == nil` identifies the free plan.
///   - `id` is a stable slug used by tests + logs; not user-facing.
///   - `displayName` is shown in PaywallSheet and SettingsView.

import Foundation

/// A named plan tier. `productID` nil = free; non-nil = a StoreKit product.
struct Plan: Codable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let productID: String?
    let limits: FeatureLimits
}
