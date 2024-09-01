//
//  TableView.swift
//
//
//  Created by ahmed suliman on 01/09/2024.
//

import SwiftUI
import Combine
import UIKit

// MARK: - TableView Layout Configuration
public struct TableViewLayout {
    public var showsIndicators: Bool = true
    public var alwaysBounces: Bool = false
    public var separatorStyle: UITableViewCell.SeparatorStyle = .none
}

// MARK: - Cell View Protocol
public protocol CellView: View {
    associatedtype ViewModel: ViewCellModel
    init(viewModel: ViewModel)
}

// MARK: - Cell View Helper Extension
private extension CellView {
    init(wrappedViewModel: ViewCellModel) {
        guard let viewModel = wrappedViewModel as? Self.ViewModel else {
            fatalError("Invalid ViewModel type")
        }
        self.init(viewModel: viewModel)
    }
}

// MARK: - Table View Cell Protocol
public protocol TableViewCell: UITableViewCell {
    associatedtype ViewModel: ViewCellModel
    static var bundle: Bundle? { get }
    func setup(viewModel: ViewModel)
}

extension TableViewCell {
    public static var bundle: Bundle? { nil }
}

// MARK: - Table View Cell Helper Extension
private extension TableViewCell {
    static var IsNib: Bool { bundle != nil }
    static var typeName: String { String(describing: Self.self) }

    func setup(wrappedViewModel: ViewCellModel) {
        guard let viewModel = wrappedViewModel as? Self.ViewModel else {
            fatalError("Invalid ViewModel type")
        }
        setup(viewModel: viewModel)
    }
}


// MARK: - View Cell Model Protocol
public protocol ViewCellModel {
    var viewType: ViewCellType { get }
}

// MARK: - View Cell Type Enumeration
public enum ViewCellType {
    case view(any CellView.Type)
    case cell(any TableViewCell.Type)
}

// MARK: - Static Table View Cell
final class StaticTableViewCell: UITableViewCell {
    /// The primary key for the cell.
    var identifier: Int?
}

// MARK: - Table View Wrapper
public struct TableView: UIViewControllerRepresentable {
    @Binding var viewModel: [[ViewCellModel]]
    var layout: TableViewLayout = .init()

    public func makeUIViewController(context: Context) -> UITableViewController {
        let controller = UITableViewController()
        controller.tableView.dataSource = context.coordinator
        controller.tableView.alwaysBounceVertical = layout.alwaysBounces
        controller.tableView.showsVerticalScrollIndicator = layout.showsIndicators
        controller.tableView.register(StaticTableViewCell.self, forCellReuseIdentifier: "cell")
        controller.tableView.separatorStyle = layout.separatorStyle
        return controller
    }

    public func updateUIViewController(_ uiViewController: UITableViewController, context: Context) {
        context.coordinator.sections = viewModel
        uiViewController.tableView.reloadData()
    }

    public func makeCoordinator() -> TableCoordinator {
        TableCoordinator(sections: viewModel)
    }

    // MARK: - Table Coordinator
    public class TableCoordinator: NSObject, UITableViewDataSource {
        var sections: [[ViewCellModel]]
        var registeredCells: [String] = []

        init(sections: [[ViewCellModel]]) {
            self.sections = sections
        }

        public func numberOfSections(in tableView: UITableView) -> Int {
            sections.count
        }

        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            sections[section].count
        }

        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cellModel = sections[indexPath.section][indexPath.row]
            switch cellModel.viewType {
            case .view(let cellView):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? StaticTableViewCell else {
                    return UITableViewCell()
                }
                let rootView = cellView.init(wrappedViewModel: cellModel)
                let controller = UIHostingController(rootView: AnyView(rootView))
                controller.view.frame = cell.contentView.bounds
                controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(controller.view)
                return cell

            case .cell(let uiTableViewCell):
                if !registeredCells.contains(uiTableViewCell.typeName) {
                    if uiTableViewCell.IsNib {
                        tableView.register(
                            UINib(nibName: uiTableViewCell.typeName, bundle: uiTableViewCell.bundle),
                            forCellReuseIdentifier: uiTableViewCell.typeName
                        )
                    } else {
                        tableView.register(uiTableViewCell, forCellReuseIdentifier: uiTableViewCell.typeName)
                    }
                    registeredCells.append(uiTableViewCell.typeName)
                }

                guard let cell = tableView.dequeueReusableCell(withIdentifier: uiTableViewCell.typeName) as? (any TableViewCell) else {
                    return UITableViewCell()
                }
                cell.setup(wrappedViewModel: cellModel)
                return cell
            }
        }
    }
}
