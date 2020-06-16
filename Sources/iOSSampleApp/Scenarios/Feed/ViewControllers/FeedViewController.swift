//
//  DashboardViewController.swift
//  iOSSampleApp
//
//  Created by Igor Kulman on 03/10/2017.
//  Copyright © 2017 Igor Kulman. All rights reserved.
//

import RxCocoa
import RxSwift
import RxSwiftExt
import UIKit

protocol FeedViewControllerDelegeate: AnyObject {
    /**
     Invoked when user requests showing RSS item detail

     - Parameter item: RSS item to show detail
     */
    func userDidRequestItemDetail(item: RssItem)
    /**
     Invoked when user requests starting the setup process again
     */
    func userDidRequestSetup()
    /**
     Invoked when user resuests the About screen
     */
    func userDidRequestAbout()
}

final class FeedViewController: UIViewController, FeedStoryboardLodable, ToastCapable {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Properties

    var viewModel: FeedViewModel!
    weak var delegate: FeedViewControllerDelegeate?

    // MARK: - Fields

    private var disposeBag = DisposeBag()
    private let refreshControl: UIRefreshControl
    private let setupButton: UIBarButtonItem
    private let aboutButton: UIBarButtonItem

    required init?(coder aDecoder: NSCoder) {
        refreshControl = UIRefreshControl()
        setupButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Settings"), style: .plain, target: nil, action: nil)
        aboutButton = UIBarButtonItem(image: #imageLiteral(resourceName: "About"), style: .plain, target: nil, action: nil)
        aboutButton.accessibilityIdentifier = "about"

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBinding()
        setupData()
    }

    // MARK: - Setup

    private func setupUI() {
        title = viewModel.title
        tableView.estimatedRowHeight = 0
        tableView.refreshControl = refreshControl
        refreshControl.attributedTitle = NSAttributedString(string: L10n.pullToRefresh)

        navigationItem.leftBarButtonItem = setupButton
        navigationItem.rightBarButtonItem = aboutButton
    }

    private func setupBinding() {
        tableView.rx.modelSelected(RssItem.self).bind { [weak self] item in self?.delegate?.userDidRequestItemDetail(item: item) }.disposed(by: disposeBag)
        tableView.rx.itemSelected.bind { [weak self] indexPath in self?.tableView.deselectRow(at: indexPath, animated: true) }.disposed(by: disposeBag)

        refreshControl.rx.controlEvent(.valueChanged).bind(to: viewModel.load).disposed(by: disposeBag)

        setupButton.rx.tap.bind { [weak self] in self?.delegate?.userDidRequestSetup() }.disposed(by: disposeBag)
        aboutButton.rx.tap.bind { [weak self] in self?.delegate?.userDidRequestAbout() }.disposed(by: disposeBag)
    }

    private func setupData() {
        tableView.register(cellType: FeedCell.self)

        // announcing errors with a toast
        viewModel.onError.bind { [weak self] error in
            switch error {
            case let rssError as RssError:
                self?.showErrorToast(message: rssError.description)
            default:
                self?.showErrorToast(message: L10n.networkProblem)
            }
        }.disposed(by: disposeBag)

        // refresh is considered finished when new data arrives or when the request fails
        Observable.merge(viewModel.feed.map({ _ in Void() }), viewModel.onError.map({ _ in Void() })).bind { [weak self] in self?.refreshControl.endRefreshing() }.disposed(by: disposeBag)

        viewModel.feed
            .bind(to: tableView.rx.items(cellIdentifier: FeedCell.reuseIdentifier, cellType: FeedCell.self)) { _, element, cell in
                cell.model = element
            }
            .disposed(by: disposeBag)
    }
}
