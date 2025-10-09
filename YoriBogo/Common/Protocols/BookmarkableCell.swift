//
//  BookmarkableCell.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-09.
//

import Foundation

/// 북마크 기능을 가진 Cell을 위한 Protocol
protocol BookmarkableCell: AnyObject {
    var recipeId: String? { get set }
    var onBookmarkTapped: ((String) -> Void)? { get set }
}
