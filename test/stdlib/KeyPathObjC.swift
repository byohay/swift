// RUN: rm -rf %t && mkdir -p %t
// RUN: %target-build-swift %s -Xfrontend -enable-experimental-keypaths -o %t/a.out
// RUN: %target-run %t/a.out
// REQUIRES: executable_test
// REQUIRES: PTRSIZE=64
// REQUIRES: objc_interop

// Disabled for now
// REQUIRES: rdar://problem/31776015

import StdlibUnittest
import Foundation

struct NonObjC {
  var x: Int
  var y: Foo
}

class Foo: NSObject {
  @objc var int: Int { fatalError() }
  @objc var bar: Bar { fatalError() }
  var nonobjc: NonObjC { fatalError() }
  @objc(thisIsADifferentName) var differentName: Bar { fatalError() }

  @objc subscript(x: Int) -> Foo { return self }
  @objc subscript(x: Bar) -> Foo { return self }
}

class Bar: NSObject {
  @objc var foo: Foo { fatalError() }
}

var testKVCStrings = TestSuite("KVC strings")

testKVCStrings.test("KVC strings") {
  expectEqual((\NonObjC.x)._kvcKeyPathString, nil)
  expectEqual((\NonObjC.y)._kvcKeyPathString, nil)
  expectEqual((\Foo.int)._kvcKeyPathString, "int")
  expectEqual((\Foo.bar)._kvcKeyPathString, "bar")
  expectEqual((\Foo.bar.foo)._kvcKeyPathString, "bar.foo")
  expectEqual((\Foo.bar.foo.bar)._kvcKeyPathString, "bar.foo.bar")
  expectEqual((\Foo.nonobjc)._kvcKeyPathString, nil)
  expectEqual((\Foo.bar.foo.nonobjc.y)._kvcKeyPathString, nil)
  expectEqual((\Foo.differentName)._kvcKeyPathString, "thisIsADifferentName")
  expectEqual((\Bar.foo)._kvcKeyPathString, "foo")

  let foo_bar = \Foo.bar
  let foo_nonobjc = \Foo.nonobjc
  let bar_foo = \Bar.foo

  let nonobjc_y = \NonObjC.y

  do {
    let foo_bar_foo = foo_bar.appending(path: bar_foo)
    expectEqual(foo_bar_foo._kvcKeyPathString, "bar.foo")
    let foo_bar_foo_bar = foo_bar_foo.appending(path: foo_bar)
    expectEqual(foo_bar_foo_bar._kvcKeyPathString, "bar.foo.bar")
  }
  do {
    let bar_foo_bar = bar_foo.appending(path: foo_bar)
    expectEqual(bar_foo_bar._kvcKeyPathString, "foo.bar")
  }
  do {
    let bar_foo_nonobjc = bar_foo.appending(path: foo_nonobjc)
    expectEqual(bar_foo_nonobjc._kvcKeyPathString, nil)
  }
  do {
    let nonobjc_y_bar = nonobjc_y.appending(path: foo_bar)
    expectEqual(nonobjc_y_bar._kvcKeyPathString, nil)
  }
  do {
    let foo_nonobjc_y = foo_nonobjc.appending(path: nonobjc_y)
    expectEqual(foo_nonobjc_y._kvcKeyPathString, nil)
  }
}

runAllTests()
