//
//  PartialIso.swift
//  DeeperFunc
//
//  Created by Ilya Puchka on 31/10/2017.
//  Copyright © 2017 Ilya Puchka. All rights reserved.
//

import Foundation

infix operator >>>
infix operator <<<

public struct PartialIso<A, B> {
    public let apply: (A) -> B?
    public let unapply: (B) -> A?
    
    public static func >>> <C>(lhs: PartialIso, _ rhs: PartialIso<B, C>) -> PartialIso<A, C> {
        return .init(
            apply: { lhs.apply($0).flatMap(rhs.apply) },
            unapply: { rhs.unapply($0).flatMap(lhs.unapply) }
        )
    }

    public static func <<< <C>(lhs: PartialIso<B, C>, rhs: PartialIso) -> PartialIso<C, A> {
        return lhs.inverted >>> rhs.inverted
    }

    var inverted: PartialIso<B, A> {
        return .init(
            apply: self.unapply,
            unapply: self.apply
        )
    }
    
    var someB: PartialIso<A, B?> {
        return .init(
            apply: apply,
            unapply: { $0.flatMap(self.unapply) }
        )
    }
    
    var someA: PartialIso<A?, B> {
        return .init(
            apply: { $0.flatMap(self.apply) },
            unapply: unapply
        )
    }

}

extension PartialIso where A == Void, B == Any {
    static var void: PartialIso { return PartialIso(apply: { _ in () as Any }, unapply: { _ in () }) }
}

extension PartialIso where A == Any, B == (Any, Any) {
    static var split: PartialIso { return PartialIso(apply: { $0 as? (Any, Any) }, unapply: { $0 }) }
}

extension PartialIso where A == (Any, Any), B == Any {
    static var join: PartialIso { return PartialIso(apply: { $0 }, unapply: { $0 as? (Any, Any) }) }
}

extension PartialIso where A == String, B == Int {
    static var int: PartialIso { return PartialIso(apply: Int.init, unapply: String.init) }
}

extension PartialIso where A == String, B == Double {
    static var double: PartialIso { return PartialIso(apply: Double.init, unapply: String.init) }
}

extension PartialIso where A == String, B == Bool {
    static var bool: PartialIso { return PartialIso(apply: Bool.fromString, unapply: Bool.toString) }
}

extension PartialIso where A == B {
    static var id: PartialIso { return PartialIso(apply: { $0 }, unapply: { $0 }) }
}

extension PartialIso where A == Any, B == String {
    static var string: PartialIso<Any, String> { return PartialIso(apply: String.init(describing:), unapply: { $0 }) }
}

