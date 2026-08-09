import SwiftUI

@MainActor
struct MainScreenView: View {
    @State private var store: MainScreenStore

    init() {
        _store = State(initialValue: MainScreenStore())
    }

    init(store: MainScreenStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("HappyPaw")
                .toolbar {
                    Button("Обновить", systemImage: "arrow.clockwise") {
                        store.send(.refreshTapped)
                    }
                    .disabled(store.state.isLoading)
                }
        }
        .task {
            store.send(.appeared)
        }
        .alert(
            "Не удалось загрузить карточки",
            isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { if !$0 { store.send(.errorDismissed) } }
            )
        ) {
            Button("Повторить") {
                store.send(.refreshTapped)
            }
            Button("Закрыть", role: .cancel) {
                store.send(.errorDismissed)
            }
        } message: {
            Text(store.state.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state.phase {
        case .idle, .loading:
            ProgressView("Загружаем карточки…")
        case .content:
            List(store.state.cards) { card in
                Button {
                    store.send(.cardTapped(card.id))
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                        if let subtitle = card.subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        case .empty:
            ContentUnavailableView(
                "Карточек пока нет",
                systemImage: "pawprint",
                description: Text("Добавленные администратором карточки появятся здесь.")
            )
        case .failure:
            ContentUnavailableView(
                "Не удалось загрузить карточки",
                systemImage: "exclamationmark.triangle"
            )
        }
    }
}

#Preview {
    MainScreenView()
}
