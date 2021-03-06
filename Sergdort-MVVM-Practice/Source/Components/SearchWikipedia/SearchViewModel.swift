//
//  SearchViewModel.swift
//  Sergdort-MVVM-Practice
//
//  Created by 深見龍一 on 2020/03/19.
//

import RxSwift
import RxCocoa

class SearchViewModel {
    struct Dependency {
        var wikipediaAPI: WikipediaSearchProtocol
        var scheduler: SchedulerType

        public static var `default`: Dependency {
            Dependency(
                wikipediaAPI: WikipediaSearchRepository(urlSession: .shared),
                scheduler: ConcurrentMainScheduler.instance
            )
        }
    }

    private let dependency: Dependency
    private let disposeBag = DisposeBag()

    init(dependency: Dependency = .default) {
        self.dependency = dependency
    }
}

extension SearchViewModel {
    struct Input {
        let searchText: Observable<String>
    }

    struct Output {
        let wikipediaPages: Observable<[WikipediaPage]>
        let searchDescription: Observable<String>
        let error: Observable<Error>
        let isLoading: Observable<Bool>
    }

    func transform(input: Input) -> Output {
        let _wikipediaPages = PublishRelay<[WikipediaPage]>()
        let _searchDescription = PublishRelay<String>()
        let _isLoading = PublishRelay<Bool>()

        let filterdText = input.searchText
            .debounce(.milliseconds(300), scheduler: dependency.scheduler)
            .distinctUntilChanged()
            .share(replay: 1)

        let sequence = filterdText
            .do(onNext: { _ in
                _isLoading.accept(true)
            })
            .flatMap { [weak self] text -> Observable<Event<[WikipediaPage]>> in
                if text == "" { return Observable.from([]).materialize() }
                return (self?.dependency.wikipediaAPI.search(from: text))!
                    .asObservable()
                    .materialize()
        }
        .do(onNext: { _ in
            _isLoading.accept(false)
        })
            .share(replay: 1)

        sequence
            .elements()
            .bind(to: _wikipediaPages)
            .disposed(by: disposeBag)

        _wikipediaPages
            .withLatestFrom(filterdText) { (pages, word) -> String in
                "\(word) \(pages.count)件"
        }
        .bind(to: _searchDescription)
        .disposed(by: disposeBag)

        return Output(wikipediaPages: _wikipediaPages.asObservable(),
                      searchDescription: _searchDescription.asObservable(),
                      error: sequence.errors(),
                      isLoading: _isLoading.asObservable()
        )
    }
}
