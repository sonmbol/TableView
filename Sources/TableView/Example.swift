//
//  Example.swift
//
//
//  Created by ahmed suliman on 01/09/2024.
//

import SwiftUI

#if DEBUG
// Example view model for the main view
class ExampleViewModel: ObservableObject {
    @Published var sections: [[ViewCellModel]] = [[SwiftUITestViewModel(text: "Hello from SwiftUI"), UITableViewCellTestViewModel()]]

    func addItem() {
        sections[0].append(SwiftUITestViewModel(text: "Hello from SwiftUI"))
    }

    func removeItem(at index: Int) {
        sections[0].remove(at: index)
    }
}

// Example views and view models
struct SwiftUITestView: View, CellView {
    let viewModel: SwiftUITestViewModel

    init(viewModel: SwiftUITestViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(viewModel.text)
    }
}

class UITableViewCellTestView: UITableViewCell, TableViewCell {
    func setup(viewModel: UITableViewCellTestViewModel) {
        textLabel?.text = viewModel.text
    }
}

struct SwiftUITestViewModel: ViewCellModel {
    let text: String
    var viewType: ViewCellType { .view(SwiftUITestView.self) }
}

class UITableViewCellTestViewModel: ViewCellModel {
    let text: String

    init(text: String = "Default Text") {
        self.text = text
    }

    var viewType: ViewCellType { .cell(UITableViewCellTestView.self) }
}

// Main view
@available(iOS 14.0, *)
struct ExampleView: View {
    @StateObject var viewModel = ExampleViewModel()

    var body: some View {
        VStack {
            TableView(sections: $viewModel.sections)
                .id("TableView")
            Button("Add Item") {
                viewModel.addItem()
            }
            Button("Remove Item") {
                if !viewModel.sections[0].isEmpty {
                    viewModel.removeItem(at: 0)
                }
            }
        }
    }
}

// Preview
@available(iOS 14.0, *)
#Preview {
    ExampleView()
}

#endif
