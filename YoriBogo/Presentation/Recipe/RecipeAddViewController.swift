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
        button.addTarget(self, action: #selector(addMainImageButtonTapped), for: .touchUpInside)
        return button
    }()

    private let mainImageScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.backgroundColor = .gray100
        sv.layer.cornerRadius = 16
        sv.clipsToBounds = true
        return sv
    }()

    private let mainImagePageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .brandOrange500
        pc.pageIndicatorTintColor = .gray300
        pc.hidesForSinglePage = true
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private let emptyMainImageView: UIView = {
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
    private let imagePickerManager = ImagePickerManager()
    private var mainImages: [UIImage] = [] // 메인 이미지 (최대 5장)
    private var stepImages: [Int: [UIImage]] = [:] // stepNumber: images

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

    // MARK: - Main Image Management
    @objc private func addMainImageButtonTapped() {
        let currentImageCount = mainImages.count
        let remainingCount = 5 - currentImageCount

        guard remainingCount > 0 else {
            showAlert(message: "메인 이미지는 최대 5장까지 추가할 수 있습니다")
            return
        }

        imagePickerManager.presentImagePicker(
            from: self,
            maxSelectionCount: remainingCount
        ) { [weak self] images in
            self?.addMainImages(images)
        }
    }

    private func addMainImages(_ images: [UIImage]) {
        mainImages.append(contentsOf: images)
        updateMainImageDisplay()
    }

    private func updateMainImageDisplay() {
        if mainImages.isEmpty {
            // 이미지 없음: emptyView 표시
            emptyMainImageView.isHidden = false
            mainImageScrollView.isHidden = true
            mainImagePageControl.isHidden = true
        } else {
            // 이미지 있음: 페이징 스크롤뷰 표시
            emptyMainImageView.isHidden = true
            mainImageScrollView.isHidden = false
            mainImagePageControl.isHidden = false

            // 기존 서브뷰 제거
            mainImageScrollView.subviews.forEach { $0.removeFromSuperview() }

            let scrollViewWidth = UIScreen.main.bounds.width - 40
            let scrollViewHeight: CGFloat = 240

            // 스크롤뷰 contentSize 설정
            mainImageScrollView.contentSize = CGSize(
                width: scrollViewWidth * CGFloat(mainImages.count),
                height: scrollViewHeight
            )

            // 각 페이지에 이미지 추가
            for (index, image) in mainImages.enumerated() {
                let pageView = UIView(frame: CGRect(
                    x: scrollViewWidth * CGFloat(index),
                    y: 0,
                    width: scrollViewWidth,
                    height: scrollViewHeight
                ))

                let imageView = UIImageView()
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 16

                let deleteButton = UIButton()
                deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
                deleteButton.tintColor = .white
                deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                deleteButton.layer.cornerRadius = 16
                deleteButton.tag = index
                deleteButton.addTarget(self, action: #selector(deleteMainImageButtonTapped(_:)), for: .touchUpInside)

                pageView.addSubview(imageView)
                pageView.addSubview(deleteButton)

                imageView.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }

                deleteButton.snp.makeConstraints {
                    $0.top.trailing.equalToSuperview().inset(12)
                    $0.size.equalTo(32)
                }

                mainImageScrollView.addSubview(pageView)
            }

            // PageControl 설정
            mainImagePageControl.numberOfPages = mainImages.count
            mainImagePageControl.currentPage = 0
        }
    }

    @objc private func deleteMainImageButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < mainImages.count else { return }

        mainImages.remove(at: index)
        updateMainImageDisplay()
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
        containerView.tag = stepNumber

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
        stepTextField.tag = 1000 + stepNumber // unique tag for finding later

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
        addImageButton.tag = stepNumber
        addImageButton.addTarget(self, action: #selector(addImageButtonTapped(_:)), for: .touchUpInside)

        // 이미지 스크롤뷰
        let imageScrollView = UIScrollView()
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.tag = 2000 + stepNumber // unique tag for finding later

        let imageStackView = UIStackView()
        imageStackView.axis = .horizontal
        imageStackView.spacing = 8
        imageStackView.alignment = .leading
        imageStackView.distribution = .fillEqually
        imageStackView.tag = 3000 + stepNumber // unique tag for finding later

        imageScrollView.addSubview(imageStackView)
        imageStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        containerView.addSubview(numberLabel)
        containerView.addSubview(stepTextField)
        containerView.addSubview(imageLabel)
        containerView.addSubview(addImageButton)
        containerView.addSubview(imageScrollView)

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
            $0.height.equalTo(32)
        }

        imageScrollView.snp.makeConstraints {
            $0.top.equalTo(addImageButton.snp.bottom).offset(12)
            $0.leading.equalTo(stepTextField)
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
            $0.height.equalTo(0) // 초기에는 높이 0
        }

        return containerView
    }

    @objc private func addImageButtonTapped(_ sender: UIButton) {
        let stepNumber = sender.tag

        // 현재 선택된 이미지 개수 확인
        let currentImageCount = stepImages[stepNumber]?.count ?? 0
        let remainingCount = 5 - currentImageCount

        guard remainingCount > 0 else {
            showAlert(message: "이미지는 최대 5장까지 추가할 수 있습니다")
            return
        }

        imagePickerManager.presentImagePicker(
            from: self,
            maxSelectionCount: remainingCount
        ) { [weak self] images in
            self?.addImagesToStep(stepNumber: stepNumber, images: images)
        }
    }

    private func addImagesToStep(stepNumber: Int, images: [UIImage]) {
        // 기존 이미지에 추가
        var currentImages = stepImages[stepNumber] ?? []
        currentImages.append(contentsOf: images)
        stepImages[stepNumber] = currentImages

        // UI 업데이트
        updateStepImagesDisplay(stepNumber: stepNumber)
    }

    private func updateStepImagesDisplay(stepNumber: Int) {
        guard let images = stepImages[stepNumber],
              !images.isEmpty else {
            // 이미지가 없으면 스크롤뷰 높이를 0으로
            if let scrollView = view.viewWithTag(2000 + stepNumber) {
                scrollView.snp.updateConstraints {
                    $0.height.equalTo(0)
                }
            }
            return
        }

        // 이미지 스택뷰 찾기
        guard let stackView = view.viewWithTag(3000 + stepNumber) as? UIStackView else { return }

        // 기존 이미지뷰 제거
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 새로운 이미지뷰 추가
        for (index, image) in images.enumerated() {
            let imageContainer = UIView()

            let imageView = UIImageView()
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.backgroundColor = .systemGray6

            let deleteButton = UIButton()
            deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            deleteButton.tintColor = .white
            deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            deleteButton.layer.cornerRadius = 12
            deleteButton.tag = index
            deleteButton.addTarget(self, action: #selector(deleteImageButtonTapped(_:)), for: .touchUpInside)

            imageContainer.addSubview(imageView)
            imageContainer.addSubview(deleteButton)

            imageView.snp.makeConstraints {
                $0.edges.equalToSuperview()
                $0.width.equalTo(100)
                $0.height.equalTo(100)
            }

            deleteButton.snp.makeConstraints {
                $0.top.trailing.equalToSuperview().inset(4)
                $0.size.equalTo(24)
            }

            // 컨테이너에 stepNumber 정보 저장
            imageContainer.tag = stepNumber * 10000 + index

            stackView.addArrangedSubview(imageContainer)
        }

        // 스크롤뷰 높이 업데이트
        if let scrollView = view.viewWithTag(2000 + stepNumber) {
            scrollView.snp.updateConstraints {
                $0.height.equalTo(100)
            }
        }
    }

    @objc private func deleteImageButtonTapped(_ sender: UIButton) {
        guard let container = sender.superview,
              let stackView = container.superview as? UIStackView else { return }

        let stepNumber = container.tag / 10000
        let imageIndex = sender.tag

        // 이미지 배열에서 제거
        stepImages[stepNumber]?.remove(at: imageIndex)

        // UI 업데이트
        updateStepImagesDisplay(stepNumber: stepNumber)
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

        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 8
        containerStack.alignment = .leading
        containerStack.distribution = .fill

        tagChipsContainer.addSubview(containerStack)
        containerStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 화면에서 사용 가능한 너비 (좌우 padding 40pt 제외)
        let availableWidth = UIScreen.main.bounds.width - 40
        let horizontalSpacing: CGFloat = 8
        let chipHeight: CGFloat = 32

        var currentRowStack: UIStackView?
        var currentRowWidth: CGFloat = 0
        var rowCount = 0

        for (index, tag) in tags.enumerated() {
            // 임시로 chipView를 생성해서 너비 계산
            let chipWidth = calculateChipWidth(for: tag)

            // 새로운 줄이 필요한지 확인
            if currentRowStack == nil || (currentRowWidth + chipWidth + horizontalSpacing) > availableWidth {
                // 새로운 줄 생성
                let newRowStack = UIStackView()
                newRowStack.axis = .horizontal
                newRowStack.spacing = horizontalSpacing
                newRowStack.alignment = .leading
                newRowStack.distribution = .fill
                containerStack.addArrangedSubview(newRowStack)
                currentRowStack = newRowStack
                currentRowWidth = 0
                rowCount += 1
            }

            // chipView 생성 및 추가
            let chipView = createTagChip(tag: tag, index: index)
            currentRowStack?.addArrangedSubview(chipView)

            // 현재 줄의 너비 업데이트
            if currentRowWidth > 0 {
                currentRowWidth += horizontalSpacing
            }
            currentRowWidth += chipWidth
        }

        // 컨테이너 높이 업데이트
        let totalHeight = CGFloat(rowCount) * chipHeight + CGFloat(max(0, rowCount - 1)) * 8
        tagChipsContainer.snp.updateConstraints {
            $0.height.equalTo(totalHeight)
        }
    }

    private func calculateChipWidth(for tag: String) -> CGFloat {
        // 레이블 텍스트 너비 계산
        let text = "#\(tag)"
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textWidth = (text as NSString).size(withAttributes: attributes).width

        // 좌우 padding(12 + 8) + 아이콘(16) + 아이콘과 텍스트 사이 간격(8) + 우측 padding(8)
        return textWidth + 12 + 8 + 16 + 8 + 8
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

        // 메인 이미지 저장
        let mainRecipeImages = saveMainImagesToLocal()

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
            images: mainRecipeImages,
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
            let stepNumber = index + 1

            // stepTextField 찾기
            guard let stepTextField = view.viewWithTag(1000 + stepNumber) as? UITextField,
                  let text = stepTextField.text?.trimmingCharacters(in: .whitespaces),
                  !text.isEmpty else {
                continue
            }

            // 이미지 수집 및 저장
            var recipeImages: [RecipeImage] = []
            if let images = stepImages[stepNumber] {
                for (imageIndex, image) in images.enumerated() {
                    if let savedPath = saveImageToLocal(image: image, stepNumber: stepNumber, imageIndex: imageIndex) {
                        let recipeImage = RecipeImage(
                            source: .localPath,
                            value: savedPath,
                            isThumbnail: false
                        )
                        recipeImages.append(recipeImage)
                    }
                }
            }

            let step = RecipeStep(
                index: stepNumber,
                text: text,
                images: recipeImages
            )
            steps.append(step)
        }

        return steps
    }

    private func saveMainImagesToLocal() -> [RecipeImage] {
        var recipeImages: [RecipeImage] = []

        for (index, image) in mainImages.enumerated() {
            if let savedPath = saveImageToLocal(image: image, prefix: "main", index: index) {
                let recipeImage = RecipeImage(
                    source: .localPath,
                    value: savedPath,
                    isThumbnail: index == 0 // 첫 번째 이미지를 썸네일로
                )
                recipeImages.append(recipeImage)
            }
        }

        return recipeImages
    }

    private func saveImageToLocal(image: UIImage, stepNumber: Int, imageIndex: Int) -> String? {
        return saveImageToLocal(image: image, prefix: "step_\(stepNumber)", index: imageIndex)
    }

    private func saveImageToLocal(image: UIImage, prefix: String, index: Int) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        // Documents 디렉토리 경로
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        // 레시피 이미지 저장 디렉토리 생성
        let recipeImagesDirectory = documentsDirectory.appendingPathComponent("RecipeImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: recipeImagesDirectory, withIntermediateDirectories: true)

        // 고유한 파일 이름 생성
        let fileName = "\(prefix)_\(index)_\(UUID().uuidString).jpg"
        let fileURL = recipeImagesDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("❌ 이미지 저장 실패: \(error)")
            return nil
        }
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

// MARK: - UIScrollViewDelegate
extension RecipeAddViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainImageScrollView else { return }

        let pageWidth = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
        mainImagePageControl.currentPage = currentPage
    }
}
