import SwiftUI

// MARK: - Design System
// Modern, professional design system for Clippy

enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        static let primary = Color.accentColor
        static let primaryLight = Color.accentColor.opacity(0.15)
        
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        static let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentPurple = Color(red: 0.69, green: 0.32, blue: 0.87)
        static let accentTeal = Color(red: 0.19, green: 0.82, blue: 0.67)
        static let accentPink = Color(red: 1.0, green: 0.41, blue: 0.71)
        static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
        
        static let backgroundPrimary = Color(NSColor.windowBackgroundColor)
        static let backgroundSecondary = Color(NSColor.controlBackgroundColor)
        static let backgroundTertiary = Color(NSColor.textBackgroundColor)
        
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.secondary.opacity(0.7)
        
        static let divider = Color.gray.opacity(0.2)
        static let border = Color.gray.opacity(0.15)
        
        static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.5)
        static let cardHover = Color(NSColor.controlBackgroundColor)
    }
    
    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 17, weight: .semibold)
        
        static let bodyLarge = Font.system(size: 15, weight: .regular)
        static let body = Font.system(size: 14, weight: .regular)
        static let bodySmall = Font.system(size: 13, weight: .regular)
        
        static let caption = Font.system(size: 12, weight: .medium)
        static let captionSmall = Font.system(size: 11, weight: .medium)
        static let button = Font.system(size: 14, weight: .semibold)
        
        static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)
        static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 3
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 18
        static let full: CGFloat = 9999
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .foregroundColor(.primary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundSecondary.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
    }
}

// MARK: - Modern Components

struct ModernQuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(DesignSystem.CornerRadius.sm)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Text(label)
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct ModernEmptyState: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = DesignSystem.Colors.accentBlue
    var action: (String, (() -> Void))?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(color.opacity(0.6))
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            if let action = action {
                Button(action: action.1) {
                    Text(action.0)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xxl)
    }
}

struct ModernSearchField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.backgroundSecondary)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.CornerRadius.full)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.full)
                        .stroke(isSelected ? DesignSystem.Colors.accentBlue : DesignSystem.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
