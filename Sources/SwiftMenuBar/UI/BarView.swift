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

struct VPNWidget: View {
    let label: String
    let showsIndicator: Bool
    let connections: [ViscosityConnection]
    let onSelect: (String) -> Void

    @State private var anchorView: NSView?

    var body: some View {
        Button {
            guard let anchorView else { return }
            VPNMenuPresenter.show(
                connections: connections,
                from: anchorView,
                onSelect: onSelect
            )
        } label: {
            HStack(spacing: 4) {
                if showsIndicator {
                    TimelineView(.animation(minimumInterval: 0.5)) { context in
                        let phase = context.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 1.0)
                        Text("🔴")
                            .font(.system(size: 10))
                            .opacity(phase < 0.5 ? 1 : 0)
                    }
                }

                Text(label)
                    .font(AppFont.primary(size: Configuration.fontSize))
                    .foregroundStyle(Theme.vpnWidget)
            }
            .barButton(border: .white, horizontal: 7, vertical: 3)
            .background(ViewAnchorReader(anchorView: $anchorView))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 4)
        .accessibilityLabel("VPN menu")
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
                // TEMP — Colombia SITAC pre-fill (remove when automated polling works)
                Button {
                    store.openSitacPrefill()
                } label: {
                    Text("Visa")
                        .font(AppFont.primary(size: Configuration.fontSize))
                        .foregroundStyle(.white)
                        .barButton(border: Theme.green, background: Theme.green.opacity(0.25), horizontal: 8, vertical: 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                .help("Open SITAC form prefilled in Chrome — solve captcha, then click Consult. Second click focuses the existing window.")

                if let vpnLabel = store.vpnSnapshot.status.label {
                    VPNWidget(
                        label: vpnLabel,
                        showsIndicator: store.vpnSnapshot.status.showsIndicator,
                        connections: store.vpnSnapshot.connections,
                        onSelect: { store.selectVPN($0) }
                    )
                }

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
