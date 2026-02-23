import SwiftUI

// MARK: - Modern Statistics Dashboard

struct StatisticsDashboardView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Statistics")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.primary)
                    
                    Text("Track rule effectiveness and file patterns")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.backgroundPrimary)
            
            Divider()
            
            // Stats Content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Summary Cards
                    ModernStatSummaryCards(appState: appState)
                    
                    // File Types Breakdown
                    if let scanResult = appState.scanResult {
                        FileTypesBreakdown(files: scanResult.files)
                    }
                    
                    // Recent Activity
                    RecentActivitySection(history: appState.historyManager.sessions)
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.backgroundTertiary)
    }
}

struct ModernStatSummaryCards: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.lg) {
            ModernStatCard(
                title: "Total Files",
                value: "\(appState.scanResult?.files.count ?? 0)",
                icon: "doc.fill",
                color: DesignSystem.Colors.accentBlue
            )
            
            ModernStatCard(
                title: "Active Rules",
                value: "\(appState.rules.filter(\.isEnabled).count)",
                icon: "list.bullet.rectangle.fill",
                color: DesignSystem.Colors.accentPurple
            )
            
            ModernStatCard(
                title: "Operations",
                value: "\(appState.historyManager.sessions.reduce(0) { $0 + $1.items.count })",
                icon: "clock.arrow.circlepath",
                color: DesignSystem.Colors.accentOrange
            )
        }
    }
}

struct FileTypesBreakdown: View {
    let files: [FileDescriptor]
    
    private var fileTypeCounts: [(String, Int, Color)] {
        let extensions = files.compactMap { file in
            file.fileURL.pathExtension.lowercased()
        }
        
        var counts: [String: Int] = [:]
        for ext in extensions {
            counts[ext, default: 0] += 1
        }
        
        let sorted = counts.sorted { $0.value > $1.value }.prefix(6)
        
        let colors: [Color] = [
            DesignSystem.Colors.accentBlue,
            DesignSystem.Colors.accentPurple,
            DesignSystem.Colors.accentTeal,
            DesignSystem.Colors.accentOrange,
            DesignSystem.Colors.accentPink,
            DesignSystem.Colors.accentBlue.opacity(0.6)
        ]
        
        return sorted.enumerated().map { (index, pair) in
            (pair.key.uppercased(), pair.value, colors[index % colors.count])
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("File Types")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(files.count) total")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            if fileTypeCounts.isEmpty {
                Text("No files scanned yet")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, DesignSystem.Spacing.lg)
            } else {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
                    // Left side - bars
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(fileTypeCounts, id: \.0) { type, count, color in
                            HStack(spacing: DesignSystem.Spacing.md) {
                                Text(type)
                                    .font(DesignSystem.Typography.caption)
                                    .fontWeight(.medium)
                                    .frame(width: 50, alignment: .leading)
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                            .fill(Color.gray.opacity(0.08))
                                            .frame(height: 10)
                                        
                                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                            .fill(
                                                LinearGradient(
                                                    colors: [color, color.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: max(CGFloat(count) / CGFloat(files.count) * geometry.size.width, 20), height: 10)
                                    }
                                }
                                .frame(height: 10)
                                
                                Text("\(count)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                    
                    // Right side - pie chart representation
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(fileTypeCounts, id: \.0) { type, count, color in
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 10, height: 10)
                                Text(type)
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(width: 80)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundPrimary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

struct RecentActivitySection: View {
    let history: [HistorySession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Recent Activity")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(.primary)
            
            if history.isEmpty {
                Text("No activity yet")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .padding(.vertical, DesignSystem.Spacing.lg)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(history.prefix(5)) { session in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            
                            Text("Organized \(session.items.count) files")
                                .font(DesignSystem.Typography.body)
                            
                            Spacer()
                            
                            Text(session.formattedDate)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundPrimary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}
