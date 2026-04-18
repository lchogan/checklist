import SwiftUI

/// About screen with app information
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon & Name
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                            .padding(.top, 32)
                        
                        Text("Checklist")
                            .font(.largeTitle.bold())
                        
                        Text("Version \(Bundle.main.appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // About Text
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Our Story")
                            .font(.title2.bold())
                        
                        Text("""
                        Checklist was born from a simple idea: staying organized shouldn't be complicated.
                        
                        We built this app because we believe that great productivity tools should be intuitive, beautiful, and accessible to everyone. Whether you're planning your weekly groceries, managing a project, or just trying to remember your daily tasks, Checklist is here to help.
                        
                        Our mission is to help you focus on what matters by making it effortless to capture, organize, and complete your tasks.
                        """)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)
                    
                    // Values
                    VStack(spacing: 16) {
                        ValueCard(
                            icon: "lock.shield.fill",
                            title: "Privacy First",
                            description: "Your data stays on your device. We never access or store your personal information."
                        )
                        
                        ValueCard(
                            icon: "paintbrush.fill",
                            title: "Beautifully Simple",
                            description: "We believe powerful tools should be easy to use. No unnecessary complexity."
                        )
                        
                        ValueCard(
                            icon: "heart.fill",
                            title: "Made with Care",
                            description: "Built by a small team who genuinely cares about creating great experiences."
                        )
                    }
                    .padding(.horizontal)
                    
                    // Credits
                    VStack(spacing: 8) {
                        Text("Made with ❤️ in 2026")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("© 2026 Checklist App")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Value Card

private struct ValueCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    AboutView()
}
