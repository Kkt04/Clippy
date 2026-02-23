import SwiftUI

// MARK: - Design System
// Modern, professional design system for File Scanner App

enum DesignSystem {
    
    // MARK: - Colors
    enum Colors {
        // Primary brand colors - Modern gradient palette
        static let primary = Color.accentColor
        static let primaryLight = Color.accentColor.opacity(0.15)
        static let primaryGradient = LinearGradient(
            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Modern accent palette
        static let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let accentPurple = Color(red: 0.69, green: 0.32, blue: 0.87)
        static let accentTeal = Color(red: 0.19, green: 0.82, blue: 0.67)
        static let accentPink = Color(red: 1.0, green: 0.41, blue: 0.71)
        static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
        
        // Background colors
        static let backgroundPrimary = Color(NSColor.windowBackgroundColor)
        static let backgroundSecondary = Color(NSColor.controlBackgroundColor)
        static let backgroundTertiary = Color(NSColor.textBackgroundColor)
        
        // Glass effect colors
        static let glassBackground = Color.white.opacity(0.7)
        static let glassBorder = Color.white.opacity(0.5)
        
        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.secondary.opacity(0.7)
        
        // Border and divider
        static let divider = Color.gray.opacity(0.2)
        static let border = Color.gray.opacity(0.15)
        static let borderLight = Color.gray.opacity(0.08)
        
        // Card backgrounds
        static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.5)
        static let cardHover = Color(NSColor.controlBackgroundColor)
        
        // Status colors with opacity
        static func statusColor(_ status: Status) -> Color {
            switch status {
            case .success: return success
            case .warning: return warning
            case .error: return error
            case .info: return info
            case .neutral: return .secondary
            }
        }
        
        enum Status {
            case success, warning, error, info, neutral
        }
    }
    
    // MARK: - Typography
    enum Typography {
        // Large titles - Modern rounded style
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 17, weight: .semibold)
        
        // Body text
        static let bodyLarge = Font.system(size: 15, weight: .regular)
        static let body = Font.system(size: 14, weight: .regular)
        static let bodySmall = Font.system(size: 13, weight: .regular)
        
        // Specialized
        static let caption = Font.system(size: 12, weight: .medium)
        static let captionSmall = Font.system(size: 11, weight: .medium)
        static let button = Font.system(size: 14, weight: .semibold)
        static let badge = Font.system(size: 11, weight: .semibold)
        
        // Monospace for technical data
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
        
        // Section spacing
        static let sectionGap: CGFloat = 24
        static let cardGap: CGFloat = 16
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
    
    // MARK: - Shadows
    enum Shadows {
        static let sm = ShadowStyle(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
        static let md = ShadowStyle(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        static let lg = ShadowStyle(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        static let xl = ShadowStyle(color: .black.opacity(0.14), radius: 20, x: 0, y: 8)
        
        struct ShadowStyle {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    enum Animation {
        static let fast = SwiftUI.Animation.easeOut(duration: 0.12)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.75)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    // MARK: - Layout
    enum Layout {
        static let sidebarWidth: CGFloat = 220
        static let minWindowWidth: CGFloat = 1000
        static let minWindowHeight: CGFloat = 700
        static let maxContentWidth: CGFloat = 1400
        static let headerHeight: CGFloat = 64
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    var isHovering: Bool = false
    var hasShadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .shadow(
                color: hasShadow ? DesignSystem.Shadows.md.color : .clear,
                radius: hasShadow ? DesignSystem.Shadows.md.radius : 0,
                x: DesignSystem.Shadows.md.x,
                y: DesignSystem.Shadows.md.y
            )
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(isHovering ? DesignSystem.Colors.cardHover : Color.clear)
            )
    }
}

struct GlassCardStyle: ViewModifier {
    var isHovering: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.glassBorder, lineWidth: 1)
            )
            .shadow(
                color: isHovering ? DesignSystem.Shadows.lg.color : DesignSystem.Shadows.sm.color,
                radius: isHovering ? DesignSystem.Shadows.lg.radius : DesignSystem.Shadows.sm.radius,
                x: 0,
                y: isHovering ? DesignSystem.Shadows.lg.y : DesignSystem.Shadows.sm.y
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if isEnabled {
                if isDestructive {
                    configuration.label
                        .font(DesignSystem.Typography.button)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .fill(DesignSystem.Colors.error)
                        )
                        .foregroundColor(.white)
                        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                        .opacity(configuration.isPressed ? 0.9 : 1.0)
                        .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
                } else {
                    configuration.label
                        .font(DesignSystem.Typography.button)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [DesignSystem.Colors.primary, DesignSystem.Colors.primary.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                        .opacity(configuration.isPressed ? 0.9 : 1.0)
                        .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
                }
            } else {
                configuration.label
                    .font(DesignSystem.Typography.button)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.primary.opacity(0.4))
                    )
                    .foregroundColor(.white)
                    .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
                    .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
            }
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(isDestructive ? DesignSystem.Colors.error.opacity(0.3) : DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
            .foregroundColor(isDestructive ? DesignSystem.Colors.error : .primary)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.button)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(configuration.isPressed 
                        ? (isDestructive ? DesignSystem.Colors.error.opacity(0.1) : DesignSystem.Colors.primary.opacity(0.1))
                        : Color.clear)
            )
            .foregroundColor(isDestructive ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(isHovering: Bool = false, hasShadow: Bool = true) -> some View {
        modifier(CardStyle(isHovering: isHovering, hasShadow: hasShadow))
    }
    
    func glassCardStyle(isHovering: Bool = false) -> some View {
        modifier(GlassCardStyle(isHovering: isHovering))
    }
}

// MARK: - Custom Components

struct ModernBadge: View {
    let text: String
    let color: Color
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(DesignSystem.Typography.badge)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm + 2)
        .padding(.vertical, DesignSystem.Spacing.xs + 1)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.full)
                .fill(color.opacity(0.15))
        )
        .foregroundColor(color)
    }
}

