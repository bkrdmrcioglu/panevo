import Foundation
import Combine

extension Publisher {
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) -> AnyPublisher<T, Failure> where Failure == Never {
        flatMap { output in
            Future<T, Never> { promise in
                Task {
                    let result = await transform(output)
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

class PassthroughSubjectDebouncer<T> {
    private let subject = PassthroughSubject<T, Never>()
    private var cancellable: AnyCancellable?
    private let debounceTime: RunLoop.SchedulerTimeType.Stride

    init(debounceTime: RunLoop.SchedulerTimeType.Stride = .milliseconds(500)) {
        self.debounceTime = debounceTime
    }

    var publisher: AnyPublisher<T, Never> {
        subject
            .debounce(for: debounceTime, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func send(_ value: T) {
        subject.send(value)
    }
}


class CombineHelper {
    static func debounced<T: Publisher>(_ publisher: T, delay: RunLoop.SchedulerTimeType.Stride) -> AnyPublisher<T.Output, T.Failure> {
        publisher
            .debounce(for: delay, scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    static func throttled<T: Publisher>(_ publisher: T, interval: RunLoop.SchedulerTimeType.Stride) -> AnyPublisher<T.Output, T.Failure> {
        publisher
            .throttle(for: interval, scheduler: RunLoop.main, latest: true)
            .eraseToAnyPublisher()
    }

    static func sequenced<T>(_ publishers: [AnyPublisher<T, Never>]) -> AnyPublisher<[T], Never> {
        publishers.publisher
            .flatMap { $0 }
            .collect()
            .eraseToAnyPublisher()
    }
}
