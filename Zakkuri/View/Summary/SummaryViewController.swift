//
//  SummaryViewController.swift
//  Zakkuri
//
//  Created by mironal on 2019/09/13.
//  Copyright © 2019 mironal. All rights reserved.
//

import FloatingPanel
import RxCocoa
import RxSwift
import UIKit

class SummaryViewController: UITableViewController {
    private let disposeBag = DisposeBag()
    public var viewModel = SummaryViewModel()
    @IBOutlet var addButton: UIBarButtonItem!

    private let deleteItemRelay = PublishRelay<IndexPath>()

    override func viewDidLoad() {
        super.viewDidLoad()

        let outputs = viewModel.bind(.init(
            tapAdd: addButton.rx.tap.asObservable(),
            selectItem: tableView.rx.itemSelected.asObservable().do(afterNext: { [weak self] in self?.tableView.deselectRow(at: $0, animated: true) }),
            deleteItem: deleteItemRelay.asObservable()
        ))

        tableView.dataSource = nil

        outputs.habits.bind(to: tableView.rx.items(cellIdentifier: "SummaryCell", cellType: SummaryCell.self)) { _, summary, cell in

            cell.state = SummaryCellState(summary: summary)

        }.disposed(by: disposeBag)

        outputs.showRecordView
            .asSignal(onErrorSignalWith: .never())
            .emit(onNext: {
                guard let vc = UIStoryboard(name: "RecordViewController", bundle: .main).instantiateViewController(withClass: RecordViewController.self) else { return }
                vc.viewModel = $0

                let fpc = FloatingPanelController(delegate: vc)
                fpc.surfaceView.shadowHidden = false
                fpc.surfaceView.width = self.view.width
                (fpc.surfaceView as UIView).cornerRadius = 9
                (fpc.surfaceView as UIView).borderWidth = 1.0 / self.traitCollection.displayScale
                (fpc.surfaceView as UIView).borderColor = UIColor.black.withAlphaComponent(0.2)
                fpc.backdropView.alpha = 1
                fpc.isRemovalInteractionEnabled = true
                fpc.set(contentViewController: vc)
                self.present(fpc, animated: true)

            }).disposed(by: disposeBag)

        outputs.showGoalForm.asSignal(onErrorSignalWith: .never())
            .emit(onNext: { [weak self] in
                guard let vc = UIStoryboard(name: "HabitFormViewController", bundle: .main).instantiateViewController(withClass: HabitFormViewController.self) else { return }

                vc.viewModel = $0

                let nav = UINavigationController(rootViewController: vc)
                self?.present(nav, animated: true)
            }).disposed(by: disposeBag)
    }

    override func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, success in
            guard let self = self else { return }

            UIAlertController.confirmDelete()(self).subscribe(onNext: {
                switch $0 {
                case .cancel:
                    success(false)
                case .delete:
                    self.deleteItemRelay.accept(indexPath)
                    success(true)
                }
            }).disposed(by: self.disposeBag)
        }

        delete.backgroundColor = Theme.defailt.accentColor

        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