struct StatusIndicator: View {
    let status: DesignSystem.Colors.Status
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(DesignSystem.Colors.statusColor(status))
                .frame(width: 8, height: 8)
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil
    var trend: Trend? = nil
    
    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let trend = trend {
                    TrendView(trend: trend)
                }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(value)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }
}

struct TrendView: View {
    let trend: ModernStatCard.Trend
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(DesignSystem.Typography.captionSmall)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.12))
        .foregroundColor(foregroundColor)
        .cornerRadius(DesignSystem.CornerRadius.xs)
    }
    
    private var icon: String {
        switch trend {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }
    
    private var text: String {
        switch trend {
        case .up(let t), .down(let t), .neutral(let t): return t
        }
    }
    
    private var foregroundColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .orange
        case .neutral: return .secondary
        }
    }
    
    private var backgroundColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .orange
        case .neutral: return .gray
        }
    }
}

struct ModernEmptyState: View {
    let icon: String
    let title: String
    let description: String
    var action: (title: String, action: () -> Void)? = nil
    var color: Color = DesignSystem.Colors.primary
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.12), color.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: 90, height: 90)
                
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(color.opacity(0.7))
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: 360)
            }
            
            if let action = action {
                Button(action: action.action) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text(action.title)
                    }
                    .font(DesignSystem.Typography.button)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

struct ModernSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (title: String, action: () -> Void)? = nil
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let action = action {
                Button(action: action.action) {
                    Text(action.title)
                        .font(DesignSystem.Typography.button)
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
    }
}

struct ModernSearchField: View {
    @Binding var text: String
    let placeholder: String
    var onClear: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            TextField(placeholder, text: $text)
                .font(DesignSystem.Typography.body)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                    onClear?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
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
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.backgroundSecondary)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.CornerRadius.full)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.full)
                        .stroke(isSelected ? Color.clear : DesignSystem.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ModernProgressView: View {
    let title: String
    let subtitle: String
    var progress: Double? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            if let progress = progress {
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.primary.opacity(0.1), lineWidth: 6)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [DesignSystem.Colors.accentBlue, DesignSystem.Colors.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(DesignSystem.Animation.normal, value: progress)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            } else {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.accentBlue.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(DesignSystem.Colors.accentBlue)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let onCancel = onCancel {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(DesignSystem.Typography.button)
                }
                .buttonStyle(GhostButtonStyle())
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .cardStyle()
    }
}

struct ModernListRow<Content: View>: View {
    @ViewBuilder let content: Content
    var isSelected: Bool = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            content
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(isSelected ? DesignSystem.Colors.primary.opacity(0.08) : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
