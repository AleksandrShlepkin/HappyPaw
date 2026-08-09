import SwiftUI

@MainActor
struct OnboardingView: View {
    let store: OnboardingStore

    var body: some View {
        VStack(spacing: Constants.layoutSpacing) {
            HStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .foregroundStyle(Constants.skipButtonColor)
                        .frame(width: Constants.skipButtonWidth, height: Constants.skipButtonHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Constants.skipButtonCornerRadius))
                    
                    Text(Constants.skipTitle)
                        .foregroundStyle(Constants.skipButtonTextColor)
                }
            }
            OnboardingCard(
                currentPage: store.state.currentPage,
                onNext: { store.send(.nextTapped) },
                onBack: { store.send(.backTapped) }
            )
            
            HStack {
                Button(Constants.backTitle) {
                    store.send(.backTapped)
                }
                .disabled(!store.state.canGoBack)

                Spacer()
                
                Text("\(Constants.pageTitle) \(store.state.currentPage + 1) \(Constants.pageCountSeparator) \(OnboardingState.pageCount)")
                    .foregroundStyle(.secondary)

                Button(store.state.isLastPage ? Constants.startTitle : Constants.nextTitle) {
                    store.send(.nextTapped)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Constants.screenPadding)
    }

    private enum Constants {
        static let layoutSpacing: CGFloat = 24
        static let screenPadding: CGFloat = 16
        static let skipTitle = "Пропустить"
        static let skipButtonWidth: CGFloat = 130
        static let skipButtonHeight: CGFloat = 32
        static let skipButtonCornerRadius: CGFloat = 32
        static let backTitle = "Назад"
        static let pageTitle = "Страница"
        static let pageCountSeparator = "из"
        static let startTitle = "Начать"
        static let nextTitle = "Далее"
        static let skipButtonColor = Color.indigo
        static let skipButtonTextColor = Color.white
    }

    private struct OnboardingCard: View {
        private let pages = OnboardingPage.pages
        let currentPage: Int
        let onNext: () -> Void
        let onBack: () -> Void

        @State private var drag: CGSize = .zero
        @State private var isAnimating = false

        // Высота дуги
        private let arcHeight: CGFloat = Constants.arcHeight

        var body: some View {
            GeometryReader { proxy in
                cardStack(exitDistance: proxy.size.width + Constants.exitDistancePadding)
            }
            .frame(height: Constants.cardContainerHeight)
            .padding(Constants.cardContainerPadding)
        }

        private func cardStack(exitDistance: CGFloat) -> some View {
            ZStack {
                if isReversingSwipe, let previousPage {
                    // Reverse of a left swipe: the current card returns to the
                    // stack while the preceding card enters from the left.
                    SubviewCard(page: pages[currentPage])
                        .scaleEffect(Constants.fullScale - dragProgress(exitDistance: exitDistance) * Constants.stackScaleDelta)
                        .opacity(Constants.fullOpacity - dragProgress(exitDistance: exitDistance) * Constants.stackOpacityDelta)

                    SubviewCard(page: previousPage)
                        .offset(x: -exitDistance + drag.width)
                        .rotationEffect(
                            .degrees(Double((-exitDistance + drag.width) / Constants.rotationDivisor)),
                            anchor: .bottom
                        )
                } else {
                    // A forward swipe removes the top card to the left and
                    // reveals the next card from the stack beneath it.
                    if let nextPage {
                        SubviewCard(page: nextPage)
                            .scaleEffect(nextCardScale(exitDistance: exitDistance))
                            .opacity(Constants.backCardBaseOpacity + dragProgress(exitDistance: exitDistance) * Constants.stackOpacityDelta)
                    }

                    if currentPage < pages.count {
                        SubviewCard(page: pages[currentPage])
                            .offset(
                                x: drag.width,
                                y: arcOffset(exitDistance: exitDistance)
                            )
                            .rotationEffect(
                                .degrees(Double(drag.width / Constants.rotationDivisor)),
                                anchor: .bottom
                            )
                    }
                }
            }
            .gesture(dragGesture(exitDistance: exitDistance))
            .allowsHitTesting(!isAnimating)
        }

        private func dragProgress(exitDistance: CGFloat) -> CGFloat {
            min(abs(drag.width) / exitDistance, Constants.maximumDragProgress)
        }

        private var nextPage: OnboardingPage? {
            guard canSwipeForward else { return nil }
            return pages[currentPage + 1]
        }

        private var previousPage: OnboardingPage? {
            guard canSwipeBack else { return nil }
            return pages[currentPage - 1]
        }

        private var isReversingSwipe: Bool {
            drag.width > 0 && canSwipeBack
        }

        private func arcOffset(exitDistance: CGFloat) -> CGFloat {
            let progress = dragProgress(exitDistance: exitDistance)

            // Парабола: карточка поднимается и затем опускается.
            return arcHeight * Constants.parabolaMultiplier * progress * (Constants.fullProgress - progress)
        }

        private func nextCardScale(exitDistance: CGFloat) -> CGFloat {
            Constants.backCardScale + dragProgress(exitDistance: exitDistance) * Constants.stackScaleDelta
        }

        private func dragGesture(exitDistance: CGFloat) -> some Gesture {
            DragGesture()
                .onChanged { value in
                    guard !isAnimating else { return }

                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                    guard isHorizontal else {
                        drag = .zero
                        return
                    }

                    if value.translation.width < Constants.zero {
                        drag.width = canSwipeForward ? value.translation.width : Constants.zero
                    } else {
                        drag.width = canSwipeBack ? value.translation.width : Constants.zero
                    }
                }
                .onEnded { value in
                    guard !isAnimating else { return }

                    let predictedWidth = value.predictedEndTranslation.width

                    if predictedWidth < -Constants.swipeCompletionThreshold, canSwipeForward {
                        completeSwipe(targetOffset: -exitDistance, action: onNext)
                    } else if predictedWidth > Constants.swipeCompletionThreshold, canSwipeBack {
                        completeSwipe(targetOffset: exitDistance, action: onBack)
                    } else {
                        cancelSwipe()
                    }
                }
        }

        private var canSwipeForward: Bool {
            currentPage + 1 < pages.count
        }

        private var canSwipeBack: Bool {
            currentPage > 0
        }

        private func completeSwipe(
            targetOffset: CGFloat,
            action: @escaping () -> Void
        ) {
            isAnimating = true

            withAnimation(.easeIn(duration: Constants.completionAnimationDuration)) {
                drag.width = targetOffset
            } completion: {
                action()
                drag = .zero
                isAnimating = false
            }
        }

        private func cancelSwipe() {
            withAnimation(.spring(response: Constants.cancelAnimationResponse, dampingFraction: Constants.cancelAnimationDamping)) {
                drag = .zero
            }
        }

        private enum Constants {
            static let exitDistancePadding: CGFloat = 96
            static let cardContainerHeight: CGFloat = 520
            static let cardContainerPadding: CGFloat = 24
            static let arcHeight: CGFloat = 0
            static let stackScaleDelta: CGFloat = 0.1
            static let stackOpacityDelta: CGFloat = 0.3
            static let backCardScale: CGFloat = 0.9
            static let backCardBaseOpacity: CGFloat = 0.7
            static let fullScale: CGFloat = 1
            static let fullOpacity: CGFloat = 1
            static let fullProgress: CGFloat = 1
            static let maximumDragProgress: CGFloat = 1
            static let parabolaMultiplier: CGFloat = 4
            static let zero: CGFloat = 0
            static let rotationDivisor: CGFloat = 60
            static let swipeCompletionThreshold: CGFloat = 140
            static let completionAnimationDuration: CGFloat = 0.15
            static let cancelAnimationResponse: CGFloat = 0.4
            static let cancelAnimationDamping: CGFloat = 0.7
        }
    }

    private struct SubviewCard: View {
        let page: OnboardingPage

        var body: some View {
            VStack(spacing: Constants.contentSpacing) {
                Image(systemName: page.icon)
                    .font(.system(size: Constants.iconSize))

                Text(page.title)
                    .font(.largeTitle.bold())

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .opacity(Constants.descriptionOpacity)
            }
            .foregroundStyle(Constants.textColor)
            .padding(Constants.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: Constants.maximumHeight)
            .background(Constants.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(
                color: Color.gray.opacity(Constants.shadowOpacity),
                radius: Constants.shadowRadius,
                y: Constants.shadowVerticalOffset
            )
        }

        private enum Constants {
            static let contentSpacing: CGFloat = 24
            static let iconSize: CGFloat = 72
            static let contentPadding: CGFloat = 32
            static let maximumHeight: CGFloat = 520
            static let cornerRadius: CGFloat = 32
            static let shadowOpacity: CGFloat = 0.3
            static let shadowRadius: CGFloat = 24
            static let shadowVerticalOffset: CGFloat = 12
            static let descriptionOpacity: CGFloat = 0.8
            static let textColor = Color.white
            static let backgroundColor = Color.indigo
        }
    }
}

#Preview {
    OnboardingView(store: OnboardingStore())
}
