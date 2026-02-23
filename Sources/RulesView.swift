import SwiftUI

struct RulesView: View {
    @ObservedObject var appState: AppState
    @State private var showingAddRule = false
    @State private var editingRule: Rule?
    @State private var showingTemplates = false
    
    var body: some View {
        VStack(spacing: 0) {
            ModernRulesHeader(
                appState: appState,
                showingAddRule: $showingAddRule,
                showingTemplates: $showingTemplates
            )
            
            Divider()
            
            if appState.filteredRules.isEmpty {
                if appState.rules.isEmpty {
                    ModernEmptyState(
                        icon: "list.bullet.rectangle",
                        title: "No Rules Yet",
                        description: "Rules define how files are organized. Add your first rule to get started.",
                        action: ("Add First Rule", { showingAddRule = true })
                    )
                } else {
                    ModernEmptyState(
                        icon: "magnifyingglass",
                        title: "No Matching Rules",
                        description: "Try adjusting your search or filter criteria."
                    )
                }
            } else {
                ModernRulesList(
                    appState: appState,
                    editingRule: $editingRule
                )
            }
        }
        .background(DesignSystem.Colors.backgroundTertiary)
        .sheet(isPresented: $showingAddRule) {
            ModernRuleEditorView(appState: appState, existingRule: nil)
        }
        .sheet(item: $editingRule) { rule in
            ModernRuleEditorView(appState: appState, existingRule: rule)
        }
        .sheet(isPresented: $showingTemplates) {
            ModernTemplateBrowserView(appState: appState)
        }
    }
}

