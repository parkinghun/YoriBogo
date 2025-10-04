//
//  RecipeDetailViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/4/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RecipeDetailViewController: BaseViewController {

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.backgroundColor = .white
        return sv
    }()

    private let contentView = UIView()

    // 상단 이미지 및 정보
    private let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        return iv
    }()

    private let bookmarkButton = BookmarkButton(radius: 20)

    private let recipeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()

    private let matchBadgeLabel = BadgeLabel(text: "매칭률 95% ✨")

    // 태그
    private lazy var tagStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()

    // 보유 재료 섹션
    private let ownedIngredientsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "✅ 보유 재료 매칭 (4개)"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        return label
    }()

    private let ownedIngredientsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 0.15)
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var ownedIngredientsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fillProportionally
        return stack
    }()

    // 재료 섹션
    private let ingredientsSectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "📌 재료"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        return label
    }()

    private lazy var ingredientsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        return stack
    }()

    // 조리 단계 섹션
    private let stepsSectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "👨‍🍳 요리 단계"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        return label
    }()

    private lazy var stepsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        return stack
    }()

    // 요리 팁 섹션
    private let tipSectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "💡 요리 팁"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        return label
    }()

    private let tipContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        return view
    }()

    private let tipLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Properties
    private let viewModel: RecipeDetailViewModel
    private let disposeBag = DisposeBag()

    // MARK: - Initialization
    init(recipe: Recipe, matchRate: Double, matchedIngredients: [String]) {
        self.viewModel = RecipeDetailViewModel(
            recipe: recipe,
            matchRate: matchRate,
            matchedIngredients: matchedIngredients
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigatoin()
        setupUI()
        bind()
    }

    private func setupNavigatoin() {
        navigationItem.title = "상세 레시피"
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [recipeImageView, recipeTitleLabel, matchBadgeLabel,
         tagStackView, ownedIngredientsHeaderLabel, ownedIngredientsContainerView,
         ingredientsSectionHeaderLabel, ingredientsStackView,
         stepsSectionHeaderLabel, stepsStackView,
         tipSectionHeaderLabel, tipContainerView].forEach {
            contentView.addSubview($0)
        }
        
        recipeImageView.addSubview(bookmarkButton)

        ownedIngredientsContainerView.addSubview(ownedIngredientsStackView)
        tipContainerView.addSubview(tipLabel)

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(scrollView)
        }

        recipeImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(300)
        }

        bookmarkButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(40)
        }

        recipeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(recipeImageView.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        matchBadgeLabel.snp.makeConstraints {
            $0.top.equalTo(recipeTitleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
            $0.height.equalTo(32)
        }

        tagStackView.snp.makeConstraints {
            $0.top.equalTo(matchBadgeLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
        }

        ownedIngredientsHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(tagStackView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        ownedIngredientsContainerView.snp.makeConstraints {
            $0.top.equalTo(ownedIngredientsHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        ownedIngredientsStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        ingredientsSectionHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(ownedIngredientsContainerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        ingredientsStackView.snp.makeConstraints {
            $0.top.equalTo(ingredientsSectionHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        stepsSectionHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(ingredientsStackView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        stepsStackView.snp.makeConstraints {
            $0.top.equalTo(stepsSectionHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        tipSectionHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(stepsStackView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        // TODO: - 위로 올리기
        tipContainerView.snp.makeConstraints {
            $0.top.equalTo(tipSectionHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(40)
        }

        tipLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
    }

    // MARK: - Bind
    private func bind() {
        let input = RecipeDetailViewModel.Input(
            viewDidLoad: Observable.just(()),
            bookmarkButtonTap: bookmarkButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 레시피 정보
        output.recipe
            .drive(with: self) { owner, recipe in
                owner.recipeTitleLabel.text = recipe.title

                // 이미지
                let imageURL = recipe.images.first(where: { $0.isThumbnail })?.value
                owner.recipeImageView.setImageWithKF(
                    urlString: imageURL,
                    placeholder: UIImage(systemName: "photo"),
                    downsamplingSize: CGSize(width: UIScreen.main.bounds.width, height: 300)
                )
            }
            .disposed(by: disposeBag)

        // 매칭률
        output.matchRate
            .drive(with: self) { owner, matchRate in
                let percentage = Int(matchRate * 100)
                owner.matchBadgeLabel.text = "매칭률 \(percentage)% ✨"
            }
            .disposed(by: disposeBag)

        // 태그
        output.tags
            .drive(with: self) { owner, tags in
                owner.configureTagStackView(tags: tags)
            }
            .disposed(by: disposeBag)

        // 보유 재료
        output.matchedIngredients
            .drive(with: self) { owner, ingredients in
                owner.configureOwnedIngredients(ingredients: ingredients)
            }
            .disposed(by: disposeBag)

        // 전체 재료
        output.ingredients
            .drive(with: self) { owner, ingredients in
                owner.configureIngredients(ingredients: ingredients)
            }
            .disposed(by: disposeBag)

        // 조리 단계
        output.steps
            .drive(with: self) { owner, steps in
                owner.configureSteps(steps: steps)
            }
            .disposed(by: disposeBag)

        // 요리 팁
        output.tip
            .drive(with: self) { owner, tip in
                if let tip = tip, !tip.isEmpty {
                    owner.tipLabel.text = tip
                } else {
                    owner.tipSectionHeaderLabel.isHidden = true
                    owner.tipContainerView.isHidden = true
                }
            }
            .disposed(by: disposeBag)

        // 북마크 상태
        output.isBookmarked
            .drive(with: self) { owner, isBookmarked in
                let imageName = isBookmarked ? "heart.fill" : "heart"
                owner.bookmarkButton.setImage(UIImage(systemName: imageName), for: .normal)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods
    private func configureTagStackView(tags: [String]) {
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        tags.forEach { tag in
            let tagLabel = UILabel()
            tagLabel.text = "#\(tag)"
            tagLabel.font = .systemFont(ofSize: 14, weight: .medium)
            tagLabel.textColor = .systemOrange
            tagLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
            tagLabel.textAlignment = .center
            tagLabel.layer.cornerRadius = 14
            tagLabel.clipsToBounds = true

            tagLabel.snp.makeConstraints {
                $0.height.equalTo(28)
                $0.width.greaterThanOrEqualTo(60)
            }

            tagStackView.addArrangedSubview(tagLabel)
        }
    }

    private func configureOwnedIngredients(ingredients: [String]) {
        ownedIngredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if ingredients.isEmpty {
            ownedIngredientsHeaderLabel.isHidden = true
            ownedIngredientsContainerView.isHidden = true
            return
        }

        ownedIngredientsHeaderLabel.text = "✅ 보유 재료 매칭 (\(ingredients.count)개)"

        // 가로로 나열하되, 2줄까지만 표시
        let hStack1 = UIStackView()
        hStack1.axis = .horizontal
        hStack1.spacing = 8
        hStack1.alignment = .leading
        hStack1.distribution = .fillProportionally

        let hStack2 = UIStackView()
        hStack2.axis = .horizontal
        hStack2.spacing = 8
        hStack2.alignment = .leading
        hStack2.distribution = .fillProportionally

        let vStack = UIStackView(arrangedSubviews: [hStack1, hStack2])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.alignment = .leading

        ingredients.enumerated().forEach { index, ingredient in
            let tag = createIngredientTag(text: ingredient)
            if index < (ingredients.count + 1) / 2 {
                hStack1.addArrangedSubview(tag)
            } else {
                hStack2.addArrangedSubview(tag)
            }
        }

        ownedIngredientsStackView.addArrangedSubview(vStack)
    }

    private func createIngredientTag(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 1.0)
        label.backgroundColor = UIColor(red: 144/255, green: 238/255, blue: 144/255, alpha: 0.25)
        label.textAlignment = .center
        label.layer.cornerRadius = 14
        label.clipsToBounds = true
        label.layer.borderColor = UIColor(red: 34/255, green: 139/255, blue: 34/255, alpha: 0.2).cgColor
        label.layer.borderWidth = 1

        label.snp.makeConstraints {
            $0.height.equalTo(28)
            $0.width.greaterThanOrEqualTo(50)
        }

        return label
    }

    private func configureIngredients(ingredients: [RecipeIngredient]) {
        ingredientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        ingredients.forEach { ingredient in
            let itemView = createIngredientItemView(ingredient: ingredient)
            ingredientsStackView.addArrangedSubview(itemView)
        }
    }

    private func createIngredientItemView(ingredient: RecipeIngredient) -> UIView {
        let containerView = UIView()

        let bulletLabel = UILabel()
        bulletLabel.text = "•"
        bulletLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bulletLabel.textColor = .systemOrange

        let nameLabel = UILabel()
        nameLabel.text = ingredient.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .regular)
        nameLabel.textColor = .darkGray

        let quantityLabel = UILabel()
        if let qty = ingredient.qty, let unit = ingredient.unit {
            quantityLabel.text = "\(qty)\(unit)"
        } else if let altText = ingredient.altText {
            quantityLabel.text = altText
        } else {
            quantityLabel.text = ""
        }
        quantityLabel.font = .systemFont(ofSize: 14, weight: .regular)
        quantityLabel.textColor = .systemGray
        quantityLabel.textAlignment = .right

        [bulletLabel, nameLabel, quantityLabel].forEach {
            containerView.addSubview($0)
        }

        bulletLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.width.equalTo(10)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(bulletLabel.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
        }

        quantityLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(nameLabel.snp.trailing).offset(8)
        }

        containerView.snp.makeConstraints {
            $0.height.equalTo(24)
        }

        return containerView
    }

    private func configureSteps(steps: [RecipeStep]) {
        stepsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        steps.forEach { step in
            let stepView = createStepView(step: step)
            stepsStackView.addArrangedSubview(stepView)
        }
    }

    private func createStepView(step: RecipeStep) -> UIView {
        let containerView = UIView()

        let stepNumberLabel = UILabel()
        stepNumberLabel.text = "\(step.index)"
        stepNumberLabel.font = .systemFont(ofSize: 18, weight: .bold)
        stepNumberLabel.textColor = .white
        stepNumberLabel.backgroundColor = .systemOrange
        stepNumberLabel.textAlignment = .center
        stepNumberLabel.layer.cornerRadius = 18
        stepNumberLabel.clipsToBounds = true

        let stepTextLabel = UILabel()
        stepTextLabel.text = step.text
        stepTextLabel.font = .systemFont(ofSize: 14, weight: .regular)
        stepTextLabel.textColor = .darkGray
        stepTextLabel.numberOfLines = 0

        containerView.addSubview(stepNumberLabel)
        containerView.addSubview(stepTextLabel)

        stepNumberLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.size.equalTo(36)
        }

        stepTextLabel.snp.makeConstraints {
            $0.top.equalTo(stepNumberLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview()
        }

        // 이미지가 있으면 추가
        if !step.images.isEmpty {
            let imageStackView = UIStackView()
            imageStackView.axis = .horizontal
            imageStackView.spacing = 8
            imageStackView.alignment = .leading
            imageStackView.distribution = .equalSpacing

            step.images.prefix(2).forEach { imageInfo in
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.backgroundColor = .systemGray6

                imageView.setImageWithKF(
                    urlString: imageInfo.value,
                    placeholder: UIImage(systemName: "photo"),
                    downsamplingSize: CGSize(width: 150, height: 150)
                )

                imageView.snp.makeConstraints {
                    $0.size.equalTo(120)
                }

                imageStackView.addArrangedSubview(imageView)
            }

            containerView.addSubview(imageStackView)

            imageStackView.snp.makeConstraints {
                $0.top.equalTo(stepTextLabel.snp.bottom).offset(12)
                $0.horizontalEdges.equalToSuperview()
                $0.bottom.equalToSuperview()
            }
        } else {
            stepTextLabel.snp.makeConstraints {
                $0.bottom.equalToSuperview()
            }
        }

        return containerView
    }
}
