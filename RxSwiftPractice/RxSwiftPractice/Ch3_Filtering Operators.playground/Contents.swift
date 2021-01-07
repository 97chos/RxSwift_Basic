import UIKit
import RxSwift

let disposeBag = DisposeBag()

//MARK: - Ignoring operators
do {

    //MARK: - ignoreElements
    // .next 이벤트를 무시하고, completed나 error 같은 정지 이벤트만 허용

    let strikes = PublishSubject<String>()

    strikes
        .ignoreElements()
        .subscribe({
            print("You're out", $0)
        })
        .disposed(by: disposeBag)

    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")

    strikes.onCompleted()


    //MARK: - elementAt
    // Observable에서 방출된 n번째 요소만 처리하려는 경우에 사용, 받고싶은 요소에 해당하는 index만을 방출하고 나머지는 무시
    print("====================elementAt")

    let strikes2 = PublishSubject<String>()

    strikes2
        .elementAt(2)
        .subscribe(onNext: { _ in
            print("You're Out")
        })
        .disposed(by: disposeBag)

    strikes2.onNext("1X")
    strikes2.onNext("2X")
    strikes2.onNext("3X")


    //MARK: - filter
    // ignoreElements와 elementAt은 observable의 방출 요소나 인덱스에 따라 필터링하여 방출
    // filter는 필터링 요구사항이 한 가지 이상일 때 사용 가능
    print("====================filter")

    Observable.of(1,2,3,4,5,6)
        .filter({ $0 % 2 == 0 })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

//MARK: - Skipping Operators
do {
    //MARK: - skip
    // 확실히 몇 개의 요소를 skip하고 싶을 때 사용
    // 첫 번재 요소부터 n개의 요소를 skip
    print("====================skip")


    Observable.of("A","B","C","D","E","F")
        .skip(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)


    //MARK: - skipWhile
    // 구독하는 동안 모든 요소를 필터링하는 filter와 달리, skitWhilte은 특정 요소를 skip하지 않을 때까지 skip하고 종료
    // 조건문에 true면 skip, false면 emmit, false 이후에는 skip 연산자가 종료되어 이후 조건이 true여도 더 이상 skip하지 않음
    print("====================skipWhile")

    Observable.of(2,2,3,4,4)
        .skipWhile({ $0%2 == 0 })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)


    //MARK: - skipUntil
    // 고정 필터링이 아닌 다른 observable에 기반하여 다이나믹하게 필터링할 때 사용
    // 다른 Observable에서 .next를 방출할 때까지 현재 Observable에서 방출하는 이벤트를 skip
    print("====================skipUntil")

    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()

    subject
        .skipUntil(trigger)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)

    subject.onNext("A")
    subject.onNext("B")
    subject.onNext("C")

    trigger.onNext("X")

    subject.onNext("D")
}

//MARK: - Taking Operators
do {
    // MARK: - take
    // Taking은 skipping의 반대 개념
    // 어떤 특정 요소만을 취하고 싶을 때 사용
    print("====================take")

    Observable.of(1,2,3,4,5,6)
        .take(3)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)


    // MARK: - takeWhile
    // SkipWhile 처럼 작동, false 이후에는 필터가 동작하지 않음
    // 조건문 로직에서 true에 해당하는 값만 방출
    print("====================takeWhile")

    Observable.of(2,2,3,4,4)
        .takeWhile({ $0 % 2 == 0 })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)


    // MARK: - enumerated
    // 방출된 요소의 index를 참고할 때 사용
    // 기존 swift의 enumerated 메소드와 유사하게 Observable에서 나오는 각 요소의 index와 값을 포함하는 튜플을 생성
    print("====================enumerated")

    Observable.of(2,2,4,4,6,6)
        .enumerated()
        .takeWhile({index, value in
            value % 2 == 0 && index < 3
        })
        .map{ $0.element }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)


    // MARK: - takeUntil
    // skipUntil처럼 동작
    // trigger Observable이 onNext 이벤트를 방출하기 전까지의 이벤트 값만 받음
    // RxCocoa 라이브러리를 이용하면 dispose를 trigger로 사용하여 구독을 해제할 수 있음
    print("====================takeUntil")

    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()

    subject
        .takeUntil(trigger)
        .subscribe(onNext: {
            print($0)
        })

    subject.onNext("1")
    subject.onNext("2")

    trigger.onNext("X")

    subject.onNext("3")
}

// MARK: - Distinct Operators
// 중복해서 이어지는 값을 막아주는 연산자

do {
    // MARK: - distinctUntilChanged
    // 연달아 같은 값이 이어질 때 중복된 값을 막아주는 연산자
    // 같은 값이 방출되더라도, 연속된 값이 아니라면 그대로 방출
    print("====================distinctUntilChanged")

    Observable.of("A","A","B","B","B")
        .distinctUntilChanged()
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)


    // MARK: - distinctUntilChanged(_:)
    // distinctUntilChanged는 기본적으로 구현된 로직에 따라 같음을 확인한다.
    // 그러나 해당 연산자는 커스텀한 비교 로직을 구현하고 싶을 때 사용한다.
    print("====================distinctUntilChanged(_:)")

    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut

    Observable<NSNumber>.of(10,110,20,200,210,310)
        .distinctUntilChanged({ a, b in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "),
                  let bWords = formatter.string(from: b)?.components(separatedBy: " ") else {
                return false
            }

            var containsMatch = false

            for aWord in aWords {
                for bWord in bWords {
                    if aWord == bWord {
                        containsMatch = true
                        break
                    }
                }
            }

            return containsMatch
        })
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

//MARK: - Challenge : 전화번호 만들기
// 전화번호는 0으로 시작할 수 없으며, 각각의 전화번호는 한자리 숫자여야 한다. 10개의 숫자만 받을 수 있다.


