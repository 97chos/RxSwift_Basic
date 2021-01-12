import UIKit
import RxSwift

let disposeBag = DisposeBag()

// MARK: - sequence 앞에 붙이기
do {
  // MARK: - startWith
  // 기존 Observable 요소의 타입과 맞는 sequence를 생성하고, 이를 기존의 sequence와 이어 붙여 초기값으로 전달한다.
  // 현재 위치나 네트워크 연결 상태와 같이 현재 상태가 필요한 상황에 유용

  let numbers = Observable.of(2,3,4)

  let observable = numbers.startWith(0,1)
  observable
    .subscribe(onNext: {
      print($0)
    })

  // MARK: - concat(_:)
  // 단일 sequence를 인자로 받는 startWith와는 달리 두 개의 sequence를 묶을 수 있다
  print("====================concat")

  let first = Observable.of(1,2,3)
  let second = Observable.of(4,5,6)

  let observerble2 = Observable.concat([first, second])
  // first.concat(second).subscribe(..) 와 동일하게 적용한다.

  observerble2.subscribe(onNext: {
    print($0)
  })


  // MARK: - concatMap(_:)
  // 각각의 sequence가 다음 sequence가 구독되기 전 붙어있다는 것을 보증한다.
  // 아래와 같은 케이스는 특정 국가의 전체 sequence를 출력한 후 다음 국가를 확인한다.
  print("====================concatMap")

  let sequences = ["Germany": Observable.of("berlin","Münich","Frankfurt"),
                  "Spain": Observable.of("Madrid","Barcelona","Valencia")]

  let observable3 = Observable.of("Germany","Spain")
    .concatMap({
      sequences[$0] ?? .empty()         // $0은 각각 Germany와 Spain
    })

  _ = observable3.subscribe(onNext: {
    print($0)
  })

}


// MARK: - 합치기
do {
  // MARK: - merge()
  // Observable들을 감싸안아 해당 Observable에 전달되는 이벤트들을 공통으로 처리해줄 수 있다.
  // merge()는 observable 요소를 갖고 방출하는 source observable을 취하며, 이는 merge에 많은 양의 sequence를 보낼 수 있다.
  // merge는 source sequence와 모든 내부 sequence들이 완료되었을 때 종료한다.
  // 만약 sequence에서 error를 방출할 경우, merge는 즉시 종료된다.
  print("====================Merge")

  let left = PublishSubject<String>()
  let right = PublishSubject<String>()

  // subeject를 Observable로 변경 후 이 Observable들을 타입으로 갖는 observable 생성
  let source = Observable.of(left.asObservable(), right.asObservable())

  let observable = source.merge()
  let disposble = observable.subscribe(onNext: { print($0) })

  var leftValues = ["Berlin","Münich","Frankfurt"]
  var rightValues = ["Madrid","Barcelona","Valencia"]

  repeat {
    if arc4random_uniform(2) == 0 {
      if !leftValues.isEmpty {
        left.onNext("Left: " + leftValues.removeFirst())
      }
    } else if !rightValues.isEmpty {
      right.onNext("Right: " + rightValues.removeFirst())
    }
  } while !leftValues.isEmpty || !rightValues.isEmpty

  disposble.dispose()

  // 번외: merge(maxCount:)
  // 합칠 수 있는 sequence의 수를 제한하기 위해서 merge(maxConcurrent:)를 사용할 수 있다.
  // maxConcurrent 수에 도달할 때까지 변동은 계속해서 일어난다.
  // limit에 도달한 이후에 들어오는 observable을 대기열에 넣는다. 그리고 현재 sequence 중 하나가 완료되자마자 구독을 시작한다.
  // 네트워크 요청이 많아질 때 리소스를 제한하거나 연결 수를 제한하기 위해 해당 메소드를 쓸 수 있다.
}

// MARK: - 요소 결합하기
do {
  // MARK: - combineLatest(::resultSecletor:)
  // 메소드 내부에 묶인 sequence들은 값을 방출할 때마다 메소드에서 제공한 클로저를 호출하며, 각각 내부 sequence들의 최종 값을 받는다.
  // 여러 TextField를 한 번에 관찰하고 값을 결합하거나 여러 소스들의 상태를 볼 때 사용한다.
  // 일반적으로 튜플에 결합한 다음 체인 아래로 전달할 때 사용한다.
  print("====================combineLatest(resultSelector)")

  let left = PublishSubject<String>()
  let right = PublishSubject<String>()

  let observable = Observable.combineLatest(left, right, resultSelector: { latestLeft, latestRight in
    return "\(latestLeft) \(latestRight)"
  })

  let disposable = observable.subscribe(onNext: { print($0) })

  print("> Sending a value to left")
  left.onNext("Hello,")
  print("> Sending a value to right")
  right.onNext("world")
  print("> Sending a another value to left")
  right.onNext("RxSwift")
  print("> Sending a another value to left")
  left.onNext("Have a good day")

  disposable.dispose()



}
