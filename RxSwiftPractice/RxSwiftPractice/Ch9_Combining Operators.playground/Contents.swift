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


  // MARK: - combineLatest([], resultSelector:)
  // array 내의 최종 값들을 결합한다.

  _ = Observable.combineLatest([left, right]) { strings in
    return strings.joined(separator: " ")
  }


  // MARK: - combineLatest(,,resultSelector:)
  // sequence의 요소 타입이 모두 같을 필요는 없다.
  // 하기 예제는 유저가 셋팅을 바꿀 때마다 자동적으로 화면에 업데이트 한다.
  print("====================combineLatest(,,resultSelector)")

  let choice:Observable<DateFormatter.Style> = Observable.of(.short, .long)
  let dates = Observable.of(Date())

  let obsercvable2 = Observable.combineLatest(choice, dates, resultSelector: { (format, when) -> String in
    let formatter = DateFormatter()
    formatter.dateStyle = format
    return formatter.string(from: when)
  })

  obsercvable2.subscribe(onNext: { print($0) })


  // MARK: - Zip
  // 제공한 Observable을 구독하고, 새 값을 방출하기를 기다린다. 방출 시 새 값을 기반으로 클로저를 호출한다.
  // 둘 중 하나의 Observable이라도 완료되면 더 긴 다른 Observable이 남아있어도 zip도 종료된다. (indexed sequencing의 특징)
  print("====================zip")


  enum Weather {
    case cloudy
    case sunny
  }

  let lefts: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
  let rights = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")

  let observable4 = Observable.zip(lefts, rights, resultSelector: { weather, city in
    return "It's \(weather) in \(city)"
  })

  observable4.subscribe(onNext: {
    print($0)
  })
}

// MARK: - Triggers
// 여러 개의 Observable을 받는 경우, 다른 Observable로 부터 데이터를 받는 동안 단순 방아쇠 역할을 담당

do {
  // MARK: - withLatestFrom(_:)
  // 방아쇠 역할을 할 Observer에 관찰할 Obervable을 구독하고, Observer(Subject)에 이벤트가 발생할 때 마다 구독한 Observable의 최신값을 방출한다.
  print("====================withLatestFrom")


  let button = PublishSubject<Void>()
  let textFiled = PublishSubject<String>()

  let observable = button.withLatestFrom(textFiled)
  _ = observable
    .subscribe(onNext: { print($0) })

  textFiled.onNext("Par")
  textFiled.onNext("Pari")
  textFiled.onNext("Paris")   // 최신값
  button.onNext(())           // tap 역할
  button.onNext(())           // tap 역할


  // MARK: - sample(_:)
  // withLatestFrom과 동일하지만, 한 번만 방출한다. 즉, 여러번 이벤트를 통해 트리거를 동작해도 한 번만 호출된다.
  // withLatestFrom은 데이터 역할 Observable을 인자로 받고, sample은 trigger 역할 Observable을 인자로 받는다.
  print("====================sample")


  let trigger = PublishSubject<Void>()

  let samplgeObserverble = textFiled.sample(trigger)
  _ = samplgeObserverble.subscribe(onNext: { print($0) })

  textFiled.onNext("Par")
  textFiled.onNext("Pari")
  textFiled.onNext("Paris")   // 최신값
  trigger.onNext(())           // tap 역할
  trigger.onNext(())           // tap 역할

  _ = button.withLatestFrom(textFiled)
    .distinctUntilChanged()                 // 해당 구문을 추가하면 withLatestFrom에서도 sample과 동일하게 동작한다.
    .subscribe(onNext: { print($0) })


}

// MARK: - Switches

do {
  // MARK: - amb
  // ambiguous 즉, 모호하다는 의미로, 두 Observable 중 모두를 구독한다. 이후, 두 개중 어떤 observable이든 요소를 방출하는 것을 기다리다가, 하나가 방출을 시작하면 나머지 Observable에 대해서는 구독을 중단한다. 그리고 처음 작동한 observable에 대해서만 요소를 방출한다.
  // 처음에는 어떤 sequence에 관심이 있는지 알 수 없기 때문에, 일단 시작하는 것을 보고 결정한다.
  print("====================amb")


  let left = PublishSubject<String>()
  let right = PublishSubject<String>()

  let observable = left.amb(right)
  let disposable = observable.subscribe(onNext: {
    print($0)
  })

  left.onNext("Lisbon")
  right.onNext("1")
  left.onNext("London")
  left.onNext("Madrid")
  right.onNext("2")

  disposable.dispose()


  // MARK: - switchLatest
  // Observable로 들어온 마지막 sequence의 아이템만 구독한다
  print("====================switchLatest")

  
  let one = PublishSubject<String>()
  let two = PublishSubject<String>()
  let three = PublishSubject<String>()

  let source = PublishSubject<Observable<String>>()

  let observable2 = source.switchLatest()
  let disposable2 = observable2.subscribe(onNext: { print($0) })

  source.onNext(one)
  one.onNext("text from sequence one")
  two.onNext("text from sequence two")

  source.onNext(two)
  one.onNext("something from sequence one")
  two.onNext("sometihng from sequence two")

  source.onNext(three)
  one.onNext("no show one")
  two.onNext("no show two")
  three.onNext("I am showing")

  source.onNext(one)
  one.onNext("I show only one")

  disposable2.dispose()
}

// MARK: - sequence 내 요소들 간의 결합
do {
  // MARK: - reduce(::)
  // 제공된 초기값 (예제에서는 0)부터 시작해서 source Observable이 값을 방출할 때마다 그 값을 가공한다.
  // 예제에서는 0+1+3+5+7+9를 방출
  print("====================reduce")


  let source = Observable.of(1,3,5,7,9)

  let observable = source.reduce(0, accumulator: +)
  observable.subscribe(onNext: { print($0) })

  // 해석하면 다음과 같다.
  let observable2 = source.reduce(0, accumulator: { summary, newValue in
    return summary + newValue
  })
  observable2.subscribe(onNext: { print($0) })


  // MARK: - scan(_:accumulator:)
  // reduce처럼 동작하나, 단계적으로 값을 리턴하고, 리턴값이 observable이다.
  print("====================scan")


  let observable3 = source.scan(0, accumulator: +)
  observable3.subscribe(onNext: { print($0) })
}

// MARK: Challenges
// zip 연산자를 이용하여 scan 예제에서 현재값과 현재 총합의 값을 동시에 나타내자.
do {
  print("====================challenge1")


  let source = Observable.of(1,3,5,7,9)
  let observable = source.scan(0, accumulator: +)

  let zipper = Observable.zip(source, observable, resultSelector: {
    return "\($0) \($1)"
  })

  zipper.subscribe(onNext: { print($0) }).dispose()
}

do {
  print("====================challenge2")

  let source = Observable.of(1,3,5,7,9)
  let observable = source.scan((0,0), accumulator: { current, total in        // current = 튜플
    return (total, current.1 + total)
  })

  observable.subscribe(onNext: { tuple in
    print("\(tuple.0) \(tuple.1)")
  })

}
