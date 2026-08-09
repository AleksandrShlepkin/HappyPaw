import SwiftUI

@MainActor
struct MainAdministratorScreenView: View {
    let store: MainAdministratorScreenStore
    @Environment(\.openURL) private var openURL

    init(store: MainAdministratorScreenStore) {
        self.store = store
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                accountSection
                documentSection(store: $store)
            }
            .navigationTitle(Constants.navigationTitle)
            .overlay {
                if store.state.isLoading {
                    ProgressView(loadingTitle)
                        .padding(Constants.loadingPadding)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.loadingCornerRadius))
                }
            }
        }
        .task { store.send(.appeared) }
        .alert(
            Constants.errorTitle,
            isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { if !$0 { store.send(.errorDismissed) } }
            )
        ) {
            Button(Constants.confirmationTitle) { store.send(.errorDismissed) }
        } message: {
            Text(store.state.errorMessage ?? "")
        }
        .onChange(of: store.state.documentURL) { _, url in
            guard let url else { return }
            openURL(url)
            store.send(.documentURLOpened)
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        Section(Constants.googleSectionTitle) {
            if store.state.isAuthorized {
                LabeledContent(Constants.accountTitle) {
                    VStack(alignment: .trailing) {
                        if let name = store.state.accountName {
                            Text(name)
                        }
                        Text(store.state.accountEmail ?? "")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Button(Constants.signOutTitle, role: .destructive) {
                    store.send(.signOutTapped)
                }
                .disabled(store.state.isLoading)
            } else {
                Text(Constants.signInDescription)
                    .foregroundStyle(.secondary)
                Button(Constants.signInTitle) {
                    store.send(.signInTapped)
                }
                .disabled(store.state.isLoading)
            }
        }
    }

    private func documentSection(store: Bindable<MainAdministratorScreenStore>) -> some View {
        Section(Constants.newDocumentSectionTitle) {
            TextField(Constants.documentTitlePlaceholder, text: Binding(
                get: { store.wrappedValue.state.documentTitle },
                set: { store.wrappedValue.send(.documentTitleChanged($0)) }
            ))
            TextEditor(text: Binding(
                get: { store.wrappedValue.state.documentContent },
                set: { store.wrappedValue.send(.documentContentChanged($0)) }
            ))
            .frame(minHeight: Constants.documentEditorMinimumHeight)

            Button(Constants.createDocumentTitle) {
                store.wrappedValue.send(.createDocumentTapped)
            }
            .disabled(!store.wrappedValue.state.canCreateDocument || store.wrappedValue.state.isLoading)
        }
    }

    private var loadingTitle: String {
        switch store.state.phase {
        case .restoringSession: Constants.restoringSessionTitle
        case .authorizing: Constants.authorizingTitle
        case .signingOut: Constants.signingOutTitle
        case .creatingDocument: Constants.creatingDocumentTitle
        case .idle: Constants.loadingTitle
        }
    }

    private enum Constants {
        static let navigationTitle = "Администрирование"
        static let loadingCornerRadius: CGFloat = 12
        static let loadingPadding: CGFloat = 16
        static let errorTitle = "Не удалось выполнить действие"
        static let confirmationTitle = "OK"
        static let googleSectionTitle = "Google"
        static let accountTitle = "Аккаунт"
        static let signOutTitle = "Выйти из Google"
        static let signInDescription = "Войдите в Google, чтобы создавать документы для питомцев."
        static let signInTitle = "Войти через Google"
        static let newDocumentSectionTitle = "Новый Google-документ"
        static let documentTitlePlaceholder = "Название"
        static let documentEditorMinimumHeight: CGFloat = 140
        static let createDocumentTitle = "Создать документ"
        static let restoringSessionTitle = "Восстанавливаем сессию…"
        static let authorizingTitle = "Открываем Google…"
        static let signingOutTitle = "Выходим…"
        static let creatingDocumentTitle = "Создаём документ…"
        static let loadingTitle = "Загрузка…"
    }
}

#Preview {
    MainAdministratorScreenView(store: MainAdministratorScreenStore())
}
