//
//  SourceSelectionViewModel.swift
//  iOSSampleApp
//
//  Created by Igor Kulman on 03/10/2017.
//  Copyright © 2017 Igor Kulman. All rights reserved.
//

import Foundation
import os.log
import RxCocoa
import RxSwift

final class SourceSelectionViewModel {

    // MARK: - Properties

    let sources: Observable<[RssSourceViewModel]>
    let filter = BehaviorRelay<String?>(value: nil)
    let isValid: Observable<Bool>

    // MARK: - Fields

    private let allSources = BehaviorRelay<[RssSourceViewModel]>(value: [])
    private let settingsService: SettingsService
    private var disposeBag = DisposeBag()

    init(settingsService: SettingsService) {
        self.settingsService = settingsService

        os_log("Loading bundled sources", log: OSLog.data, type: .debug)

        let jsonData = Bundle.main.loadFile(filename: "sources.json")!

        let jsonDecoder = JSONDecoder()
        let all = (try! jsonDecoder.decode(Array<RssSource>.self, from: jsonData)).map({ RssSourceViewModel(source: $0) })

        sources = Observable.combineLatest(allSources.asObservable(), filter.asObservable()) { (all: [RssSourceViewModel], filter: String?) -> [RssSourceViewModel] in
            if let filter = filter, !filter.isEmpty {
                return all.filter({ $0.source.title.lowercased().contains(filter.lowercased()) })
            } else {
                return all
            }
        }

        isValid = sources.asObservable().flatMap { Observable.combineLatest($0.map { $0.isSelected.asObservable() }) }.map({ $0.filter({ $0 }).count == 1 })

        allSources.accept(all)

        // selecting again from feed
        if let selected = settingsService.selectedSource {
            if let index = allSources.value.firstIndex(where: { $0.source == selected }) { // pre-selecting the current source
                allSources.value[index].isSelected.accept(true)
            } else { // using a custom source
                let vm = RssSourceViewModel(source: selected)
                vm.isSelected.accept(true)
                allSources.accept(allSources.value.inserting(vm, at: 0))
            }
        }
    }

    // MARK: - Actions

    func toggleSource(source: RssSourceViewModel) {
        let selected = source.isSelected.value

        for s in allSources.value {
            s.isSelected.accept(false)
        }

        source.isSelected.accept(!selected)
    }

    func addNewSource(source: RssSource) {
        let vm = RssSourceViewModel(source: source)
        allSources.accept(allSources.value.inserting(vm, at: 0))
        toggleSource(source: vm)
    }

    func saveSelectedSource() -> Bool {
        guard let selected = allSources.value.first(where: { $0.isSelected.value }) else {
            os_log("Cannot save, no source selected", log: OSLog.data, type: .error)
            return false
        }

        settingsService.selectedSource = selected.source
        return true
    }
}
