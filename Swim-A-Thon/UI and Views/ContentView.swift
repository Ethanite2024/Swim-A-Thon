//
//  ContentView.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 6/24/25.
//

import SwiftUI
import SwiftData
import Combine

struct LapCounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Swimmer.createdAt, order: .forward) private var swimmers: [Swimmer]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var newSwimmerName: String = ""
    @State private var nameHelper: String? = nil
    @FocusState private var isNameFieldFocused: Bool

    @State private var pendingDeletion: Swimmer? = nil
    @State private var showUndoBanner: Bool = false
    @State private var lastDeleted: (name: String, laps: Int)? = nil

    // NEW: Add button animation state
    @State private var addButtonEnabled: Bool = false
    @State private var addButtonGlow: Bool = false

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var showTutorial: Bool = false
    
    @AppStorage("reduceLag") private var reduceLag: Bool = false

    @State private var showSettings: Bool = false

    private let metersPerLap = 25

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics(width: proxy.size.width)

            ZStack(alignment: .bottom) {
                // Content
                ScrollView {
                    VStack(spacing: metrics.vStackSpacing) {
                        addSwimmerBar(metrics: metrics)

                        if swimmers.isEmpty {
                            EmptyState(metrics: metrics)
                                .padding(.horizontal, metrics.horizontalPadding)
                                .padding(.top, 24)
                                // NEW: gentle appear transition
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            ForEach(swimmers, id: \.id) { item in
                                SwimmerRow(
                                    item: item,
                                    metersPerLap: metersPerLap,
                                    metrics: metrics,
                                    onDeleteRequest: { pendingDeletion = item }
                                )
                                .padding(.horizontal, metrics.horizontalPadding)
                                // NEW: row appear/disappear transitions
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    // Apply only top padding to avoid lifting content above the waves
                    .padding(.top, metrics.verticalPadding)
                }
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { isNameFieldFocused = false }
                            .keyboardShortcut(.escape, modifiers: [])
                    }
                }
                .onTapGesture { isNameFieldFocused = false }
                .alert("Delete swimmer?", isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                )) {
                    Button("Delete", role: .destructive) { confirmDelete() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    if let item = pendingDeletion {
                        Text("This will remove \(item.name) and their lap count.")
                    }
                }
                .overlay(alignment: .bottom) {
                    if showUndoBanner, let lastDeleted {
                        UndoBanner(name: lastDeleted.name, laps: lastDeleted.laps, metrics: metrics) {
                            undoDelete()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                }
                .animation(reduceMotion ? .default : .spring(response: 0.45, dampingFraction: 0.9), value: swimmers)
                .animation(.snappy, value: showUndoBanner)
                .onAppear {
                    if !hasSeenTutorial {
                        showTutorial = true
                    }
                }
                // Tutorial full screen cover overlay
                .fullScreenCover(isPresented: $showTutorial) {
                    TutorialView(dismiss: {
                        hasSeenTutorial = true
                        showTutorial = false
                    }, reduceLag: $reduceLag)
                }

                // Decorative animated waves at the bottom
                if !reduceLag {
                    AnimatedWaves()
                        // Make the waves a bit taller so they can extend under the safe area
                        .frame(height: max(210, 260 * metrics.scale))
                        // Allow drawing under the home indicator/safe area
                        .ignoresSafeArea(edges: .bottom)
                        // Pull the waves down slightly to visually continue beyond the bottom edge
                        .padding(.bottom, -100)
                        // NEW: subtle parallax based on scroll position (approx using geometry)
                        .offset(y: reduceMotion ? 0 : -min(20, proxy.safeAreaInsets.bottom / 2))
                        // NEW: dim slightly in dark mode
                        .opacity(colorScheme == .dark ? 0.9 : 1.0)
                        .accessibilityHidden(true)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsPlaceholderView(dismiss: { showSettings = false })
            }
        }
    }

    // MARK: - Add swimmer UI

    private func addSwimmerBar(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: metrics.hStackSpacing) {
                TextField("New swimmer name", text: $newSwimmerName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .font(metrics.baseFont)
                    .onChange(of: newSwimmerName) { _, _ in
                        validateName()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            addButtonEnabled = canAddName
                        }
                    }
                    .onSubmit {
                        addItem()
                    }
                    .accessibilityLabel("New swimmer name")
                    .accessibilityHint("Type a name and press Add")
                    // NEW: slight highlight sweep when first focused
                    .overlay(alignment: .trailing) {
                        if isNameFieldFocused && !reduceMotion && !reduceLag {
                            ShimmerView()
                                .frame(width: 60, height: 24)
                                .offset(x: 10)
                                .transition(.opacity)
                        }
                    }

                Button {
                    addItem()
                } label: {
                    Label("Add", systemImage: "person.badge.plus")
                        .labelStyle(metrics.buttonLabelStyle)
                        .font(metrics.buttonFont)
                        .frame(minHeight: metrics.buttonHeight)
                        .contentShape(Rectangle())
                }
                .apply(style: metrics.primaryButtonStyle)
                .disabled(!canAddName)
                // NEW: spring pop when becomes enabled
                .scaleEffect(addButtonEnabled ? 1.0 : 0.96)
                .animation(.spring(response: 0.28, dampingFraction: 0.8), value: addButtonEnabled)
                // NEW: pulsing glow when enabled and field has text
                .shadow(color: (addButtonEnabled && !reduceMotion) ? .blue.opacity(addButtonGlow ? 0.6 : 0.2) : .clear,
                        radius: addButtonGlow ? 10 : 4,
                        x: 0, y: 0)
                .onChange(of: addButtonEnabled) { _, enabled in
                    guard !reduceMotion else { return }
                    if enabled {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            addButtonGlow = true
                        }
                    } else {
                        addButtonGlow = false
                    }
                }
                .accessibilityHint(canAddName ? "Adds a new swimmer" : (nameHelper ?? "Enter a unique name"))
            }

            if let helper = nameHelper, !helper.isEmpty {
                Text(helper)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityLabel(helper)
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
    }

    private var canAddName: Bool {
        let name = newSwimmerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        return !swimmers.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
    }

    private func validateName() {
        let name = newSwimmerName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            nameHelper = nil
        } else if swimmers.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            nameHelper = "A swimmer with this name already exists."
        } else {
            nameHelper = nil
        }
    }

    // MARK: - Database helpers (SwiftData)

    @MainActor
    private func addItem() {
        let name = newSwimmerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            isNameFieldFocused = false
            return
        }
        guard !swimmers.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            nameHelper = "A swimmer with this name already exists."
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            modelContext.insert(Swimmer(name: name, laps: 0))
        }
        newSwimmerName = ""
        isNameFieldFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor
    private func confirmDelete() {
        guard let item = pendingDeletion else { return }
        lastDeleted = (name: item.name, laps: item.laps)
        withAnimation(.easeInOut(duration: 0.25)) {
            modelContext.delete(item)
        }
        pendingDeletion = nil
        showUndoBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showUndoBanner = false }
            lastDeleted = nil
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    @MainActor
    private func undoDelete() {
        guard let lastDeleted else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            modelContext.insert(Swimmer(name: lastDeleted.name, laps: lastDeleted.laps))
        }
        self.lastDeleted = nil
        withAnimation { showUndoBanner = false }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
}









