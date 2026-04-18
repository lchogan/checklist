import SwiftUI

/// Main profile/settings screen
struct ProfileView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showPlanView = false
    @State private var showHelpView = false
    @State private var showTutorial = false
    @State private var showAboutView = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome")
                                .font(.title2.bold())
                            
                            HStack(spacing: 6) {
                                Image(systemName: entitlementManager.isPremium ? "checkmark.seal.fill" : "circle")
                                    .font(.caption)
                                Text(entitlementManager.isPremium ? "Premium" : "Free Plan")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(entitlementManager.isPremium ? .green : .secondary)
                            
                            if entitlementManager.isPremium {
                                HStack(spacing: 4) {
                                    Image(systemName: "icloud.fill")
                                        .font(.caption2)
                                    Text("iCloud Sync Active")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Subscription
                Section {
                    Button {
                        showPlanView = true
                    } label: {
                        HStack {
                            Label("Plan", systemImage: "crown.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            if !entitlementManager.isPremium {
                                Text("Upgrade")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.accentColor)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                // Help & Support
                Section {
                    Button {
                        showTutorial = true
                    } label: {
                        HStack {
                            Label("Tutorial", systemImage: "play.circle.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button {
                        showHelpView = true
                    } label: {
                        HStack {
                            Label("Help & Support", systemImage: "questionmark.circle.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                // About
                Section {
                    Button {
                        showAboutView = true
                    } label: {
                        HStack {
                            Label("About", systemImage: "info.circle.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                // App Version
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPlanView) {
                PlanView()
            }
            .sheet(isPresented: $showHelpView) {
                HelpView()
            }
            .sheet(isPresented: $showTutorial) {
                TutorialView()
            }
            .sheet(isPresented: $showAboutView) {
                AboutView()
            }
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    ProfileView()
        .environmentObject(EntitlementManager())
}
