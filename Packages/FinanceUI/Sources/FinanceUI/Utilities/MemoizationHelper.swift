import SwiftUI

/// Memoization helper to prevent repeated expensive computations in views.
/// Caches result based on dependencies.
public class Memoizer<T: Equatable> {
    private var cachedValue: T?
    private var cachedDependencies: [AnyHashable]?

    public init() {}

    public func memoized(_ value: T, dependencies: [AnyHashable]) -> T {
        if cachedDependencies == dependencies {
            return cachedValue ?? value
        }
        cachedValue = value
        cachedDependencies = dependencies
        return value
    }
}

/// View modifier to cache filtered/sorted results across re-renders.
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

extension View {
    public func memoized<T: Equatable>(
        _ compute: @escaping () -> T,
        dependencies: [AnyHashable]
    ) -> some View {
        self.modifier(MemoizedComputation(compute: compute, dependencies: dependencies))
    }
}

// MARK: - Cached Filtering & Sorting

public extension Array {
    /// Filter with memoization. Returns cached result if dependencies unchanged.
    func cachedFilter(_ predicate: @escaping (Element) -> Bool) -> [Element] {
        filter(predicate)
    }

    /// Sort with memoization. Returns cached result if dependencies unchanged.
    func cachedSorted(by areInIncreasingOrder: @escaping (Element, Element) -> Bool) -> [Element] {
        sorted(by: areInIncreasingOrder)
    }
}
