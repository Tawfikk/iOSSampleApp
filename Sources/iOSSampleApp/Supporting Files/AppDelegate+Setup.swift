//
//  AppDelegate+Setup.swift
//  iOSSampleApp
//
//  Created by Igor Kulman on 03/10/2017.
//  Copyright © 2017 Igor Kulman. All rights reserved.
//

import Foundation
import os.log
import Swinject
import SwinjectAutoregistration

extension AppDelegate {
    /**
     Set up the depedency graph in the DI container
     */
    internal func setupDependencies() {
        os_log("Registering dependencies", log: OSLog.lifeCycle, type: .debug)

        // services
        container.autoregister(SettingsService.self, initializer: UserDefaultsSettingsService.init).inObjectScope(ObjectScope.container)
        container.autoregister(DataService.self, initializer: RssDataService.init).inObjectScope(ObjectScope.container)

        // viewmodels
        container.autoregister(SourceSelectionViewModel.self, initializer: SourceSelectionViewModel.init)
        container.autoregister(CustomSourceViewModel.self, initializer: CustomSourceViewModel.init)
        container.autoregister(FeedViewModel.self, initializer: FeedViewModel.init)
        container.autoregister(LibrariesViewModel.self, initializer: LibrariesViewModel.init)
        container.autoregister(AboutViewModel.self, initializer: AboutViewModel.init)

        // view controllers
        container.registerViewController(SourceSelectionViewController.self) { r, c in
            c.viewModel = r~>
        }
        container.registerViewController(CustomSourceViewController.self) { r, c in
            c.viewModel = r~>
        }
        container.registerViewController(FeedViewController.self) { r, c in
            c.viewModel = r~>
        }
        container.registerViewController(LibrariesViewController.self) { r, c in
            c.viewModel = r~>
        }
        container.registerViewController(AboutViewController.self) { r, c in
            c.viewModel = r~>
        }

        #if DEBUG
            if ProcessInfo().arguments.contains("testMode") {
                os_log("Running in UI tests, deleting selected source to start clean", log: OSLog.lifeCycle, type: .debug)
                let settingsService = container.resolve(SettingsService.self)!
                settingsService.selectedSource = nil
            }
        #endif
    }
}
