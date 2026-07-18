import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "hand.raised.fill",
            "Grant Accessibility",
            "Panevo needs Accessibility permission to move and resize windows. Open System Settings and enable Panevo."
        ),
        (
            "keyboard.fill",
            "Keyboard Shortcuts",
            "Use ⌃⌥ + arrows to snap windows. Open Shortcuts in Panevo to customize every action."
        ),
        (
            "rectangle.split.2x1.fill",
            "Drag, Palette & More",
            "Drag to edges to snap. Hold ⌃⌥ while dragging for the snap palette. Double-click a title bar to maximize."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .padding()
            }

            Spacer()

            let current = pages[page]
            Image(systemName: current.icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentBlue, Color.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 24)

            Text(LocalizedStringKey(current.title))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.bottom, 8)

            Text(LocalizedStringKey(current.body))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
                .padding(.horizontal, 32)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentBlue : Color.primary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)

            Button(action: advance) {
                Text(page == pages.count - 1 ? "Get Started" : "Next")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 36)
        }
        .frame(width: 480, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        SettingsManager.shared.hasCompletedOnboarding = true
        if page == 0 || !AccessibilityManager.shared.isAccessibilityEnabled {
            AccessibilityManager.shared.requestAccessibilityPermission()
        }
        onFinish()
    }
}
