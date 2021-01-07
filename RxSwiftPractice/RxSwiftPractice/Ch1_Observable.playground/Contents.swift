import UIKit
import RxSwift


let one = 1
let two = 2
let three = 3

var disposeBag = DisposeBag()

// MARK: - just: 오직 하나의 요소를 포함하는 sequence를 생성
let observable1: Observable<Int> = Observable<Int>.just(one)


// MARK: - of: 주어진 값들의 타입추론을 통해 Observable sequence를 생성
// observable2 는 Observable<Int> 타입
let observable2 = Observable.of(one, two, three)


// MARK: - subscribe
let observable = Observable.of(one, two, three)

observable.subscribe({ event in
    print(event)
})
.dispose()


// MARK: - subscribe + disposeBag 추가
Observable.of("A", "B", "C")
    .subscribe{
        print($0)
    }
    .disposed(by: disposeBag)


// MARK: - create를 이용한 Observable 생성
// 특징 : disposable을 리턴
// subscribe한 observer에게 이벤트 전달
enum MyError: Error {
    case anError
}

Observable<String>.create{ (observer) -> Disposable in
    // 1
    observer.onNext("1")
    // 2
    observer.onCompleted()
    // 3
    observer.onError(MyError.anError)
    // 4
    observer.onNext("?")
    // 5
    return Disposables.create()
}
.subscribe(
    onNext: { print($0) },
    onError: { print($0) },
    onCompleted: { print("completed") },
    onDisposed: { print("disposed") })
.disposed(by: disposeBag)


// MARK: - observable factory를 이용한 Observable 생성
// 특징: deferred는 create와 달리 Observable 값을 리턴, lazy처럼 subscribe 될 때 deferred가 실행되어 리턴 값인 Observable이 출력
var flip = false

let factory: Observable<Int> = Observable.deferred{

    // 3
    flip = !flip

    if flip {
        return Observable.of(1,2,3)
    } else {
        return Observable.of(4,5,6)
    }
}

for _ in 0...3 {
    factory.subscribe(onNext: {
        print($0, terminator: "")
    })
    .disposed(by: disposeBag)
}

// MARK: - trait 사용 (Single, Completable, Maybe)
do {

    // MARK: - Single
    // success, error 이벤트만 방출, 성공 또는 실패로 확인할 수 있는 1회성 로직에 사용
    // success = .next + .completed

    // Single을 이용하여 Resource 폴더 내의 copyright.txt 파일을 읽어야 한다고 가정
    enum FileReadError: Error {
        case fileNotFound, unreadable, encodingFailed
    }

    func loadText(from name: String) -> Single<String> {

        return Single.create { observer in
            let disposable = Disposables.create()

            // 번들 내에서 파일에 대한 경로를 찾고, 없으면 옵저버에게 .Error 리턴
            guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
                observer(.error(FileReadError.fileNotFound))
                return disposable
            }

            // 해당 파일로부터 데이터를 받아오고, 읽을 수 없다면 .Error 리턴
            guard let data = FileManager.default.contents(atPath: path) else {
                observer(.error(FileReadError.unreadable))
                return disposable
            }

            // 해당 파일을 String으로 인코딩하고, 안되면 .Error 리턴
            guard let contents = String(data: data, encoding: .utf8) else {
                observer(.error(FileReadError.encodingFailed))
                return disposable
            }

            // 데이터를 성공적으로 읽어왔다면 success 리턴
            observer(.success(contents))
            return disposable
        }
    }

    // 위에서 작성한 함수를 사용하고, 리턴 값을 이용하여 결과 처리
    loadText(from: "Copyright")
        .subscribe {
            switch $0 {
            case .success(let string):
                print(string)
            case .error(let error):
                print(error)
            }
        }
        .disposed(by: disposeBag)

    // MARK: - Maybe
    // Single과 다르게 complete 되더라도 onNext 이벤트를 방출하지 않을 수 있음 (선택 사항)
    // success, .completed, .error

    // MARK: - Completable
    // .completed, .error 이벤트만을 방출
    // observable을 completable로 변경할 수 없음

}

// MARK: - Never 연산자
// never 연산자는 아무것도 출력하지 않음.
// do 연산자는 작업 중인 Observable에 영향없이 부수적인 작용을 추가할 수 있으며, onSubscribe를 통해 핸들링 할 수 있다.
// do는 그냥 뚫고 지나간다는 의미, onSubscribe 외에도 onNext, onCompleted, onError를 사용하여 핸들링 가능
let observableNever = Observable<Any>.never()

observableNever.do(
    onSubscribe: { print("subscribed") }
)
.subscribe(
    onNext: { (element) in
        print(element)
    },
    onCompleted: {
        print("completed")
    }
)
.disposed(by: disposeBag)

// MARK: - debug 연산자
// debug 연산자는 observable의 모든 이벤트를 프린트함.
// 특정 문자열을 debug 연산자에 넣어주어 프린트

observableNever
    .debug("never 확인")
    .subscribe()
    .disposed(by: disposeBag)
