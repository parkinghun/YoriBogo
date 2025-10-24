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

    // MARK: - ViewModel
    private let viewModel: RecipeAddViewModel

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

    let titleTextField: UITextField = {
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

    // 메인 이미지
    private let mainImageLabel: UILabel = {
        let label = UILabel()
        label.text = "메인 이미지"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private lazy var addMainImageButton: UIButton = {
        let button = UIButton()
        button.setTitle("+ 이미지 추가", for: .normal)
        button.setTitleColor(.brandOrange500, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()

    let mainImageScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = .gray100
        sv.layer.cornerRadius = 16
        sv.clipsToBounds = true
        return sv
    }()

    let mainImagePageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .brandOrange500
        pc.pageIndicatorTintColor = .gray300
        pc.hidesForSinglePage = true
        pc.isUserInteractionEnabled = false
        return pc
    }()

    let emptyMainImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray100
        view.layer.cornerRadius = 16

        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.tintColor = .gray400
        imageView.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "메인 이미지를 추가해주세요"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray500
        label.textAlignment = .center

        view.addSubview(imageView)
        view.addSubview(label)

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-20)
            $0.size.equalTo(60)
        }

        label.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        return view
    }()

    // 카테고리
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "카테고리"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    lazy var categoryButton: UIButton = {
        let button = UIButton()
        button.setTitle("반찬", for: .normal)
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

    private let categorySelectedRelay = PublishRelay<RecipeCategory>()

    // 태그
    private let tagLabel: UILabel = {
        let label = UILabel()
        label.text = "태그"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        return label
    }()

    let tagTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "다이어트, 식단"
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

    let tagChipsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let tagRemovedRelay = PublishRelay<Int>()

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
        return button
    }()

    let ingredientsStackView: UIStackView = {
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
        return button
    }()

    let stepsStackView: UIStackView = {
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

    let tipTextView: UITextView = {
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
    var tags: [String] = []
    let imagePickerManager = ImagePickerManager()

    // 이미지 경로 저장 (메모리 최적화)
    var mainImagePaths: [String] = []
    var stepImagePaths: [Int: [String]] = [:]

    // Relays for ViewModel input (internal for extension access)
    let mainImagesAddedRelay = PublishRelay<[UIImage]>()
    let mainImageRemovedRelay = PublishRelay<Int>()
    let stepImagesAddedRelay = PublishRelay<(stepNumber: Int, images: [UIImage])>()
    let stepImageRemovedRelay = PublishRelay<(stepNumber: Int, index: Int)>()

    // 편집 모드
    var isEditMode: Bool = false
    var isCreateFromApi: Bool = false

    // Completion handler
    var onSaveCompleted: ((Recipe) -> Void)?

    // MARK: - Initialization
    init(editingRecipe: Recipe? = nil, isCreateFromApi: Bool = false) {
        self.isEditMode = editingRecipe != nil
        self.isCreateFromApi = isCreateFromApi
        self.viewModel = RecipeAddViewModel(editingRecipe: editingRecipe, isCreateFromApi: isCreateFromApi)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "저장", style: .done, target: nil, action: nil)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupKeyboard()
        bindViewModel()

        // 신규 추가 모드일 때 초기 재료와 단계 추가
        if !isEditMode {
            addInitialIngredient()
            addInitialStep()
        }
    }

    // MARK: - Setup
    private func setupNavigation() {
        if isCreateFromApi {
            setNavigationTitle("나의 레시피로 만들기")
        } else {
            setNavigationTitle(isEditMode ? "레시피 수정" : "레시피 추가")
        }

        let cancelButton = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(cancelTapped))

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, titleTextField,
         mainImageLabel, addMainImageButton, mainImageScrollView, mainImagePageControl, emptyMainImageView,
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

        // 메인 이미지
        mainImageLabel.snp.makeConstraints {
            $0.top.equalTo(titleTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(20)
        }

        addMainImageButton.snp.makeConstraints {
            $0.centerY.equalTo(mainImageLabel)
            $0.trailing.equalToSuperview().inset(20)
        }

        emptyMainImageView.snp.makeConstraints {
            $0.top.equalTo(mainImageLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(240)
        }

        mainImageScrollView.snp.makeConstraints {
            $0.top.equalTo(mainImageLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(240)
        }

        mainImagePageControl.snp.makeConstraints {
            $0.top.equalTo(mainImageScrollView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
        }

        // 카테고리
        categoryLabel.snp.makeConstraints {
            $0.top.equalTo(mainImagePageControl.snp.bottom).offset(24)
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
        mainImageScrollView.delegate = self

        // 초기 상태: 이미지 없으면 emptyView 표시
        updateMainImageDisplay()
    }

    private func setupKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        // 재료 변경 감지
        let ingredientsChanged = Observable<Void>.merge(
            addIngredientButton.rx.tap.asObservable(),
            NotificationCenter.default.rx.notification(Notification.Name("IngredientChanged")).map { _ in () }
        )
        .map { [weak self] _ -> [RecipeIngredient] in
            return self?.collectIngredients() ?? []
        }

        // 단계 변경 감지
        let stepsChanged = Observable<Void>.merge(
            addStepButton.rx.tap.asObservable(),
            NotificationCenter.default.rx.notification(Notification.Name("StepChanged")).map { _ in () }
        )
        .map { [weak self] _ -> [RecipeStep] in
            return self?.collectSteps() ?? []
        }

        // Tag 텍스트 입력 (Return 키 눌렀을 때)
        let tagText = tagTextField.rx.controlEvent(.editingDidEndOnExit)
            .map { [weak self] _ in self?.tagTextField.text?.trimmingCharacters(in: .whitespaces) ?? "" }
            .filter { !$0.isEmpty }
            .do(onNext: { [weak self] _ in self?.tagTextField.text = "" })

        // Tip 텍스트
        let tipText = tipTextView.rx.text
            .map { [weak self] text -> String? in
                guard let self = self else { return nil }
                if self.tipTextView.textColor == .gray400 || text?.isEmpty == true {
                    return nil
                }
                return text
            }

        // Input 생성
        let input = RecipeAddViewModel.Input(
            viewDidLoad: Observable.just(()),
            titleText: titleTextField.rx.text.asObservable(),
            categorySelected: categorySelectedRelay.asObservable(),
            tagText: tagText,
            tagRemoved: tagRemovedRelay.asObservable(),
            mainImagesAdded: mainImagesAddedRelay.asObservable(),
            mainImageRemoved: mainImageRemovedRelay.asObservable(),
            ingredientsChanged: ingredientsChanged,
            stepsChanged: stepsChanged,
            stepImagesAdded: stepImagesAddedRelay.asObservable(),
            stepImageRemoved: stepImageRemovedRelay.asObservable(),
            tipText: tipText,
            saveTapped: saveButton.rx.tap.asObservable()
        )

        // Transform
        let output = viewModel.transform(input: input)

        // Output 바인딩
        output.title
            .drive(onNext: { [weak self] title in
                print("📥 RecipeAddVC: Received title: '\(title ?? "nil")'")
                self?.titleTextField.text = title
            })
            .disposed(by: disposeBag)

        output.category
            .drive(onNext: { [weak self] (category: RecipeCategory) in
                print("📥 RecipeAddVC: Received category: \(category.displayName)")
                self?.categoryButton.setTitle(category.displayName, for: .normal)
            })
            .disposed(by: disposeBag)

        output.tags
            .drive(onNext: { [weak self] (tags: [String]) in
                print("📥 RecipeAddVC: Received tags: \(tags)")
                self?.tags = tags
                self?.updateTagChips()
            })
            .disposed(by: disposeBag)

        output.mainImagePaths
            .drive(onNext: { [weak self] (paths: [String]) in
                self?.mainImagePaths = paths
                self?.updateMainImageDisplay()
            })
            .disposed(by: disposeBag)

        output.stepImagePaths
            .drive(onNext: { [weak self] (paths: [Int: [String]]) in
                self?.stepImagePaths = paths
                // 모든 단계의 이미지 업데이트
                paths.keys.forEach { stepNumber in
                    self?.updateStepImagesDisplay(stepNumber: stepNumber)
                }
            })
            .disposed(by: disposeBag)

        output.ingredients
            .drive(onNext: { [weak self] ingredients in
                guard let self = self else { return }
                print("📥 RecipeAddVC: Received ingredients count: \(ingredients.count)")
                if !ingredients.isEmpty {
                    print("✅ RecipeAddVC: Loading ingredients to UI")
                    self.loadIngredients(ingredients)
                } else {
                    print("⚠️ RecipeAddVC: Ingredients is empty, skipping loadIngredients")
                }
            })
            .disposed(by: disposeBag)

        output.steps
            .drive(onNext: { [weak self] steps in
                guard let self = self else { return }
                print("📥 RecipeAddVC: Received steps count: \(steps.count)")
                if !steps.isEmpty {
                    print("✅ RecipeAddVC: Loading steps to UI")
                    self.loadSteps(steps)
                } else {
                    print("⚠️ RecipeAddVC: Steps is empty, skipping loadSteps")
                }
            })
            .disposed(by: disposeBag)

        output.tip
            .drive(onNext: { [weak self] (tip: String?) in
                if let tip = tip, !tip.isEmpty {
                    self?.tipTextView.text = tip
                    self?.tipTextView.textColor = .black
                }
            })
            .disposed(by: disposeBag)

        output.saveEnabled
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.saveSuccess
            .drive(onNext: { [weak self] recipe in
                self?.onSaveCompleted?(recipe)
            })
            .disposed(by: disposeBag)

        output.error
            .drive(onNext: { [weak self] message in
                self?.showAlert(message: message)
            })
            .disposed(by: disposeBag)

        output.dismissView
            .drive(onNext: { [weak self] (_: Void) in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

        // 메인 이미지 추가 버튼
        addMainImageButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addMainImageButtonTapped()
            })
            .disposed(by: disposeBag)

        // 재료 추가 버튼
        addIngredientButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addIngredientTapped()
            })
            .disposed(by: disposeBag)

        // 단계 추가 버튼
        addStepButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addStepTapped()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Category Menu
    private func createCategoryMenu() -> UIMenu {
        let categories = RecipeCategory.allCases.map { $0.displayName }
        let actions = categories.map { categoryName in
            UIAction(title: categoryName) { [weak self] _ in
                self?.categoryButton.setTitle(categoryName, for: .normal)
                let category = RecipeCategory(rawValue: categoryName)
                self?.categorySelectedRelay.accept(category)
            }
        }
        return UIMenu(children: actions)
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension RecipeAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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

// MARK: - UIScrollViewDelegate
extension RecipeAddViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainImageScrollView else { return }

        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        mainImagePageControl.currentPage = currentPage
    }
}
