//
//  CompositionalLayoutFactory.swift
//  YoriBogo
//
//  Created by 박성훈 on 2025-10-09.
//

import UIKit

enum CompositionalLayoutFactory {
    /// 그리드 레이아웃 생성
    /// - Parameters:
    ///   - columnsCount: 열 개수
    ///   - itemHeight: 아이템 높이
    ///   - spacing: 아이템 간격
    ///   - contentInsets: 섹션 여백
    ///   - hasHeader: 헤더 여부
    ///   - headerHeight: 헤더 높이
    /// - Returns: UICollectionViewLayout
    static func createGridLayout(
        columnsCount: Int,
        itemHeight: CGFloat,
        spacing: CGFloat = 12,
        contentInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 20, bottom: 20, trailing: 20),
        hasHeader: Bool = false,
        headerHeight: CGFloat = 44
    ) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columnsCount)),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = contentInsets

        if hasHeader {
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(headerHeight)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]
        }

        return UICollectionViewCompositionalLayout(section: section)
    }

    /// 세로 리스트 레이아웃 생성
    /// - Parameters:
    ///   - estimatedHeight: 예상 높이
    ///   - spacing: 아이템 간격
    ///   - contentInsets: 섹션 여백
    /// - Returns: UICollectionViewLayout
    static func createVerticalListLayout(
        estimatedHeight: CGFloat = 280,
        spacing: CGFloat = 16,
        contentInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
    ) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(estimatedHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(estimatedHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = contentInsets
        section.orthogonalScrollingBehavior = .none

        return UICollectionViewCompositionalLayout(section: section)
    }

    /// 섹션별로 다른 레이아웃을 적용하는 Compositional Layout 생성
    /// - Parameter sectionProvider: 섹션 인덱스에 따른 NSCollectionLayoutSection 제공 클로저
    /// - Returns: UICollectionViewLayout
    static func createCustomLayout(
        sectionProvider: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?
    ) -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }

    /// 가로 스크롤 레이아웃 생성
    /// - Parameters:
    ///   - itemWidth: 아이템 너비 (fractional)
    ///   - itemHeight: 아이템 높이
    ///   - spacing: 아이템 간격
    ///   - contentInsets: 섹션 여백
    /// - Returns: UICollectionViewLayout
    static func createHorizontalScrollLayout(
        itemWidth: CGFloat = 0.8,
        itemHeight: CGFloat = 200,
        spacing: CGFloat = 12,
        contentInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
    ) -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidth),
            heightDimension: .absolute(itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = spacing
        section.contentInsets = contentInsets

        return UICollectionViewCompositionalLayout(section: section)
    }
}
