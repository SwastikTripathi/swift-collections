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
import DequeModule
import BasicContainers
#endif
import ContainersPreview

#if compiler(>=6.4) && UnstableContainersPreview

// These go through generic functions so that they exercise the default
// implementations in `RangeReplaceableContainer`, not the concrete types' own
// methods with the same names.
@available(SwiftStdlib 6.4, *)
private func appendCopying<C: RangeReplaceableContainer<Int> & ~Copyable>(
  _ container: inout C, _ items: [Int]
) {
  container.append(copying: items)
}

@available(SwiftStdlib 6.4, *)
private func insertCopying<C: RangeReplaceableContainer<Int> & ~Copyable>(
  _ container: inout C, _ items: [Int], at index: C.Index
) -> Range<C.Index> {
  container.insert(copying: items, at: index)
}

@available(SwiftStdlib 6.4, *)
private func contents<C: Container<Int> & ~Copyable>(_ container: borrowing C) -> [Int] {
  var result: [Int] = []
  var index = container.startIndex
  while index < container.endIndex {
    result.append(container[index])
    container.formIndex(after: &index)
  }
  return result
}

@available(SwiftStdlib 6.4, *)
final class RangeReplaceableContainerCopyingTests: CollectionTestCase {
  func test_append_copying_array() {
    withEvery("count", in: 0 ..< 6) { count in
      let items = Array(0 ..< count)
      var array = UniqueArray<Int>()
      appendCopying(&array, items)
      expectEqualElements(contents(array), items)

      var deque = UniqueDeque<Int>()
      appendCopying(&deque, items)
      expectEqualElements(contents(deque), items)
    }
  }

  func test_append_copying_wrappingRigidDeque() {
    // Leave the free space split across the end of the storage.
    var deque = RigidDeque<Int>(capacity: 8)
    for i in 0 ..< 6 { deque.append(i) }
    deque.removeFirst(4)
    appendCopying(&deque, [10, 11, 12, 13])
    expectEqualElements(contents(deque), [4, 5, 10, 11, 12, 13])
  }

  func test_insert_copying_wrappingRigidDeque() {
    withEvery("count", in: 0 ..< 3) { count in
      withEvery("offset", in: 0 ... 2) { offset in
        var deque = RigidDeque<Int>(capacity: 8)
        for i in 0 ..< 6 { deque.append(i) }
        deque.removeFirst(4)

        let items = Array(10 ..< 12 + count)
        var expected = [4, 5]
        expected.insert(contentsOf: items, at: offset)

        let index = deque.startIndex + offset
        let range = insertCopying(&deque, items, at: index)
        expectEqual(range.lowerBound, index)
        expectEqual(range.upperBound, index + items.count)
        expectEqualElements(contents(deque), expected)
      }
    }
  }

  func test_insert_copying_wrappingUniqueDeque() {
    var deque = UniqueDeque<Int>(capacity: 8)
    for i in 0 ..< 6 { deque.append(i) }
    deque.removeFirst(4)
    _ = insertCopying(&deque, [10, 11, 12, 13], at: deque.endIndex)
    expectEqualElements(contents(deque), [4, 5, 10, 11, 12, 13])
  }
}

#endif
