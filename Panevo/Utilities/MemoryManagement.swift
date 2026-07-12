import Foundation

class WeakReference<T: AnyObject> {
    private(set) weak var value: T?

    init(_ value: T) {
        self.value = value
    }

    var isAlive: Bool {
        return value != nil
    }
}

class Cache<Key: Hashable, Value> {
    private var storage: [Key: CacheEntry<Value>] = [:]
    private let lock = NSLock()
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 300) {
        self.ttl = ttl
    }

    subscript(key: Key) -> Value? {
        get {
            lock.lock()
            defer { lock.unlock() }

            guard let entry = storage[key] else { return nil }

            if Date().timeIntervalSince(entry.timestamp) > ttl {
                storage.removeValue(forKey: key)
                return nil
            }

            return entry.value
        }
        set {
            lock.lock()
            defer { lock.unlock() }

            if let value = newValue {
                storage[key] = CacheEntry(value: value, timestamp: Date())
            } else {
                storage.removeValue(forKey: key)
            }
        }
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }

    func cleanup() {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        for (key, entry) in storage {
            if now.timeIntervalSince(entry.timestamp) > ttl {
                storage.removeValue(forKey: key)
            }
        }
    }

    private struct CacheEntry<V> {
        let value: V
        let timestamp: Date
    }
}

class ObjectPool<T> {
    private let factory: () -> T
    private let resetHandler: (T) -> Void
    private var availableObjects: [T] = []
    private var usedObjects: Set<NSObject> = []
    private let lock = NSLock()
    private let maxSize: Int

    init(factory: @escaping () -> T, resetHandler: @escaping (T) -> Void, maxSize: Int = 10) {
        self.factory = factory
        self.resetHandler = resetHandler
        self.maxSize = maxSize

        for _ in 0..<maxSize {
            availableObjects.append(factory())
        }
    }

    func acquire() -> T {
        lock.lock()
        defer { lock.unlock() }

        if let object = availableObjects.popLast() {
            return object
        }

        return factory()
    }

    func release(_ object: T) {
        lock.lock()
        defer { lock.unlock() }

        resetHandler(object)

        if availableObjects.count < maxSize {
            availableObjects.append(object)
        }
    }
}

class ResourceMonitor {
    static let shared = ResourceMonitor()

    private var timers: [String: Timer] = [:]
    private let lock = NSLock()

    private init() {}

    func startMonitoring(name: String, interval: TimeInterval = 60, handler: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            handler()
        }

        timers[name] = timer
    }

    func stopMonitoring(name: String) {
        lock.lock()
        defer { lock.unlock() }

        timers[name]?.invalidate()
        timers.removeValue(forKey: name)
    }

    func stopAllMonitoring() {
        lock.lock()
        defer { lock.unlock() }

        for timer in timers.values {
            timer.invalidate()
        }

        timers.removeAll()
    }
}
