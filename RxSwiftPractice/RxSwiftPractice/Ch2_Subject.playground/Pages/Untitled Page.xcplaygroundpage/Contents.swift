import UIKit
import RxSwift
import RxCocoa

let disposeBag = DisposeBag()
// MARK: - Subjects
do {

    // MARK: - Publish Subject
    // 구독된 순간 새로운 이벤트 수신을 알리고 싶을 때 용이
    // 구독을 멈추거나, .completed, .error 이벤트를 통해 완전 종료될 때까지 지속
    let subject = PublishSubject<String>()
    subject.onNext("Is anyone listening?")

    let subscription1 = subject
        .subscribe(onNext: {
            print("1st: ",$0)
        })

    subject.onNext("1")

    let subscription2 = subject
        .subscribe(onNext: {
            print("2nd: ",$0)
        })

    subject.onNext("3")

    subscription1.dispose()             // subscribe 해제
    subject.onNext("4")

    subject.onCompleted()               // subject(Observable) 종료
    subject.onNext("5")

    subscription2.dispose() 

    subject                             // subject를 종료한 이후이므로 .completed 값만 리턴됨
        .subscribe {
            print("3rd: ",$0)
        }
        .disposed(by: disposeBag)

    subject.onNext("?")


    // MARK: - Behavior Subject
    // 초기값, 혹은 마지막 이벤트를 새로운 구독자에게 전달
    // 이 외 나머지 특징은 Publish Subject와 유사

    print("========================Behavior subject")
    enum MyError: Error {
        case anError
    }

    let subject2 = BehaviorSubject(value: "initial Value")

    subject2
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)

    subject2.onNext("X")

    subject2
        .subscribe{
            print("2nd: ",$0)
        }
        .disposed(by: disposeBag)

    subject2.onError(MyError.anError)

    subject2
        .subscribe{
            print("3rd: ",$0)
        }
        .disposed(by: disposeBag)

    // MARK: - Replay Subject
    // Subject 생성 시 선택한 특정 크기까지 방출하는 최신 요소를 일시적으로 캐시한 다음, 해당 버퍼를 새 구독자에게 방출
    // 이때, 캐시된 버퍼들은 메모리를 가지고 있으므로, 배열이나 이미지 같이 큰 메모리를 차지하는 데이터를은 메모리 부담에 유의
    // 최근 검색어 같이, 최근 값을 이용하여 보여줄 때 사용

    print("========================Replay subject")

    let subject3 = ReplaySubject<String>.create(bufferSize: 2)

    subject3.onNext("1")
    subject3.onNext("2")
    subject3.onNext("3")

    subject3
        .subscribe {
            print("1st: ",$0)
        }
        .disposed(by: disposeBag)

    subject3
        .subscribe {
            print("2nd: ",$0)
        }
        .disposed(by: disposeBag)

    subject3.onNext("4")
    subject3.onError(MyError.anError)
    subject3.dispose()

    subject3
        .subscribe {
            print("3rd: ", $0)
        }
        .disposed(by: disposeBag)

    // MARK: - Variables
    // BehaviorSubject를 래핑하고, 이들의 현재값을 vlaue 프로퍼티에 보유
    // onNext를 사용할 수 없으며, 에러가 발생하지 않을 것임을 보증하고, 할당 해제 시 자동으로 완료되므로 .error,.complete 사용 불가
    // Observable의 현재 값이 궁금할 때 사용

    print("========================Variables")

    let variable = BehaviorRelay(value: "Initail Value")

    //variable.value = "New initail value"
    variable.accept("New initail value")

    variable.asObservable()                         // asObservable을 호출하여 Observable처럼 읽힐 수 있도록 설정
        .subscribe{
            print("1st: ", $0)
        }
        .disposed(by: disposeBag)


    // variable.value = "1"
  variable.accept("1")

    variable.asObservable()
        .subscribe {
            print("2nd: ", $0)
        }
        .disposed(by: disposeBag)

    // variable.value = "2"
  variable.accept("2")
}



