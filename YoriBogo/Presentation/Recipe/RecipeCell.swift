//
//  RecipeCell.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-14.
//

import UIKit
import SnapKit
import Kingfisher

final class RecipeCell: UICollectionViewCell, ReusableView, BookmarkableCell {

    // MARK: - Properties
    var recipeId: String?
    var onBookmarkTapped: ((String) -> Void)?

    // MARK: - UI Components
    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .systemGray6
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        return iv
    }()

    private let recipeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.numberOfLines = 1
        return label
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray600
        label.numberOfLines = 1
        return label
    }()

    private lazy var tagsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .gray500
        label.numberOfLines = 1
        return label
    }()

    private let bookmarkButton = BookmarkButton(radius: 20)

    private let versionBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .brandOrange600
        label.backgroundColor = .brandOrange50
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipeId = nil
        onBookmarkTapped = nil
        recipeImageView.image = nil
        recipeTitleLabel.text = nil
        categoryLabel.text = nil
        tagsLabel.text = nil
        bookmarkButton.isHidden = true
        versionBadge.isHidden = true
    }

    @objc private func bookmarkButtonTapped() {
        guard let recipeId = recipeId else { return }
        onBookmarkTapped?(recipeId)
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(cardContainerView)

        [recipeImageView, recipeTitleLabel, categoryLabel, tagsLabel, bookmarkButton, versionBadge].forEach {
            cardContainerView.addSubview($0)
        }

        cardContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(120)
        }

        recipeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(88)
        }

        recipeTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalTo(recipeImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(60)
        }

        categoryLabel.snp.makeConstraints {
            $0.top.equalTo(recipeTitleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(recipeTitleLabel)
            $0.trailing.equalTo(recipeTitleLabel)
        }

        tagsLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(6)
            $0.leading.equalTo(recipeTitleLabel)
            $0.trailing.equalTo(recipeTitleLabel)
        }

        bookmarkButton.snp.makeConstraints {
            $0.top.equalTo(recipeTitleLabel)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(40)
        }

        versionBadge.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(40)
            $0.height.equalTo(24)
        }
    }

    // MARK: - Configuration
    func configure(with recipe: Recipe, showBookmark: Bool) {
        recipeId = recipe.id
        recipeTitleLabel.text = recipe.title

        // 이미지 로드
        let imageURL = recipe.images.first(where: { $0.isThumbnail })?.value
        recipeImageView.setImageWithKF(urlString: imageURL, placeholder: UIImage(systemName: "photo"))

        // 카테고리 설정
        if let category = recipe.category {
            categoryLabel.text = category.displayName
        } else {
            categoryLabel.text = ""
        }

        // 태그 설정
        var tags: [String] = []
        if let method = recipe.method {
            tags.append("#\(method.displayName)")
        }
        // recipe.tags에서 최대 2개까지 추가
        tags.append(contentsOf: recipe.tags.prefix(2).map { "#\($0)" })
        tagsLabel.text = tags.joined(separator: " ")

        // 북마크 또는 버전 표시
        if showBookmark {
            bookmarkButton.isHidden = false
            bookmarkButton.isSelected = recipe.isBookmarked
            versionBadge.isHidden = true
        } else {
            bookmarkButton.isHidden = true
            versionBadge.isHidden = false
            versionBadge.text = "v\(recipe.version)"
        }
    }
}
