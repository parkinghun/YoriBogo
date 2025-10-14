//
//  RecipeAddViewController.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-14.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class RecipeAddViewController: BaseViewController {

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.backgroundColor = .white
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    // 레시피 이름
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "레시피 이름"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "레시피 이름을 입력하세요"
        tf.font = .systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.backgroundColor = .gray50
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        return tf
    }()

    // 카테고리
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private lazy var categoryButton: UIButton = {
        let button = UIButton()
        button.setTitle("한식", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.backgroundColor = .gray50
        button.layer.cornerRadius = 12

        // 드롭다운 아이콘
        let imageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        imageView.tintColor = .gray500
        button.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        button.menu = createCategoryMenu()
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    // 태그
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.text = "태그"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private let tagTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "매운맛, 집밥"
        tf.font = .systemFont(ofSize: 16)
        tf.borderStyle = .none
        tf.backgroundColor = .gray50
        tf.layer.cornerRadius = 12
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.rightViewMode = .always
        tf.returnKeyType = .done
        return tf
    }()

    private let tagChipsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    // 재료
    private let ingredientLabel: UILabel = {
        let label = UILabel()
        label.text = "재료"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private lazy var addIngredientButton: UIButton = {
        let button = UIButton()
        button.setTitle("+ 재료 추가", for: .normal)
        button.setTitleColor(.brandOrange500, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(addIngredientTapped), for: .touchUpInside)
        return button
    }()

    private let ingredientsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.distribution = .fill
        return sv
    }()

    // 요리 단계
    private let stepLabel: UILabel = {
        let label = UILabel()
        label.text = "요리 단계"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private lazy var addStepButton: UIButton = {
        let button = UIButton()
        button.setTitle("+ 단계 추가", for: .normal)
        button.setTitleColor(.brandOrange500, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(addStepTapped), for: .touchUpInside)
        return button
    }()

    private let stepsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.distribution = .fill
        return sv
    }()

    // 요리 팁
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = "요리 팁"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private let tipTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.textColor = .gray400
        tv.text = "맛있게 만드는 비법을 알려주세요"
        tv.backgroundColor = .gray50
        tv.layer.cornerRadius = 12
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        return tv
    }()

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var tags: [String] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupKeyboard()
        addInitialIngredient()
        addInitialStep()
    }

    // MARK: - Setup
    private func setupNavigation() {
        setNavigationTitle("레시피 추가")

        let cancelButton = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(cancelTapped))
        let saveButton = UIBarButtonItem(title: "저장", style: .done, target: self, action: #selector(saveTapped))

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, titleTextField,
         categoryLabel, categoryButton,
         tagLabel, tagTextField, tagChipsContainer,
         ingredientLabel, addIngredientButton, ingredientsStackView,
         stepLabel, addStepButton, stepsStackView,
         tipLabel, tipTextView].forEach {
            contentView.addSubview($0)
        }

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 레시피 이름
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        titleTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        // 카테고리
        categoryLabel.snp.makeConstraints {
            $0.top.equalTo(titleTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(20)
        }

        categoryButton.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(20)
            $0.width.equalTo(160)
            $0.height.equalTo(52)
        }

        // 태그
        tagLabel.snp.makeConstraints {
            $0.top.equalTo(categoryButton.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        tagTextField.snp.makeConstraints {
            $0.top.equalTo(tagLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }

        tagChipsContainer.snp.makeConstraints {
            $0.top.equalTo(tagTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(0)
        }

        // 재료
        ingredientLabel.snp.makeConstraints {
            $0.top.equalTo(tagChipsContainer.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(20)
        }

        addIngredientButton.snp.makeConstraints {
            $0.centerY.equalTo(ingredientLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        ingredientsStackView.snp.makeConstraints {
            $0.top.equalTo(ingredientLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 요리 단계
        stepLabel.snp.makeConstraints {
            $0.top.equalTo(ingredientsStackView.snp.bottom).offset(32)
            $0.leading.equalToSuperview().inset(20)
        }

        addStepButton.snp.makeConstraints {
            $0.centerY.equalTo(stepLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        stepsStackView.snp.makeConstraints {
            $0.top.equalTo(stepLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 요리 팁
        tipLabel.snp.makeConstraints {
            $0.top.equalTo(stepsStackView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        tipTextView.snp.makeConstraints {
            $0.top.equalTo(tipLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(120)
            $0.bottom.equalToSuperview().offset(-40)
        }

        tipTextView.delegate = self
        tagTextField.delegate = self
    }

    private func setupKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Category Menu
    private func createCategoryMenu() -> UIMenu {
        let categories = RecipeCategory.allCases.map { $0.displayName }
        let actions = categories.map { categoryName in
            UIAction(title: categoryName) { [weak self] _ in
                self?.categoryButton.setTitle(categoryName, for: .normal)
            }
        }
        return UIMenu(children: actions)
    }

    // MARK: - Ingredient Management
    private func addInitialIngredient() {
        let ingredientView = createIngredientView()
        ingredientsStackView.addArrangedSubview(ingredientView)
    }

    private func createIngredientView() -> UIView {
        let containerView = UIView()

        let nameTextField = UITextField()
        nameTextField.placeholder = "재료명"
        nameTextField.font = .systemFont(ofSize: 16)
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = .gray50
        nameTextField.layer.cornerRadius = 12
        nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameTextField.leftViewMode = .always

        let qtyTextField = UITextField()
        qtyTextField.placeholder = "1"
        qtyTextField.font = .systemFont(ofSize: 16)
        qtyTextField.borderStyle = .none
        qtyTextField.backgroundColor = .gray50
        qtyTextField.layer.cornerRadius = 12
        qtyTextField.textAlignment = .center
        qtyTextField.keyboardType = .decimalPad

        let unitTextField = UITextField()
        unitTextField.placeholder = "개"
        unitTextField.font = .systemFont(ofSize: 16)
        unitTextField.borderStyle = .none
        unitTextField.backgroundColor = .gray50
        unitTextField.layer.cornerRadius = 12
        unitTextField.textAlignment = .center

        containerView.addSubview(nameTextField)
        containerView.addSubview(qtyTextField)
        containerView.addSubview(unitTextField)

        nameTextField.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.height.equalTo(52)
        }

        qtyTextField.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalTo(nameTextField.snp.trailing).offset(8)
            $0.width.equalTo(70)
        }

        unitTextField.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(qtyTextField.snp.trailing).offset(8)
            $0.width.equalTo(80)
        }

        return containerView
    }

    @objc private func addIngredientTapped() {
        let ingredientView = createIngredientView()
        ingredientsStackView.addArrangedSubview(ingredientView)
    }

    // MARK: - Step Management
    private func addInitialStep() {
        let stepView = createStepView(stepNumber: 1)
        stepsStackView.addArrangedSubview(stepView)
    }

    private func createStepView(stepNumber: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .gray50
        containerView.layer.cornerRadius = 16

        let numberLabel = UILabel()
        numberLabel.text = "\(stepNumber)"
        numberLabel.font = .systemFont(ofSize: 20, weight: .bold)
        numberLabel.textColor = .brandOrange500
        numberLabel.textAlignment = .center
        numberLabel.backgroundColor = .brandOrange50
        numberLabel.layer.cornerRadius = 20
        numberLabel.clipsToBounds = true

        let stepTextField = UITextField()
        stepTextField.placeholder = "요리 단계를 입력하세요"
        stepTextField.font = .systemFont(ofSize: 16)
        stepTextField.borderStyle = .none

        let imageLabel = UILabel()
        imageLabel.text = "단계 이미지 (선택사항)"
        imageLabel.font = .systemFont(ofSize: 14)
        imageLabel.textColor = .gray600

        let addImageButton = UIButton()
        addImageButton.setTitle("+ 이미지 추가", for: .normal)
        addImageButton.setTitleColor(.brandOrange500, for: .normal)
        addImageButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        addImageButton.setImage(UIImage(systemName: "photo"), for: .normal)
        addImageButton.tintColor = .brandOrange500
        addImageButton.contentHorizontalAlignment = .leading
        addImageButton.semanticContentAttribute = .forceLeftToRight
        addImageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)

        containerView.addSubview(numberLabel)
        containerView.addSubview(stepTextField)
        containerView.addSubview(imageLabel)
        containerView.addSubview(addImageButton)

        numberLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
            $0.size.equalTo(40)
        }

        stepTextField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalTo(numberLabel.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }

        imageLabel.snp.makeConstraints {
            $0.top.equalTo(stepTextField.snp.bottom).offset(16)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
        }

        addImageButton.snp.makeConstraints {
            $0.top.equalTo(imageLabel.snp.bottom).offset(8)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(32)
        }

        return containerView
    }

    @objc private func addStepTapped() {
        let stepNumber = stepsStackView.arrangedSubviews.count + 1
        let stepView = createStepView(stepNumber: stepNumber)
        stepsStackView.addArrangedSubview(stepView)
    }

    // MARK: - Tag Management
    private func addTagChip(_ tag: String) {
        guard !tag.isEmpty, !tags.contains(tag) else { return }

        tags.append(tag)
        updateTagChips()
    }

    private func updateTagChips() {
        // Clear existing chips
        tagChipsContainer.subviews.forEach { $0.removeFromSuperview() }

        guard !tags.isEmpty else {
            tagChipsContainer.snp.updateConstraints {
                $0.height.equalTo(0)
            }
            return
        }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally

        let currentRowStack = UIStackView()
        currentRowStack.axis = .horizontal
        currentRowStack.spacing = 8
        currentRowStack.distribution = .fillProportionally

        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 8
        containerStack.distribution = .fillEqually

        tagChipsContainer.addSubview(containerStack)
        containerStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        for (index, tag) in tags.enumerated() {
            let chipView = createTagChip(tag: tag, index: index)
            currentRowStack.addArrangedSubview(chipView)
        }

        containerStack.addArrangedSubview(currentRowStack)

        let chipHeight = 32
        let rows = (tags.count + 4) / 5 // 대략 한 줄에 5개 정도
        tagChipsContainer.snp.updateConstraints {
            $0.height.equalTo(chipHeight * rows + (rows - 1) * 8)
        }
    }

    private func createTagChip(tag: String, index: Int) -> UIView {
        let chipView = UIView()
        chipView.backgroundColor = .brandOrange50
        chipView.layer.cornerRadius = 16

        let label = UILabel()
        label.text = "#\(tag)"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .brandOrange600

        let deleteButton = UIButton()
        deleteButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        deleteButton.tintColor = .brandOrange500
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(removeTagChip(_:)), for: .touchUpInside)

        chipView.addSubview(label)
        chipView.addSubview(deleteButton)

        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
        }

        deleteButton.snp.makeConstraints {
            $0.leading.equalTo(label.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        chipView.snp.makeConstraints {
            $0.height.equalTo(32)
        }

        return chipView
    }

    @objc private func removeTagChip(_ sender: UIButton) {
        let index = sender.tag
        guard index < tags.count else { return }
        tags.remove(at: index)
        updateTagChips()
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        // 레시피 이름 검증
        guard let title = titleTextField.text?.trimmingCharacters(in: .whitespaces),
              !title.isEmpty else {
            showAlert(message: "레시피 이름을 입력해주세요")
            return
        }

        // 재료 수집
        let ingredients = collectIngredients()
        guard !ingredients.isEmpty else {
            showAlert(message: "재료를 최소 1개 이상 입력해주세요")
            return
        }

        // 요리 단계 수집
        let steps = collectSteps()
        guard !steps.isEmpty else {
            showAlert(message: "요리 단계를 최소 1개 이상 입력해주세요")
            return
        }

        // 카테고리 가져오기
        let categoryText = categoryButton.titleLabel?.text ?? "한식"
        let category = RecipeCategory(rawValue: categoryText)

        // 팁 가져오기
        let tip: String? = (tipTextView.textColor == .gray400 || tipTextView.text.isEmpty) ? nil : tipTextView.text

        // Recipe 객체 생성
        let recipe = Recipe(
            id: UUID().uuidString,
            baseId: UUID().uuidString,
            kind: .userOriginal,
            version: 1,
            title: title,
            category: category,
            method: nil,
            tags: tags,
            tip: tip,
            images: [],
            nutrition: nil,
            ingredients: ingredients,
            steps: steps,
            isBookmarked: false,
            rating: nil,
            cookCount: 0,
            lastCookedAt: nil,
            createdAt: Date(),
            updatedAt: nil
        )

        // Realm에 저장
        do {
            try RecipeRealmManager.shared.updateRecipe(recipe)
            dismiss(animated: true)
        } catch {
            showAlert(message: "레시피 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    private func collectIngredients() -> [RecipeIngredient] {
        var ingredients: [RecipeIngredient] = []

        for view in ingredientsStackView.arrangedSubviews {
            guard let nameTextField = view.subviews.first(where: { $0 is UITextField && ($0 as! UITextField).placeholder == "재료명" }) as? UITextField,
                  let name = nameTextField.text?.trimmingCharacters(in: .whitespaces),
                  !name.isEmpty else {
                continue
            }

            // qty와 unit 찾기
            var qty: Double?
            var unit: String?

            for subview in view.subviews {
                if let textField = subview as? UITextField {
                    if textField.placeholder == "1" {
                        if let text = textField.text, let value = Double(text) {
                            qty = value
                        }
                    } else if textField.placeholder == "개" {
                        unit = textField.text?.trimmingCharacters(in: .whitespaces)
                    }
                }
            }

            let ingredient = RecipeIngredient(
                name: name,
                qty: qty,
                unit: unit,
                altText: nil
            )
            ingredients.append(ingredient)
        }

        return ingredients
    }

    private func collectSteps() -> [RecipeStep] {
        var steps: [RecipeStep] = []

        for (index, view) in stepsStackView.arrangedSubviews.enumerated() {
            // stepTextField 찾기
            guard let stepTextField = view.subviews.first(where: { $0 is UITextField && ($0 as! UITextField).placeholder == "요리 단계를 입력하세요" }) as? UITextField,
                  let text = stepTextField.text?.trimmingCharacters(in: .whitespaces),
                  !text.isEmpty else {
                continue
            }

            let step = RecipeStep(
                index: index + 1,
                text: text,
                images: []
            )
            steps.append(step)
        }

        return steps
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension RecipeAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == tagTextField {
            if let text = textField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty {
                addTagChip(text)
                textField.text = ""
            }
        }
        return true
    }
}

// MARK: - UITextViewDelegate
extension RecipeAddViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .gray400 {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "맛있게 만드는 비법을 알려주세요"
            textView.textColor = .gray400
        }
    }
}
