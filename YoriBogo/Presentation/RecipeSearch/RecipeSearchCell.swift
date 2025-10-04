//
//  RecipeSearchCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import SnapKit

final class RecipeSearchCell: UITableViewCell, ReusableView {

    // MARK: - UI Components
    private let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 12
        return iv
    }()

    private let recipeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()

    private let matchBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemOrange
        label.textAlignment = .center
        return label
    }()

    private lazy var tagStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .leading
        return stack
    }()

    private let bookmarkButton = BookmarkButton()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white

        [recipeImageView, recipeTitleLabel, matchBadgeLabel, tagStackView, bookmarkButton].forEach {
            contentView.addSubview($0)
        }

        recipeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(100)
        }

        bookmarkButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(recipeImageView)
            $0.size.equalTo(40)
        }

        recipeTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalTo(recipeImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(bookmarkButton.snp.leading).offset(-8)
        }

        matchBadgeLabel.snp.makeConstraints {
            $0.top.equalTo(recipeTitleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(recipeImageView.snp.trailing).offset(12)
        }

        tagStackView.snp.makeConstraints {
            $0.top.equalTo(matchBadgeLabel.snp.bottom).offset(8)
            $0.leading.equalTo(recipeImageView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(bookmarkButton.snp.leading).offset(-8)
            $0.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    // MARK: - Configuration
    func configure(with recipe: Recipe, matchRate: Double) {
        recipeTitleLabel.text = recipe.title

        // 이미지 로드
        let imageURL = recipe.images.first(where: { $0.isThumbnail })?.value
        recipeImageView.setImageWithKF(
            urlString: imageURL,
            placeholder: UIImage(systemName: "photo"),
            downsamplingSize: CGSize(width: 100, height: 100)
        )

        // 매칭률 표시
        if matchRate > 0 {
            let percentage = Int(matchRate * 100)
            matchBadgeLabel.text = "\(percentage)% 매치"
        } else {
            matchBadgeLabel.text = ""
        }

        // 태그 설정
        configureTagStackView(recipe: recipe)

        // 북마크 상태
        bookmarkButton.setBookmarked(recipe.isBookmarked)
    }

    private func configureTagStackView(recipe: Recipe) {
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var tags: [String] = []
        if let category = recipe.category {
            tags.append(category.displayName)
        }
        if let method = recipe.method {
            tags.append(method.displayName)
        }

        tags.forEach { tagText in
            let tagLabel = UILabel()
            tagLabel.text = "#\(tagText)"
            tagLabel.font = .systemFont(ofSize: 12, weight: .medium)
            tagLabel.textColor = .systemGray
            tagStackView.addArrangedSubview(tagLabel)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipeImageView.image = nil
        recipeTitleLabel.text = nil
        matchBadgeLabel.text = nil
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