struct ModernRulesHeader: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddRule: Bool
    @Binding var showingTemplates: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Rules")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.primary)
                    
                    Text("\(appState.rules.filter(\.isEnabled).count) of \(appState.rules.count) rules active")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button(action: { showingTemplates = true }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Templates")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button(action: { showingAddRule = true }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "plus")
                            Text("Add Rule")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                ModernSearchField(
                    text: $appState.ruleSearchText,
                    placeholder: "Search rules..."
                )
                .frame(maxWidth: 300)
                
                if !appState.ruleGroups.isEmpty {
                    Picker("Group", selection: $appState.selectedRuleGroup) {
                        Text("All Groups")
                            .tag(nil as String?)
                        ForEach(appState.ruleGroups, id: \.self) { group in
                            Text(group)
                                .tag(group as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                Spacer()
                
                Text("\(appState.filteredRules.count) of \(appState.rules.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}

struct ModernRulesList: View {
    @ObservedObject var appState: AppState
    @Binding var editingRule: Rule?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md, pinnedViews: [.sectionHeaders]) {
                let groupedRules = Dictionary(grouping: appState.filteredRules) { $0.group ?? "Ungrouped" }
                let sortedGroups = groupedRules.keys.sorted()
                
                ForEach(sortedGroups, id: \.self) { group in
                    Section {
                        ForEach(groupedRules[group] ?? []) { rule in
                            ModernRuleRow(
                                rule: rule,
                                appState: appState,
                                onEdit: { editingRule = rule }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.xl)
                        }
                        .onDelete { indexSet in
                            let rulesInGroup = groupedRules[group] ?? []
                            let rulesToDelete = indexSet.map { rulesInGroup[$0] }
                            appState.rules.removeAll { rule in
                                rulesToDelete.contains { $0.id == rule.id }
                            }
                        }
                    } header: {
                        HStack {
                            Text(group)
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            Spacer()
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.backgroundTertiary)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
    }
}

struct ModernRuleRow: View {
    let rule: Rule
    @ObservedObject var appState: AppState
    let onEdit: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newValue in
                    if let index = appState.rules.firstIndex(where: { $0.id == rule.id }) {
                        let updated = Rule(
                            id: rule.id,
                            name: rule.name,
                            description: rule.description,
                            conditions: rule.conditions,
                            outcome: rule.outcome,
                            isEnabled: newValue,
                            group: rule.group,
                            tags: rule.tags
                        )
                        appState.rules[index] = updated
                    }
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text(rule.name)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(rule.isEnabled ? .primary : .secondary)
                    
                    if !rule.isEnabled {
                        ModernBadge(text: "Disabled", color: .secondary)
                    }
                    
                    if !rule.tags.isEmpty {
                        HStack(spacing: DesignSystem.Spacing.xxs) {
                            ForEach(rule.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(DesignSystem.Typography.captionSmall)
                                    .padding(.horizontal, DesignSystem.Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(DesignSystem.CornerRadius.xs)
                            }
                            if rule.tags.count > 3 {
                                Text("+\(rule.tags.count - 3)")
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Text(rule.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(rule.conditions.enumerated()), id: \.offset) { _, condition in
                        ModernConditionBadge(condition: condition)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    ModernOutcomeBadge(outcome: rule.outcome)
                }
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Text("Edit")
                    .font(DesignSystem.Typography.caption)
            }
            .buttonStyle(GhostButtonStyle())
            .opacity(isHovering ? 1 : 0.7)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.backgroundPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
        )
        .opacity(rule.isEnabled ? 1 : 0.7)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
}

struct ModernConditionBadge: View {
    let condition: RuleCondition
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: conditionIcon)
                .font(.system(size: 8))
            Text(conditionText)
        }
        .font(DesignSystem.Typography.captionSmall)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(DesignSystem.CornerRadius.xs)
    }
    
    private var conditionText: String {
        switch condition {
        case .fileExtension(let ext):
            return ".\(ext)"
        case .fileName(let contains):
            return "contains \"\(contains)\""
        case .fileSize(let bytes):
            return "> \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))"
        case .createdBefore(let date):
            return "created before \(date.formatted(date: .abbreviated, time: .omitted))"
        case .modifiedBefore(let date):
            return "modified before \(date.formatted(date: .abbreviated, time: .omitted))"
        case .isDirectory:
            return "is folder"
        }
    }
    
    private var conditionIcon: String {
        switch condition {
        case .fileExtension:
            return "doc"
        case .fileName:
            return "textformat"
        case .fileSize:
            return "externaldrive"
        case .createdBefore, .modifiedBefore:
            return "calendar"
        case .isDirectory:
            return "folder"
        }
    }
}

struct ModernOutcomeBadge: View {
    let outcome: RuleOutcome
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: outcomeIcon)
                .font(.system(size: 8))
            Text(outcomeText)
        }
        .font(DesignSystem.Typography.captionSmall)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(outcomeColor.opacity(0.1))
        .foregroundColor(outcomeColor)
        .cornerRadius(DesignSystem.CornerRadius.xs)
    }
    
    private var outcomeText: String {
        switch outcome {
        case .move(let url):
            return "Move to \(url.lastPathComponent)"
        case .copy(let url):
            return "Copy to \(url.lastPathComponent)"
        case .delete:
            return "Delete"
        case .rename:
            return "Rename"
        case .skip:
            return "Skip"
        }
    }
    
    private var outcomeIcon: String {
        switch outcome {
        case .move:
            return "arrow.right"
        case .copy:
            return "doc.on.doc"
        case .delete:
            return "trash"
        case .rename:
            return "pencil"
        case .skip:
            return "minus"
        }
    }
    
    private var outcomeColor: Color {
        switch outcome {
        case .move: return .green
        case .copy: return .blue
        case .delete: return .orange
        case .rename: return .purple
        case .skip: return .secondary
        }
    }
}

struct ModernRuleEditorView: View {
    @ObservedObject var appState: AppState
    let existingRule: Rule?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var conditionType: ConditionType = .fileExtension
    @State private var conditionValue: String = ""
    @State private var outcomeType: OutcomeType = .move
    @State private var destinationPath: String = ""
    @State private var showSecurityError = false
    @State private var group: String = ""
    @State private var tags: String = ""
    
    enum ConditionType: String, CaseIterable {
        case fileExtension = "File Extension"
        case fileName = "File Name Contains"
        case fileSize = "File Size Larger Than"
    }
    
    enum OutcomeType: String, CaseIterable {
        case move = "Move to Folder"
        case delete = "Move to Trash"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(existingRule == nil ? "Add Rule" : "Edit Rule")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                    .buttonStyle(GhostButtonStyle())
            }
            .padding(DesignSystem.Spacing.xl)
            
            Divider()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            Text("Rule Details")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: DesignSystem.Spacing.md) {
                                ModernFormField(label: "Name", placeholder: "e.g., Archive PDFs", text: $name)
                                ModernFormField(label: "Description", placeholder: "e.g., Move old PDF files to archive", text: $description)
                                
                                HStack {
                                    Text("Group:")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    HStack {
                                        TextField("Group name", text: $group, prompt: Text("Optional"))
                                            .textFieldStyle(.plain)
                                        
                                        if !appState.ruleGroups.isEmpty {
                                            Picker("", selection: $group) {
                                                Text("Select...").tag("")
                                                ForEach(appState.ruleGroups, id: \.self) { existingGroup in
                                                    Text(existingGroup).tag(existingGroup)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(width: 120)
                                        }
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                    .padding(.vertical, DesignSystem.Spacing.xs)
                                    .background(DesignSystem.Colors.backgroundSecondary)
                                    .cornerRadius(DesignSystem.CornerRadius.sm)
                                }
                                
                                ModernFormField(label: "Tags", placeholder: "Comma separated tags", text: $tags)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .groupBoxStyle(ModernGroupBoxStyle())
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            Text("When a file...")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Picker("Condition", selection: $conditionType) {
                                    ForEach(ConditionType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                switch conditionType {
                                case .fileExtension:
                                    ModernFormField(label: "Extension", placeholder: "pdf, jpg, etc.", text: $conditionValue)
                                case .fileName:
                                    ModernFormField(label: "Contains", placeholder: "Screenshot, etc.", text: $conditionValue)
                                case .fileSize:
                                    ModernFormField(label: "Size (MB)", placeholder: "100", text: $conditionValue)
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .groupBoxStyle(ModernGroupBoxStyle())
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            Text("Then...")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Picker("Action", selection: $outcomeType) {
                                    ForEach(OutcomeType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                
                                if outcomeType == .move {
                                    ModernFormField(label: "Destination", placeholder: "~/Documents/Archive", text: $destinationPath)
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                    }
                    .groupBoxStyle(ModernGroupBoxStyle())
                }
                .padding(DesignSystem.Spacing.xl)
            }
            
            Divider()
            
            HStack {
                Spacer()
                
                Button(action: saveRule) {
                    Text("Save Rule")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(name.isEmpty)
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .frame(width: 520, height: 520)
        .alert("Security Error", isPresented: $showSecurityError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The selected destination path is not allowed. Please choose a path within your home directory.")
        }
        .onAppear {
            if let rule = existingRule {
                name = rule.name
                description = rule.description
                group = rule.group ?? ""
                tags = rule.tags.joined(separator: ", ")
            }
        }
    }
    
    private func saveRule() {
        let condition: RuleCondition
        switch conditionType {
        case .fileExtension:
            condition = .fileExtension(is: conditionValue)
        case .fileName:
            condition = .fileName(contains: conditionValue)
        case .fileSize:
            let mb = Int64(conditionValue) ?? 100
            condition = .fileSize(largerThan: mb * 1_000_000)
        }
        
        let outcome: RuleOutcome
        switch outcomeType {
        case .move:
            let path = destinationPath.isEmpty ? NSHomeDirectory() + "/Documents/Organized" : 
                       (destinationPath.hasPrefix("~") ? NSHomeDirectory() + destinationPath.dropFirst() : destinationPath)
            guard isPathAllowed(path) else {
                showSecurityError = true
                return
            }
            outcome = .move(to: URL(fileURLWithPath: path))
        case .delete:
            outcome = .delete
        }
        
        let rule = Rule(
            id: existingRule?.id ?? UUID(),
            name: name,
            description: description,
            conditions: [condition],
            outcome: outcome,
            group: group.isEmpty ? nil : group,
            tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        )
        
        if let existing = existingRule,
           let index = appState.rules.firstIndex(where: { $0.id == existing.id }) {
            appState.rules[index] = rule
        } else {
            appState.rules.append(rule)
        }
        
        dismiss()
    }
    
    private func isPathAllowed(_ path: String) -> Bool {
        let allowedPrefixes = [
            NSHomeDirectory(),
            "/Users/",
            "/tmp/",
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
        ]
        
        let resolvedPath = (path as NSString).standardizingPath
        
        let blockedPrefixes = [
            "/System", "/usr/bin", "/usr/sbin", "/bin", "/sbin",
            "/etc", "/var", "/private", "/dev", "/Applications",
            NSHomeDirectory() + "/Library"
        ]
        
        for blocked in blockedPrefixes {
            if resolvedPath.hasPrefix(blocked) {
                return false
            }
        }
        
        return allowedPrefixes.contains { resolvedPath.hasPrefix($0) }
    }
}

struct ModernFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.CornerRadius.sm)
        }
    }
}

struct ModernGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .background(DesignSystem.Colors.backgroundPrimary)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
    }
}

struct ModernTemplateBrowserView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let templates = RuleTemplateLibrary.allTemplates
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Rule Templates")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.primary)
                    
                    Text("Choose a template to quickly create a rule")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(DesignSystem.Spacing.xl)
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: DesignSystem.Spacing.lg) {
                    ForEach(templates) { template in
                        TemplateCard(template: template) {
                            appState.rules.append(template.rule)
                            dismiss()
                        }
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .frame(width: 700, height: 500)
        .background(DesignSystem.Colors.backgroundTertiary)
    }
}

struct TemplateCard: View {
    let template: RuleTemplate
    let onSelect: () -> Void
    @State private var isHovering = false
    
    private var color: Color {
        switch template.category {
        case .documents: return .blue
        case .images: return .purple
        case .development: return .green
        case .media: return .orange
        case .archives: return .gray
        case .productivity: return .pink
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                        .frame(width: 48, height: 48)
                        .background(color.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                        .opacity(isHovering ? 1 : 0.5)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(template.name)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundPrimary)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(isHovering ? color.opacity(0.3) : DesignSystem.Colors.border, lineWidth: 1)
            )
            .shadow(
                color: isHovering ? color.opacity(0.1) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
}
