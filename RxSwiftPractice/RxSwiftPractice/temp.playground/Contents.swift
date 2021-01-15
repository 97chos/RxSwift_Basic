import UIKit
import RxSwift


let numbers = Observable<Int>.create { observer in
  let start = getStartNumber()
  observer.onNext(start)
  observer.onNext(start+1)
  observer.onNext(start+2)
  observer.onCompleted()
  return Disposables.create()
}.share()

var start = 0
func getStartNumber() -> Int {
  start += 1
  return start
}

numbers
  .subscribe(onNext: {
    print("element: \($0)")
  }, onCompleted: {
    print("-------")
  }).dispose()

numbers
  .subscribe(onNext: {
    print("element: \($0)")
  }, onCompleted: {
    print("-------")
  }).dispose()

let arr = BehaviorSubject<[Int]>(value: [1,2,3,4,5])

arr
  .map{
    $0.map {
      $0 + 1
    }
  }
  .subscribe(onNext: {
    print($0)
  })

let arr2 = [1,2,3,4,5]

print(arr2.map{ $0 + 1 })
