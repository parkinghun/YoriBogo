//
//  DateFormatter.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import Foundation

extension DateFormatter {
    /// 유통기한 표시용: "2025. 10. 07."
     static let expirationDate: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy. MM. dd."
         formatter.locale = Locale(identifier: "ko_KR")
         return formatter
     }()

     /// 상세 카드 유통기한 표시용 (같은 연도): "10월10일"
     static let expirationDetailSameYear: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "M월d일"
         formatter.locale = Locale(identifier: "ko_KR")
         return formatter
     }()

     /// 상세 카드 유통기한 표시용 (다른 연도): "2026년1월2일"
     static let expirationDetailDifferentYear: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy년M월d일"
         formatter.locale = Locale(identifier: "ko_KR")
         return formatter
     }()
     
     /// 날짜만 표시: "2025-10-07"
     static let isoDate: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "yyyy-MM-dd"
         formatter.locale = Locale(identifier: "en_US_POSIX")
         return formatter
     }()
     
     /// 전체 날짜시간: "2025년 10월 7일 오후 3:30"
     static let fullDateTime: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateStyle = .long
         formatter.timeStyle = .short
         formatter.locale = Locale(identifier: "ko_KR")
         return formatter
     }()
     
     /// 시간만: "15:30"
     static let timeOnly: DateFormatter = {
         let formatter = DateFormatter()
         formatter.dateFormat = "HH:mm"
         formatter.locale = Locale(identifier: "ko_KR")
         return formatter
     }()
}
