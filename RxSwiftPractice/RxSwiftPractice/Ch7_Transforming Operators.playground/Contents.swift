import UIKit
import RxSwift

let disposeBag = DisposeBag()

//MARK: - 변환 연산자 요소
do {

    //MARK: - toArray
    // Observable의 독립적 요소들을 array로 바인딩하는 연산자
    // 구성된 array를 .next 이벤트를 통해 subscriber에게 방출
    // single 패턴이므로 onNext 대신 onSuccess, onError 사용

    Observable.of("A","B","C")
        .toArray()
        .subscribe(onSuccess: {
            print($0)
        }, onError: {
            print($0)
        })
        .disposed(by: disposeBag)


    //MARK: - map
    // Observable에서 동작한다는 점만 제외하면 swift 표준 라이브러리의 Map과 동일
    // 조건식에 따라 값을 변환하여 전달
    print("====================map")

    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut

    Observable.of(123,4,56)
        .map{
            formatter.string(from: $0) ?? ""
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)

    //MARK: - enumerated
    // 인덱스 반환, map과 조합하여 방출하기
    print("====================enumerated")

    Observable.of(1,2,3,4,5,6)
        .enumerated()
        .map{ index, integer in
            index > 2 ? integer * 2 : integer
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
}

//MARK: - 내부 Observable 변환하기
do {
    //MARK: - flatMap
    // flatMap은 한 시퀀스의 element를 전달받아 이를 변형한 새로운 시퀀스를 만들고, (Element하나당 Sequence하나를 생성)
    // 만들어진 시퀀스에서 발생하는 모든 이벤트를 최종 시퀀스로 전달하는 것이다.
    print("====================flatMap")

    struct Student {
        var score: BehaviorSubject<Int>
    }

    let ryan = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 90))

    let student = PublishSubject<Student>()

    student
        .flatMap{ $0.score }         // 오리지널 시퀀스에서 새로운 시퀀스 생성,해당 value에 변동이 있으면 발생한 이벤트를 전달
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)

    student.onNext(ryan)

    ryan.score.onNext(85)
    charlotte.score.onNext(70)

    student.onNext(charlotte)

    ryan.score.onNext(95)
    charlotte.score.onNext(100)


    //MARK: - flatMapLatest
    // flatmap에서 가장 최신의 값만을 트래킹하고 싶을 때 사용
    // 가장 최근에 전달된 Observable의 Element 값만 트래킹하고, 이전의 값들은 모두 구독해지하고 무시
    // 네트워킹 조작에서 흔히 사용, 사전 검색 시 각 스펠링을 입력할 때마다 이전에 노출되던 값들은 모두 지워지고, 새로은 검색값만 노출될 때
    print("====================flatMapLatest")

    student
        .flatMapLatest { $0.score }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)

    student.onNext(ryan)
    ryan.score.onNext(85)

    student.onNext(charlotte)

    ryan.score.onNext(95)
    charlotte.score.onNext(100)

    student.onNext(ryan)
    charlotte.score.onNext(130)
}

//MARK: - 이벤트 관찰하기
do {
    print("====================ObserverEvent")

    enum MYyrror: Error {
        case anError
    }

    struct Student {
        var score: BehaviorSubject<Int>
    }

    let ryan = Student(score: BehaviorSubject(value: 80))
    let charlotte = Student(score: BehaviorSubject(value: 100))

    let student = BehaviorSubject(value: ryan)

    let studentScore = student
        .flatMapLatest{ $0.score.materialize() }

    studentScore
        .filter {
            guard $0.error == nil else {
                print($0)
                return false
            }
            return true
        }
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)

    ryan.score.onNext(85)
    ryan.score.onError(MYyrror.anError)
    ryan.score.onNext(90)

    student.onNext(charlotte)
}
