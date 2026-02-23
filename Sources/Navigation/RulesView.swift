import SwiftUI
import ClippyCore
import ClippyEngine

struct RulesView: View {
    @ObservedObject var appState: AppState
    @State private var showingAddRule = false
    @State private var editingRule: Rule?
    
    var body: some View {
        VStack(spacing: 0) {
            RulesHeaderView(appState: appState, showingAddRule: $showingAddRule)
            Divider()
            if appState.filteredRules.isEmpty {
                if appState.rules.isEmpty {
                    EmptyRulesView()
                } else {
                    NoMatchingRulesView()
                }
            } else {
                List {
                    let groupedRules = Dictionary(grouping: appState.filteredRules) { $0.group ?? "Ungrouped" }
                    let sortedGroups = groupedRules.keys.sorted()
                    ForEach(sortedGroups, id: \.self) { group in
                        Section(header: Text(group).font(.headline).foregroundColor(.secondary)) {
                            ForEach(groupedRules[group] ?? []) { rule in
                                RuleRowView(rule: rule, appState: appState, onEdit: {
                                    editingRule = rule
                                })
                            }
                            .onDelete { indexSet in
                                let rulesInGroup = groupedRules[group] ?? []
                                let rulesToDelete = indexSet.map { rulesInGroup[$0] }
                                appState.rules.removeAll { rule in
                                    rulesToDelete.contains { $0.id == rule.id }
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .sheet(isPresented: $showingAddRule) {
            RuleEditorView(appState: appState, existingRule: nil)
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorView(appState: appState, existingRule: rule)
        }
    }
}

struct RulesHeaderView: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddRule: Bool
    @State private var showingTemplates = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UICopy.Rules.title).font(.title2).fontWeight(.semibold)
                    Text(UICopy.Rules.subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button { showingTemplates = true } label: {
                        Label("Templates", systemImage: "doc.text.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    Button { showingAddRule = true } label: {
                        Label(UICopy.Rules.addButton, systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingTemplates) {
                TemplateBrowserView(appState: appState)
            }
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search rules...", text: $appState.ruleSearchText).textFieldStyle(.plain)
                    if !appState.ruleSearchText.isEmpty {
                        Button { appState.ruleSearchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                if !appState.ruleGroups.isEmpty {
                    Picker("Group", selection: $appState.selectedRuleGroup) {
                        Text("All Groups").tag(nil as String?)
                        ForEach(appState.ruleGroups, id: \.self) { group in
                            Text(group).tag(group as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                Spacer()
                Text("\(appState.filteredRules.count) of \(appState.rules.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct NoMatchingRulesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass").font(.system(size: 48)).foregroundColor(.secondary.opacity(0.5))
            Text("No matching rules").font(.title3).fontWeight(.medium)
            Text("Try adjusting your search or filter criteria.").font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyRulesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle").font(.system(size: 48)).foregroundColor(.secondary.opacity(0.5))
            Text(UICopy.Rules.emptyTitle).font(.title3).fontWeight(.medium)
            Text(UICopy.Rules.emptyBody).font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RuleRowView: View {
    let rule: Rule
    @ObservedObject var appState: AppState
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { newValue in
                    if let index = appState.rules.firstIndex(where: { $0.id == rule.id }) {
                        appState.rules[index] = Rule(
                            id: rule.id, name: rule.name, description: rule.description,
                            conditions: rule.conditions, outcome: rule.outcome,
                            isEnabled: newValue, group: rule.group, tags: rule.tags
                        )
                    }
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(rule.name).fontWeight(.medium)
                    if !rule.isEnabled {
                        Text(UICopy.Rules.disabled).font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2)).cornerRadius(4)
                    }
                    if !rule.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(rule.tags.prefix(3), id: \.self) { tag in
                                Text(tag).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1)).foregroundColor(.accentColor).cornerRadius(4)
                            }
                            if rule.tags.count > 3 {
                                Text("+\(rule.tags.count - 3)").font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                Text(rule.description).font(.caption).foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(Array(rule.conditions.enumerated()), id: \.offset) { _, condition in
                        ConditionBadge(condition: condition)
                    }
                    Text("→").foregroundColor(.secondary)
                    OutcomeBadge(outcome: rule.outcome)
                }
                .font(.caption2)
            }
            Spacer()
            Button(UICopy.Rules.editButton) { onEdit() }.buttonStyle(.bordered).controlSize(.small)
        }
        .padding(.vertical, 8)
        .opacity(rule.isEnabled ? 1 : 0.6)
    }
}

struct ConditionBadge: View {
    let condition: RuleCondition
    var body: some View {
        Text(conditionText)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(4)
    }
    private var conditionText: String {
        switch condition {
        case .fileExtension(let ext): return UICopy.Common.conditionExt(ext)
        case .fileName(let contains): return UICopy.Common.conditionContains(contains)
        case .fileSize(let bytes): return UICopy.Common.conditionSize(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
        case .createdBefore(let date): return "created " + UICopy.Common.conditionDate(date.formatted(date: .abbreviated, time: .omitted))
        case .modifiedBefore(let date): return "modified " + UICopy.Common.conditionDate(date.formatted(date: .abbreviated, time: .omitted))
        case .isDirectory: return UICopy.Common.conditionFolder
        }
    }
}

struct OutcomeBadge: View {
    let outcome: RuleOutcome
    var body: some View {
        Text(outcomeText)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(outcomeColor.opacity(0.1)).foregroundColor(outcomeColor).cornerRadius(4)
    }
    private var outcomeText: String {
        switch outcome {
        case .move(let url): return UICopy.Execution.movedTo(url.lastPathComponent)
        case .copy(let url): return "Copy to \(url.lastPathComponent)"
        case .delete: return UICopy.Rules.actionDelete
        case .rename(let prefix, let suffix): return UICopy.Common.outcomeRename(prefix, suffix)
        case .skip(let reason): return UICopy.Execution.skipped(reason)
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

struct RuleEditorView: View {
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
        case fileExtension, fileName, fileSize
        var rawValue: String {
            switch self {
            case .fileExtension: return UICopy.Rules.conditionExtension
            case .fileName: return UICopy.Rules.conditionName
            case .fileSize: return UICopy.Rules.conditionSize
            }
        }
    }
    
    enum OutcomeType: String, CaseIterable {
        case move, delete
        var rawValue: String {
            switch self {
            case .move: return UICopy.Rules.actionMove
            case .delete: return UICopy.Rules.actionDelete
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(existingRule == nil ? UICopy.Rules.editorAddTitle : UICopy.Rules.editorEditTitle).font(.headline)
                Spacer()
                Button(UICopy.Rules.cancelButton) { dismiss() }.keyboardShortcut(.escape)
            }
            .padding()
            Divider()
            ScrollView {
                VStack(spacing: 24) {
                    GroupBox(label: Text(UICopy.Rules.sectionDetails).font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Name", text: $name, prompt: Text(UICopy.Rules.namePlaceholder))
                            TextField("Description", text: $description, prompt: Text(UICopy.Rules.descPlaceholder))
                            HStack {
                                Text("Group:").foregroundColor(.secondary)
                                TextField("Group name", text: $group, prompt: Text("Optional"))
                                if !appState.ruleGroups.isEmpty {
                                    Picker("", selection: $group) {
                                        Text("Select...").tag("")
                                        ForEach(appState.ruleGroups, id: \.self) { g in Text(g).tag(g) }
                                    }
                                    .pickerStyle(.menu).frame(width: 120)
                                }
                            }
                            HStack {
                                Text("Tags:").foregroundColor(.secondary)
                                TextField("Comma separated tags", text: $tags, prompt: Text("e.g., important, archive, work"))
                            }
                        }
                        .padding(8)
                    }
                    GroupBox(label: Text(UICopy.Rules.sectionConditions).font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Condition", selection: $conditionType) {
                                ForEach(ConditionType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .labelsHidden()
                            switch conditionType {
                            case .fileExtension: TextField("Extension", text: $conditionValue, prompt: Text("pdf"))
                            case .fileName: TextField("Contains", text: $conditionValue, prompt: Text("Screenshot"))
                            case .fileSize: TextField("Size in MB", text: $conditionValue, prompt: Text("100"))
                            }
                        }
                        .padding(8)
                    }
                    GroupBox(label: Text(UICopy.Rules.sectionOutcomes).font(.headline)) {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Action", selection: $outcomeType) {
                                ForEach(OutcomeType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .labelsHidden()
                            if outcomeType == .move {
                                TextField("Destination folder path", text: $destinationPath, prompt: Text("~/Documents/Archive"))
                            }
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            Divider()
            HStack {
                Spacer()
                Button(UICopy.Rules.saveButton) { saveRule() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 450)
        .alert("Security Error", isPresented: $showSecurityError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The selected destination path is not allowed. Please choose a path within your home directory or Documents folder.")
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
        case .fileExtension: condition = .fileExtension(is: conditionValue)
        case .fileName: condition = .fileName(contains: conditionValue)
        case .fileSize:
            let mb = Int64(conditionValue) ?? 100
            condition = .fileSize(largerThan: mb * 1_000_000)
        }
        let outcome: RuleOutcome
        switch outcomeType {
        case .move:
            let path = destinationPath.isEmpty ? NSHomeDirectory() + "/Documents/Organized" :
                (destinationPath.hasPrefix("~") ? NSHomeDirectory() + destinationPath.dropFirst() : destinationPath)
            guard isPathAllowed(path) else { showSecurityError = true; return }
            outcome = .move(to: URL(fileURLWithPath: path))
        case .delete: outcome = .delete
        }
        let rule = Rule(
            id: existingRule?.id ?? UUID(), name: name, description: description,
            conditions: [condition], outcome: outcome,
            group: group.isEmpty ? nil : group,
            tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        )
        if let existing = existingRule, let index = appState.rules.firstIndex(where: { $0.id == existing.id }) {
            appState.rules[index] = rule
        } else {
            appState.rules.append(rule)
        }
        dismiss()
    }
    
    private func isPathAllowed(_ path: String) -> Bool {
        let allowedPrefixes = [NSHomeDirectory(), "/Users/", "/tmp/", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""]
        let resolvedPath = (path as NSString).standardizingPath
        let blockedPrefixes = ["/System", "/usr/bin", "/usr/sbin", "/bin", "/sbin", "/etc", "/var", "/private", "/dev", "/Applications", NSHomeDirectory() + "/Library"]
        for blocked in blockedPrefixes { if resolvedPath.hasPrefix(blocked) { return false } }
        return allowedPrefixes.contains { resolvedPath.hasPrefix($0) }
    }
}
