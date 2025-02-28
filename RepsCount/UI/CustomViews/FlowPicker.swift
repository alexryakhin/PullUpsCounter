//
//  FlowPicker.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 1/26/25.
//

import Flow
import SwiftUI

protocol Selectable: Hashable {
    var name: LocalizedStringKey { get }
}

extension String: Selectable {
    var name: LocalizedStringKey { LocalizedStringKey(self) }
}

struct FlowPickerView<SelectionItem: Selectable>: View {

    @Binding private var selection: SelectionItem?
    private let items: [SelectionItem]

    init(
        selection: Binding<SelectionItem?>,
        items: [SelectionItem]
    ) {
        self._selection = selection
        self.items = items
    }

    var body: some View {
        HFlow {
            ForEach(items, id: \.self) { item in
                capsuleView(for: item)
            }
        }
    }

    @ViewBuilder
    func capsuleView(for item: SelectionItem) -> some View {
        if selection == item {
            Button {
                selection = nil
                HapticManager.shared.triggerSelection()
            } label: {
                Text(item.name)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
        } else {
            Button {
                selection = item
                HapticManager.shared.triggerSelection()
            } label: {
                Text(item.name)
            }
            .buttonStyle(.bordered)
            .clipShape(Capsule())
        }
    }
}

struct FlowPicker<SelectionItem: Selectable>: View {

    @Binding private var selection: SelectionItem?
    @Binding private var error: LocalizedStringKey?
    private let items: [SelectionItem]
    private let header: LocalizedStringKey
    private let caption: LocalizedStringKey?

    init(
        selection: Binding<SelectionItem?>,
        error: Binding<LocalizedStringKey?> = .constant(nil),
        items: [SelectionItem],
        header: LocalizedStringKey,
        caption: LocalizedStringKey? = nil
    ) {
        self._selection = selection
        self._error = error
        self.items = items
        self.header = header
        self.caption = caption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(.subheadline)
                .padding(.horizontal, 16)

            FlowPickerView(selection: $selection, items: items)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clippedWithBackground()
                .overlay {
                    var color: Color {
                        if error != nil {
                            return .red
                        } else {
                            return .clear
                        }
                    }
                    color.clipShape(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: .init(lineWidth: 1))
                    )
                    .allowsHitTesting(false)
                }
                .onChange(of: selection) { _ in
                    if error != nil {
                        error = nil
                    }
                }
            Group {
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else if let caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
