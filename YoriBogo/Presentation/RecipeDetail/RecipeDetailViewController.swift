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
        sv.backgroundColor = .gray50
        return sv
    }()

    private let contentView = UIView()

    // 상단 이미지 및 정보
    private let recipeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let bookmarkButton = BookmarkButton(radius: 20)

    private let recipeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .darkGray
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let matchBadgeLabel: BadgeLabel = {
        let label = BadgeLabel(text: "95%")
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    // 태그
    private lazy var tagStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .leading
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
        view.backgroundColor = .brandOrange50
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

    // 보유 재료 섹션
    private let ownedIngredientsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .statusGreen50
        view.layer.cornerRadius = 12
        return view
    }()

    private let ownedIngredientsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "✅ 보유 재료 매칭 (4개)"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        return label
    }()

    private let ownedIngredientsFlowView: FlowLayoutView = {
        let view = FlowLayoutView()
        view.horizontalSpacing = 8
        view.verticalSpacing = 8
        return view
    }()

    private let emptyIngredientsLabel: UILabel = {
        let label = UILabel()
        label.text = "보유 재료가 없습니다"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray500
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // 재료 섹션
    private let ingredientsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()

    private let ingredientsSectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "재료"
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
    private let stepsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()

    private let stepsSectionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "요리 단계"
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

    // MARK: - Properties
    private let viewModel: RecipeDetailViewModel
    private let disposeBag = DisposeBag()
    private var matchedIngredientNames: [String] = []

    // MARK: - Initialization
    init(recipe: Recipe, matchRate: Double, matchedIngredients: [String]) {
        self.viewModel = RecipeDetailViewModel(
            recipe: recipe,
            matchRate: matchRate,
            matchedIngredients: matchedIngredients
        )
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [recipeImageView, recipeTitleLabel, matchBadgeLabel,
         tagStackView, tipContainerView,
         ownedIngredientsContainerView,
         ingredientsContainerView,
         stepsContainerView].forEach {
            contentView.addSubview($0)
        }

        recipeImageView.addSubview(bookmarkButton)
        tipContainerView.addSubview(tipSectionHeaderLabel)
        tipContainerView.addSubview(tipLabel)

        ownedIngredientsContainerView.addSubview(ownedIngredientsHeaderLabel)
        ownedIngredientsContainerView.addSubview(ownedIngredientsFlowView)
        ownedIngredientsContainerView.addSubview(emptyIngredientsLabel)

        ingredientsContainerView.addSubview(ingredientsSectionHeaderLabel)
        ingredientsContainerView.addSubview(ingredientsStackView)

        stepsContainerView.addSubview(stepsSectionHeaderLabel)
        stepsContainerView.addSubview(stepsStackView)

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
            $0.width.equalTo(scrollView)
        }

        // 이미지
        recipeImageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(300)
        }

        bookmarkButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(40)
        }

        // 타이틀 + 매칭률 (가로 배치)
        recipeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(recipeImageView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalTo(matchBadgeLabel.snp.leading).offset(-12)
        }

        matchBadgeLabel.snp.makeConstraints {
            $0.centerY.equalTo(recipeTitleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        // 태그
        tagStackView.snp.makeConstraints {
            $0.top.equalTo(recipeTitleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(20)
        }

        tipContainerView.snp.makeConstraints {
            $0.top.equalTo(tagStackView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalTo(tipLabel.snp.bottom).offset(16)
        }
        
        tipSectionHeaderLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview().inset(16)
        }

        tipLabel.snp.makeConstraints {
            $0.top.equalTo(tipSectionHeaderLabel.snp.bottom).offset(8)
            $0.leading.equalTo(tipSectionHeaderLabel)
            $0.trailing.equalToSuperview().inset(16)
        }

        ownedIngredientsContainerView.snp.makeConstraints {
            $0.top.equalTo(tipContainerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        ownedIngredientsHeaderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        ownedIngredientsFlowView.snp.makeConstraints {
            $0.top.equalTo(ownedIngredientsHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }

        emptyIngredientsLabel.snp.makeConstraints {
            $0.top.equalTo(ownedIngredientsHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(40)
        }

        ingredientsContainerView.snp.makeConstraints {
            $0.top.equalTo(ownedIngredientsContainerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        ingredientsSectionHeaderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        ingredientsStackView.snp.makeConstraints {
            $0.top.equalTo(ingredientsSectionHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.bottom.equalToSuperview().inset(16)
        }

        // 요리 단계 (컨테이너 안에 헤더 포함)
        stepsContainerView.snp.makeConstraints {
            $0.top.equalTo(ingredientsContainerView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(40)
        }

        stepsSectionHeaderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        stepsStackView.snp.makeConstraints {
            $0.top.equalTo(stepsSectionHeaderLabel.snp.bottom).offset(12)
            $0.horizontalEdges.bottom.equalToSuperview().inset(16)
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
                owner.navigationItem.title = recipe.title
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
                owner.matchBadgeLabel.updateText("매치율 \(percentage)%")
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
                owner.matchedIngredientNames = ingredients
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
                    owner.tipLabel.text = "-"
                }
            }
            .disposed(by: disposeBag)

        // 북마크 상태
        output.isBookmarked
            .drive(with: self) { owner, isBookmarked in
                owner.bookmarkButton.setBookmarked(isBookmarked)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods
    private func configureTagStackView(tags: [String]) {
        tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        tags.forEach { tag in
            let tagLabel = ChipLabel(text: "#\(tag)", style: .orangeLight, size: .medium)
            tagStackView.addArrangedSubview(tagLabel)
        }
    }

    private func configureOwnedIngredients(ingredients: [String]) {
        ownedIngredientsFlowView.removeAllArrangedSubviews()

        if ingredients.isEmpty {
            ownedIngredientsHeaderLabel.text = "보유 재료 매칭"
            ownedIngredientsFlowView.isHidden = true
            emptyIngredientsLabel.isHidden = false
            return
        }

        ownedIngredientsHeaderLabel.text = "✅ 보유 재료 매칭 (\(ingredients.count)개)"
        ownedIngredientsFlowView.isHidden = false
        emptyIngredientsLabel.isHidden = true

        // FlowLayoutView에 태그 추가
        ingredients.forEach { ingredient in
            let tag = createIngredientTag(text: ingredient)
            ownedIngredientsFlowView.addArrangedSubview(tag)
        }
    }

    private func createIngredientTag(text: String) -> ChipLabel {
        return ChipLabel(text: text, style: .greenLight, size: .medium)
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

        // 보유 재료 확인 (IngredientMatcher 사용)
        let isOwned = matchedIngredientNames.contains { matchedName in
            IngredientMatcher.isMatch(
                recipeIngredient: ingredient.name.lowercased(),
                userIngredient: matchedName.lowercased()
            )
        }

        let bulletView = UIView()
        bulletView.backgroundColor = isOwned ? .statusGreen500 : .brandOrange500
        bulletView.layer.cornerRadius = 4
        bulletView.clipsToBounds = true

        // 재료명 (왼쪽)
        let nameLabel = UILabel()
        nameLabel.text = ingredient.name
        nameLabel.font = .systemFont(ofSize: 15, weight: .regular)
        nameLabel.textColor = .gray700
        nameLabel.numberOfLines = 1

        // 부가 정보 (오른쪽): qty unit (altText)
        let detailLabel = UILabel()
        detailLabel.text = formatIngredientDetail(ingredient)
        detailLabel.font = .systemFont(ofSize: 15, weight: .regular)
        detailLabel.textColor = .gray500
        detailLabel.textAlignment = .right
        detailLabel.numberOfLines = 1

        [bulletView, nameLabel, detailLabel].forEach {
            containerView.addSubview($0)
        }

        bulletView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(8)
        }

        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(bulletView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        detailLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(nameLabel.snp.trailing).offset(12)
        }

        containerView.snp.makeConstraints {
            $0.height.equalTo(28)
        }

        return containerView
    }

    private func formatIngredientDetail(_ ingredient: RecipeIngredient) -> String {
        var parts: [String] = []

        // qty와 unit이 있으면 추가 (소수점 최적화)
        if let qty = ingredient.qty, let unit = ingredient.unit {
            let formattedQty = qty.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", qty)  // 정수
                : String(format: "%g", qty)     // 소수점 (trailing zeros 제거)
            parts.append("\(formattedQty)\(unit)")
        }

        // altText가 있으면 괄호로 추가
        if let altText = ingredient.altText, !altText.isEmpty {
            parts.append("(\(altText))")
        }

        return parts.joined(separator: " ")
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

        // 원형 번호 배지
        let stepNumberBadge = UILabel()
        stepNumberBadge.text = "\(step.index)"
        stepNumberBadge.font = .systemFont(ofSize: 16, weight: .bold)
        stepNumberBadge.textColor = .brandOrange600
        stepNumberBadge.backgroundColor = .brandOrange100
        stepNumberBadge.textAlignment = .center
        stepNumberBadge.layer.cornerRadius = 18
        stepNumberBadge.clipsToBounds = true

        // 텍스트에서 숫자 부분 제거 (예: "1. 오렌지를 깎는다" -> "오렌지를 깎는다")
        let cleanedText = step.text.replacingOccurrences(
            of: "^\\d+\\.\\s*",
            with: "",
            options: .regularExpression
        )

        let stepTextLabel = UILabel()
        stepTextLabel.text = cleanedText
        stepTextLabel.font = .systemFont(ofSize: 15, weight: .regular)
        stepTextLabel.textColor = .gray700
        stepTextLabel.numberOfLines = 0

        containerView.addSubview(stepNumberBadge)
        containerView.addSubview(stepTextLabel)

        stepNumberBadge.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.size.equalTo(36)
        }

        stepTextLabel.snp.makeConstraints {
            $0.leading.equalTo(stepNumberBadge.snp.trailing).offset(12)
            $0.trailing.equalToSuperview()
            $0.top.equalTo(stepNumberBadge)
        }

        if !step.images.isEmpty {
            let imageScrollView = UIScrollView()
            imageScrollView.showsHorizontalScrollIndicator = false
            imageScrollView.showsVerticalScrollIndicator = false

            let imageStackView = UIStackView()
            imageStackView.axis = .horizontal
            imageStackView.spacing = 8
            imageStackView.alignment = .leading
            imageStackView.distribution = .equalSpacing

            step.images.forEach { imageInfo in
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
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

            imageScrollView.addSubview(imageStackView)
            containerView.addSubview(imageScrollView)

            imageScrollView.snp.makeConstraints {
                $0.top.equalTo(stepTextLabel.snp.bottom).offset(12)
                $0.leading.equalTo(stepTextLabel)
                $0.trailing.equalToSuperview()
                $0.height.equalTo(120)
                $0.bottom.equalToSuperview()
            }

            imageStackView.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.height.equalToSuperview()
            }
        } else {
            stepTextLabel.snp.makeConstraints {
                $0.bottom.equalToSuperview()
            }
        }

        return containerView
    }
}