// MARK: - Button style token and application

enum ButtonStyleToken {
    case borderedProminent(tint: Color?)
    case bordered(tint: Color?)
}

extension View {
    @ViewBuilder
    func apply(style token: ButtonStyleToken) -> some View {
        switch token {
        case .borderedProminent(let tint):
            if let tint {
                self.buttonStyle(.borderedProminent).tint(tint)
            } else {
                self.buttonStyle(.borderedProminent)
            }
        case .bordered(let tint):
            if let tint {
                self.buttonStyle(.bordered).tint(tint)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }

    // Auto-repeat using DragGesture with reliable delayed start/stop
    func autoRepeat(onPressBegan: @escaping () -> Void,
                    onRepeat: @escaping () -> Void,
                    interval: TimeInterval) -> some View {
        modifier(AutoRepeatModifier(onPressBegan: onPressBegan,
                                    onRepeat: onRepeat,
                                    interval: interval))
    }
}

// MARK: - Label style wrapper

struct AnyLabelStyle: LabelStyle {
    enum Kind {
        case iconOnly
        case titleAndIcon
    }

    let kind: Kind

    init(_ kind: Kind) {
        self.kind = kind
    }

    func makeBody(configuration: Configuration) -> some View {
        switch kind {
        case .iconOnly:
            configuration.icon
        case .titleAndIcon:
            HStack(spacing: 6) {
                configuration.icon
                configuration.title
            }
        }
    }
}


// MARK: - Flexible buttons row (wraps on narrow widths)

struct FlexibleButtonsRow<Content: View>: View {
    let metrics: LayoutMetrics
    @ViewBuilder let content: () -> Content

    var body: some View {
        let minButtonWidth = max(110, 120 * metrics.scale)

        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: minButtonWidth), spacing: metrics.hStackSpacing)
            ],
            spacing: metrics.hStackSpacing
        ) {
            content()
        }
    }
}


// MARK: - Auto-repeat modifier using DragGesture (2s delayed start)

struct AutoRepeatModifier: ViewModifier {
    @State private var delayTimer: Timer?
    @State private var repeatTimer: Timer?
    let onPressBegan: () -> Void
    let onRepeat: () -> Void
    let interval: TimeInterval
    private let delay: TimeInterval = 2.0

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        // Start the 2-second delay timer once on initial press
                        if delayTimer == nil && repeatTimer == nil {
                            startDelayTimer()
                        }
                    }
                    .onEnded { _ in
                        stopAllTimers()
                    }
            )
            .onDisappear {
                stopAllTimers()
            }
    }

    private func startDelayTimer() {
        stopAllTimers()
        let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            onPressBegan()
            startRepeatTimer()
        }
        delayTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func startRepeatTimer() {
        repeatTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: max(0.05, interval), repeats: true) { _ in
            onRepeat()
        }
        repeatTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAllTimers() {
        delayTimer?.invalidate()
        repeatTimer?.invalidate()
        delayTimer = nil
        repeatTimer = nil
    }
}








// A small compatibility modifier to bridge onChange API differences across iOS 16/17.
struct OnChangeCompat<Value: Equatable>: ViewModifier {
    let value: Value
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: value, action)
        } else {
            content.onChange(of: value) { _ in action() }
        }
    }
}


private struct SettingsPlaceholderView: View {
    var dismiss: () -> Void
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Settings Coming Soon")
                    .font(.title2.bold())
                Text("This is a placeholder for the Settings screen.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    LapCounterView()
        .modelContainer(for: Swimmer.self, inMemory: true)
}
