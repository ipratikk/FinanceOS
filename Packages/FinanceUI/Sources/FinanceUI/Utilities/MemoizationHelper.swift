import SwiftUI

/// Caches a computed value keyed by an array of `AnyHashable` dependencies.
///
/// Not thread-safe — intended for use on the main thread within SwiftUI views.
/// When dependencies change the cache is invalidated and `value` is stored fresh.
public class Memoizer<T: Equatable> {
    private var cachedValue: T?
    private var cachedDependencies: [AnyHashable]?

    public init() {}

    /// Returns the cached value if `dependencies` match the last call; otherwise caches and returns `value`.
    public func memoized(_ value: T, dependencies: [AnyHashable]) -> T {
        if cachedDependencies == dependencies {
            return cachedValue ?? value
        }
        cachedValue = value
        cachedDependencies = dependencies
        return value
    }
}

/// ViewModifier that runs a computation on appear and caches it via a `Memoizer`.
///
/// Useful to prevent expensive filter/sort operations from re-running every re-render.
public struct MemoizedComputation<T: Equatable>: ViewModifier {
    let compute: () -> T
    let dependencies: [AnyHashable]
    @State private var memoizer = Memoizer<T>()

    public func body(content: Content) -> some View {
        content.onAppear {
            _ = memoizer.memoized(compute(), dependencies: dependencies)
        }
    }
}

public extension View {
    /// Attaches a `MemoizedComputation` modifier that caches `compute()` keyed by `dependencies`.
    func memoized(
        _ compute: @escaping () -> some Equatable,
        dependencies: [AnyHashable]
    ) -> some View {
        modifier(MemoizedComputation(compute: compute, dependencies: dependencies))
    }
}

// MARK: - Cached Filtering & Sorting

public extension Array {
    /// Filters using `predicate`. Currently delegates to `Array.filter` — caching is caller-managed.
    func cachedFilter(_ predicate: @escaping (Element) -> Bool) -> [Element] {
        filter(predicate)
    }

    /// Sorts using `areInIncreasingOrder`. Currently delegates to `Array.sorted` — caching is caller-managed.
    func cachedSorted(by areInIncreasingOrder: @escaping (Element, Element) -> Bool) -> [Element] {
        sorted(by: areInIncreasingOrder)
    }
}
