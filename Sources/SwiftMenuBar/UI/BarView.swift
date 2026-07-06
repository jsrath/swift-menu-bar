import SwiftUI

private struct BarButtonStyle: ViewModifier {
    let borderColor: Color
    let backgroundColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: Theme.buttonRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius)
                    .stroke(borderColor, lineWidth: Theme.buttonBorderWidth)
            )
    }
}

private extension View {
    func barButton(
        border: Color,
        background: Color = .clear,
        horizontal: CGFloat,
        vertical: CGFloat
    ) -> some View {
        modifier(BarButtonStyle(
            borderColor: border,
            backgroundColor: background,
            horizontalPadding: horizontal,
            verticalPadding: vertical
        ))
    }
}

struct SimpleSpaceButton: View {
    let space: YabaiSpace
    let action: () -> Void

    private var borderColor: Color {
        space.hasFocus || space.isVisible ? Theme.green : .white
    }

    private var backgroundColor: Color {
        if space.hasFocus { return Theme.green }
        if space.isNativeFullscreen { return Theme.foreground }
        return .clear
    }

    private var labelColor: Color {
        if space.hasFocus { return .black }
        if space.isVisible { return Theme.green }
        return .white
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(space.trimmedLabel)
                if !space.windows.isEmpty {
                    Text(String(repeating: "●", count: space.windows.count))
                        .padding(.leading, 5)
                }
            }
            .font(AppFont.primary(size: Configuration.fontSize))
            .foregroundStyle(labelColor)
            .barButton(border: borderColor, background: backgroundColor, horizontal: 10, vertical: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 5)
    }
}

struct BarWidget: View {
    let text: String
    var textColor: Color = .white
    var onTap: (() -> Void)?

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    label.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
        .padding(.leading, 4)
    }

    private var label: some View {
        Text(text)
            .font(AppFont.primary(size: Configuration.fontSize))
            .foregroundStyle(textColor)
            .barButton(border: .white, horizontal: 7, vertical: 3)
    }
}

struct BarView: View {
    @Bindable var store: BarStore

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(store.spaces) { space in
                    SimpleSpaceButton(space: space) {
                        store.selectSpace(space)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                if !store.sheetText.isEmpty {
                    BarWidget(text: store.sheetText, textColor: Theme.fireWidget) {
                        Task { await store.refreshSheet() }
                    }
                }

                if let battery = store.battery {
                    BarWidget(text: "\(battery.percentage)%")
                }

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    BarWidget(text: DateTimeFormat.string(from: context.date)) {
                        store.openCalendar()
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Configuration.barHeight, alignment: .center)
        .frame(maxWidth: .infinity, maxHeight: Configuration.barHeight)
        .background(Theme.background.opacity(Theme.barOpacity))
        .ignoresSafeArea()
        .clipped()
    }
}
