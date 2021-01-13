import UIKit
import RxSwift

// MARK: - Buffering operators

do {
  // MARK: - replay(_:), replayAll()

  let elementsPerSecond = 1
  let maxElements = 5
  let replayedElements = 1
  let replayDelay:TimeInterval = 3

  let sourceObservable = Observable<Int>.create { observer in
    var value = 1
    }
}
