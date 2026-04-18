import SwiftUI
import MessageUI

/// Help and support screen with contact options
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    
    private let supportEmail = "support@checklistapp.com"
    private let websiteURL = "https://www.checklistapp.com"
    
    var body: some View {
        NavigationStack {
            List {
                // Quick Help
                Section {
                    HelpTopicRow(
                        icon: "checklist",
                        title: "Creating Checklists",
                        description: "Tap the + button to create a new checklist"
                    )
                    
                    HelpTopicRow(
                        icon: "tag.fill",
                        title: "Using Tags",
                        description: "Organize items with tags for easy filtering"
                    )
                    
                    HelpTopicRow(
                        icon: "folder.fill",
                        title: "Categories",
                        description: "Group checklists into categories"
                    )
                    
                    HelpTopicRow(
                        icon: "square.and.pencil",
                        title: "Editing Items",
                        description: "Swipe left on any item to edit or delete"
                    )
                } header: {
                    Text("Quick Tips")
                }
                
                // Contact Support
                Section {
                    Button {
                        sendEmail()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.accentColor)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email Support")
                                    .foregroundStyle(.primary)
                                Text(supportEmail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Button {
                        if let url = URL(string: websiteURL) {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.accentColor)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Visit Website")
                                    .foregroundStyle(.primary)
                                Text(websiteURL)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Get in Touch")
                } footer: {
                    Text("We're here to help! Reach out with any questions or feedback.")
                }
                
                // FAQs
                Section {
                    DisclosureGroup {
                        Text("The free plan includes \(FeatureLimits.free.maxChecklists ?? 1) checklist and \(FeatureLimits.free.maxTags ?? 3) tags. Categories are a Premium feature. Upgrade to Premium for unlimited access to all features.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } label: {
                        Text("What's included in the free version?")
                            .font(.subheadline)
                    }
                    
                    DisclosureGroup {
                        Text("Go to Profile > Plan and tap 'Manage Subscription'. You can cancel anytime from your iOS Settings or the App Store.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } label: {
                        Text("How do I cancel my subscription?")
                            .font(.subheadline)
                    }
                    
                    DisclosureGroup {
                        Text("Your data is stored locally on your device and synced via iCloud (coming soon). We never access or store your personal checklist data on our servers.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } label: {
                        Text("Is my data private?")
                            .font(.subheadline)
                    }
                    
                    DisclosureGroup {
                        Text("Swipe left on any checklist in the main list to reveal the duplicate option. This creates a copy with all items included.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } label: {
                        Text("How do I duplicate a checklist?")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Frequently Asked Questions")
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    subject: "Checklist App Support",
                    recipients: [supportEmail],
                    body: """
                    
                    
                    ---
                    Device: \(UIDevice.current.model)
                    iOS: \(UIDevice.current.systemVersion)
                    App Version: \(Bundle.main.appVersion)
                    """
                )
            }
            .alert("Email Unavailable", isPresented: $showMailUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please configure Mail on your device or contact us at \(supportEmail)")
            }
        }
    }
    
    private func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showMailUnavailableAlert = true
        }
    }
}

// MARK: - Help Topic Row

private struct HelpTopicRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    HelpView()
}
