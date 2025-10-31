//
//  TimerAddViewModel.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/29/25.
//

import Foundation
import RxSwift
import RxCocoa

final class TimerAddViewModel: ViewModelType {
    struct Input {
        let viewDidLoad: Observable<Void>
        let timerName: Observable<String>
        let hours: Observable<Int>
        let minutes: Observable<Int>
        let seconds: Observable<Int>
        let applyButtonTap: Observable<Void>
        let closeButtonTap: Observable<Void>
    }

    struct Output {
        let isApplyButtonEnabled: Driver<Bool>
        let dismiss: Driver<Void>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        // 시간 입력 값들
        let hoursValue = input.hours.startWith(0)
        let minutesValue = input.minutes.startWith(0)
        let secondsValue = input.seconds.startWith(0)

        // 총 시간(초) 계산
        let totalSeconds = Observable.combineLatest(hoursValue, minutesValue, secondsValue)
            .map { hours, minutes, seconds in
                return hours * 3600 + minutes * 60 + seconds
            }

        // 적용 버튼 활성화 조건: 이름이 비어있지 않고, 총 시간이 0보다 큼
        let isApplyButtonEnabled = Observable.combineLatest(
            input.timerName,
            totalSeconds
        )
        .map { name, total in
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && total > 0
        }
        .asDriver(onErrorJustReturn: false)

        // 적용 버튼 탭 시 처리
        let applyDismiss = input.applyButtonTap
            .withLatestFrom(Observable.combineLatest(
                input.timerName,
                hoursValue,
                minutesValue,
                secondsValue
            ))
            .do(onNext: { name, hours, minutes, seconds in
                let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
                TimerManager.shared.createTimer(title: name, duration: duration)
            })
            .map { _ in () }

        // 닫기 버튼 또는 적용 후 dismiss
        let dismiss = Observable.merge(
            input.closeButtonTap,
            applyDismiss
        )
        .asDriver(onErrorJustReturn: ())

        return Output(
            isApplyButtonEnabled: isApplyButtonEnabled,
            dismiss: dismiss
        )
    }
}
