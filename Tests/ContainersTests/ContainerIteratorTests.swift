//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
//
//===----------------------------------------------------------------------===//

import XCTest

#if COLLECTIONS_SINGLE_MODULE
import Collections
#else
import _CollectionsTestSupport
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

/// A noncopyable container that uses the provided `ContainerIterator`.
@available(SwiftStdlib 6.4, *)
private struct NoncopyableWrapper<Element: ~Copyable>: ~Copyable, Container {
  typealias BorrowingIterator = ContainerIterator<Self>

  let storage: RigidArray<Element>

  var count: Int { storage.count }
  var startIndex: Int { storage.startIndex }
  var endIndex: Int { storage.endIndex }

  subscript(index: Int) -> Element { borrow { storage[index] } }

  @_lifetime(borrow self)
  func nextSpan(
    after index: inout Int, maxCount: Int, limitedBy limit: Int
  ) -> Span<Element> {
    storage.nextSpan(after: &index, maxCount: maxCount, limitedBy: limit)
  }
}

@available(SwiftStdlib 6.4, *)
final class ContainerIteratorTests: CollectionTestCase {
  func test_skip_stopsAtTheEndOfTheIterator() {
    let count = 10
    let items = NoncopyableWrapper(
      storage: RigidArray(capacity: count, copying: 0 ..< count))
    for start in 0 ... count {
      for end in start ... count {
        for offset in 0 ... count + 2 {
          var it = items.makeBorrowingIterator(from: start, to: end)
          let skipped = it.skip(by: offset)
          let expected = Swift.min(offset, end - start)
          expectEqual(
            skipped, expected,
            "start: \(start), end: \(end), offset: \(offset)")
          expectEqual(
            items.currentIndex(of: &it), start + expected,
            "start: \(start), end: \(end), offset: \(offset)")

          var rest: [Int] = []
          while true {
            let span = it.nextSpan(maxCount: .max)
            if span.isEmpty { break }
            for i in span.indices { rest.append(span[i]) }
          }
          expectEqualElements(
            rest, start + expected ..< end,
            "start: \(start), end: \(end), offset: \(offset)")
        }
      }
    }
  }
}

#endif
