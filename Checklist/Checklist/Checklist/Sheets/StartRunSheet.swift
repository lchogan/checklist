/// StartRunSheet.swift
/// Purpose: Name-only sheet for starting a new concurrent run when ≥1 live run
///   already exists. Per spec §7 the prototype's due-date field is dropped.
/// Dependencies: SwiftUI, SwiftData, BottomSheet, PillButton, Theme, RunStore.
/// Key concepts:
///   - Commits via RunStore.startRun(on:name:in:); passes nil for empty names.
///   - Calls onStarted(run) before dismiss so the caller can switch currentRunID.

import SwiftUI
import SwiftData

/// Name-only sheet for starting a new concurrent run when ≥1 live run
/// already exists. Per spec §7 this drops the prototype's due-date field.
struct StartRunSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    let checklist: Checklist
    let onStarted: (Run) -> Void

    @State private var name: String = ""
    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW RUN")
                    .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
                Text("Name this run.")
                    .font(Theme.display(size: 22)).foregroundColor(Theme.text)
                Text("A short label like \"Tokyo\" or \"Week 14\". Optional — leave blank if you don't care.")
                    .font(.system(size: 13)).foregroundColor(Theme.dim)
                TextField("", text: $name)
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))

                HStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                    PillButton(title: "Start", color: Theme.amethyst, wide: true) { commit() }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
    }

    /// Creates a new Run via RunStore, notifies the caller, then dismisses.
    ///
    /// - Note: Passes nil as the name when the trimmed input is empty,
    ///   consistent with ARCHITECTURE §3e "Unnamed" run semantics.
    private func commit() {
        let decision = EntitlementGate.canStartRun(
            currentLiveRunsOnChecklist: checklist.runs?.count ?? 0,
            limits: entitlementManager.limits
        )
        if case .blocked(let reason) = decision {
            paywallReason = reason
            showPaywall = true
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let run = try? RunStore.startRun(on: checklist, name: trimmed.isEmpty ? nil : trimmed, in: ctx) {
            onStarted(run)
        }
        dismiss()
    }
}
