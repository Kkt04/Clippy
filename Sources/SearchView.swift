import SwiftUI

// MARK: - Modern Search View

struct GlobalSearchView: View {
    @ObservedObject var appState: AppState
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Search")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.primary)
                    
                    Text("Search across files, rules, and history")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.backgroundPrimary)
            
            Divider()
            
            // Search Bar
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernSearchField(
                    text: $searchText,
                    placeholder: "Search files, rules, history..."
                )
                .onChange(of: searchText) { newValue in
                    appState.searchManager.search(query: newValue)
                }
                
                // Filter chips
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(SearchableItemType.allCases, id: \.self) { type in
                        ModernFilterChip(
                            title: type.rawValue,
                            isSelected: appState.searchManager.selectedTypes.contains(type)
                        ) {
                            if appState.searchManager.selectedTypes.contains(type) {
                                appState.searchManager.selectedTypes.remove(type)
                            } else {
                                appState.searchManager.selectedTypes.insert(type)
                            }
                            if !searchText.isEmpty {
                                appState.searchManager.search(query: searchText)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(DesignSystem.Spacing.xl)
            
            Divider()
            
            // Results
            if appState.searchManager.searchResults.isEmpty {
                if searchText.isEmpty {
                    ModernEmptyState(
                        icon: "magnifyingglass",
                        title: "Start Searching",
                        description: "Type above to search across files, rules, and history."
                    )
                } else {
                    ModernEmptyState(
                        icon: "magnifyingglass.circle",
                        title: "No Results Found",
                        description: "Try adjusting your search terms or filters."
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(appState.searchManager.searchResults) { result in
                            SearchResultCard(result: result)
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
        }
        .background(DesignSystem.Colors.backgroundTertiary)
        .onAppear {
            appState.searchManager.updateData(
                files: appState.scanResult?.files ?? [],
                rules: appState.rules,
                history: appState.historyManager.sessions
            )
        }
    }
}

struct SearchResultCard: View {
    let result: SearchResultItem
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: result.icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 48, height: 48)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.md)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(result.title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(result.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                ModernBadge(text: result.type.rawValue, color: .blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundPrimary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(isHovering ? DesignSystem.Colors.primary.opacity(0.2) : DesignSystem.Colors.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
}
