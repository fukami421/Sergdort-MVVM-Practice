//
//  UserSearchCoordinator.swift
//  Sergdort-MVVM-Practice
//
//  Created by 深見龍一 on 2020/04/09.
//

import UIKit

final class UserSearchCoordinator: NavigationCoordinator {
    let navigationController: UINavigationController

    init(presenter: UINavigationController) {
        self.navigationController = presenter
    }

    func start() {
        let viewController: UserSearchViewController = .init()
        navigationController.viewControllers = [viewController]
        navigationController.tabBarItem = .init(tabBarSystemItem: .favorites, tag: 0)
    }
}