//
//  RecommendRecipeCell.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import SnapKit
import Kingfisher

final class RecommendRecipeCell: UICollectionViewCell, ReusableView {

    // MARK: - Properties
    private var recipeId: String?
    var onBookmarkTapped: ((String) -> Void)?

    // MARK: - UI Components
    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        return view
    }()

    private let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .systemGray6
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 24
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return iv
    }()

    private let badgeLabel = BadgeLabel(text: "보유재료와 95% 매치 ✨")

    private let bookmarkButton = BookmarkButton()

    private let recipeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .darkGray
        label.numberOfLines = 2
        label.text = "혼제오리 야채집"
        return label
    }()

    private lazy var ingredientsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fillProportionally
        return stack
    }()

    private let methodTagLabel = ChipLabel(text: "#메인요리", style: .orangeLight, size: .regular)

    private let categoryTagLabel = ChipLabel(text: "#초급", style: .orangeLight, size: .regular)

    private lazy var tagStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [methodTagLabel, categoryTagLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
        return stack
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

    @objc private func bookmarkButtonTapped() {
        print("🔥 북마크 버튼 탭됨")
        guard let recipeId = recipeId else {
            print("⚠️ recipeId가 nil입니다")
            return
        }
        print("✅ recipeId: \(recipeId)")
        onBookmarkTapped?(recipeId)
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(cardContainerView)

        [recipeImageView, badgeLabel, bookmarkButton, recipeTitleLabel,
         ingredientsStackView, tagStackView].forEach {
            cardContainerView.addSubview($0)
        }

        cardContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        recipeImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(recipeImageView.snp.width).multipliedBy(0.7)
        }

        badgeLabel.snp.makeConstraints {
            $0.top.equalTo(recipeImageView).offset(16)
            $0.leading.equalTo(recipeImageView).offset(16)
            $0.height.equalTo(36)
        }

        bookmarkButton.snp.makeConstraints {
            $0.top.equalTo(recipeImageView).offset(16)
            $0.trailing.equalTo(recipeImageView).offset(-16)
            $0.size.equalTo(48)
        }

        recipeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(recipeImageView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        ingredientsStackView.snp.makeConstraints {
            $0.top.equalTo(recipeTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(32)
        }


        tagStackView.snp.makeConstraints {
            $0.top.equalTo(ingredientsStackView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.bottom.lessThanOrEqualToSuperview().inset(20)
        }
    }

    // MARK: - Configuration
    func configure(with recipe: Recipe, hasIngredients: Bool, matchRate: Double, matchedIngredients: [String]) {
        recipeId = recipe.id
        recipeTitleLabel.text = recipe.title

        // 이미지 로드
        let imageURL = recipe.images.first(where: { $0.isThumbnail })?.value
        recipeImageView.setImageWithKF(urlString: imageURL, placeholder: UIImage(systemName: "photo"))

        // 배지 설정 (매칭률 표시)
        if hasIngredients && matchRate > 0 {
            let percentage = Int(matchRate * 100)
            badgeLabel.text = "보유재료와 \(percentage)% 매치 ✨"
        } else {
            badgeLabel.text = "간단 요리 추천 ✨"
        }

        // 보유 재료 태그 설정
        configureIngredientsTags(matchedIngredients: matchedIngredients)

        // 태그 설정
        if let method = recipe.method {
            methodTagLabel.updateText("#\(method.displayName)")
        }

        if let category = recipe.category {
            categoryTagLabel.updateText("#\(category.displayName)")
        }

        // 북마크 상태
        bookmarkButton.setBookmarked(recipe.isBookmarked)
    }

    private func configureIngredientsTags(matchedIngredients: [String]) {
        // 기존 태그 제거
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !matchedIngredients.isEmpty else { return }

        let maxDisplayCount = 3
        let displayIngredients = Array(matchedIngredients.prefix(maxDisplayCount))

        // 재료 태그 생성
        displayIngredients.forEach { ingredient in
            let tag = createIngredientTag(text: ingredient)
            ingredientsStackView.addArrangedSubview(tag)
        }

        // 나머지 재료가 있으면 +N 태그 추가
        let remainingCount = matchedIngredients.count - displayIngredients.count
        if remainingCount > 0 {
            let remainingTag = createIngredientTag(text: "+\(remainingCount)")
            ingredientsStackView.addArrangedSubview(remainingTag)
        }
    }

    private func createIngredientTag(text: String) -> ChipLabel {
        return ChipLabel(text: text, style: .greenLight, size: .regular)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        recipeId = nil
        onBookmarkTapped = nil
        recipeImageView.image = nil
        recipeTitleLabel.text = nil
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
