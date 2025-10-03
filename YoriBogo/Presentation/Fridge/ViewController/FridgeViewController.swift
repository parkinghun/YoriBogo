//
//  FridgeViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class FridgeViewController: BaseViewController, ConfigureViewController {

    private let emptyView = FridgeEmptyView()

    private lazy var categoryChipCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.showsHorizontalScrollIndicator = false
        cv.register(FridgeCategoryChipCell.self, forCellWithReuseIdentifier: FridgeCategoryChipCell.id)
        return cv
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .gray50
        cv.register(FridgeIngredientCardCell.self, forCellWithReuseIdentifier: FridgeIngredientCardCell.id)
        cv.register(IngredientHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: IngredientHeaderView.id)
        cv.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        return cv
    }()
    
    private let addButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: nil, action: nil)

    private let filterInfoView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private let totalCountLabel = {
        let label = UILabel()
        label.font = Pretendard.medium.of(size: 14)
        label.textColor = .gray700
        return label
    }()

    private let sortButton = {
        let button = UIButton()
        button.setTitle("기본순", for: .normal)
        button.setTitleColor(.gray700, for: .normal)
        button.titleLabel?.font = Pretendard.medium.of(size: 14)
        button.setImage(UIImage(named: "sort"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        return button
    }()

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var viewModel: FridgeViewModel
    private var dataSource: UICollectionViewDiffableDataSource<FridgeCategorySection, FridgeIngredientDetail>!
    private var chipDataSource: UICollectionViewDiffableDataSource<Int, CategoryChip>!
    private let viewDidLoadRelay = PublishRelay<Void>()
    private let categorySelectedRelay = PublishRelay<Int>()
    private var categoryChips: [CategoryChip] = []

    // MARK: - Initialization
    init(viewModel: FridgeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        configureDataSource()
        configureCategoryChipDataSource()
        bind()

        viewDidLoadRelay.accept(())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면 재진입 시 데이터 리로드
        viewDidLoadRelay.accept(())
    }

    // MARK: - Setup
    private func setupNavigation() {
        navigationItem.title = "냉장고"
        navigationItem.rightBarButtonItem = addButtonItem
    }

    func configureHierachy() {
        view.addSubview(emptyView)
        view.addSubview(categoryChipCollectionView)
        view.addSubview(filterInfoView)
        filterInfoView.addSubview(totalCountLabel)
        filterInfoView.addSubview(sortButton)
        view.addSubview(collectionView)
    }

    func configureLayout() {
        emptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        categoryChipCollectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(60)
        }

        filterInfoView.snp.makeConstraints {
            $0.top.equalTo(categoryChipCollectionView.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(44)
        }

        totalCountLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        sortButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(filterInfoView.snp.bottom)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Binding
    func bind() {
        let input = FridgeViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            addButtonTapped: Observable.merge(emptyView.ctaButton.rx.tap.asObservable(),
                                              addButtonItem.rx.tap.asObservable()),
            categorySelected: categorySelectedRelay.asObservable(),
            sortButtonTapped: sortButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 빈 화면 전환
        output.isEmpty
            .drive(with: self) { owner, isEmpty in
                owner.emptyView.isHidden = !isEmpty
                owner.collectionView.isHidden = isEmpty
                owner.categoryChipCollectionView.isHidden = isEmpty
                owner.filterInfoView.isHidden = isEmpty
                owner.addButtonItem.isHidden = isEmpty
            }
            .disposed(by: disposeBag)

        // 총 아이템 수 표시
        output.totalItemCount
            .drive(with: self) { owner, count in
                owner.totalCountLabel.text = "전체 \(count)개"
            }
            .disposed(by: disposeBag)

        // 정렬 버튼 텍스트 업데이트
        output.currentSort
            .drive(with: self) { owner, sort in
                let title = sort == .basic ? "기본순" : "소비기한 임박순"
                owner.sortButton.setTitle(title, for: .normal)
            }
            .disposed(by: disposeBag)

        // 카테고리 칩 선택 이벤트 (rx.itemSelected 사용)
        categoryChipCollectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> Int? in
                guard let chip = self?.chipDataSource.itemIdentifier(for: indexPath) else { return nil }
                return chip.id
            }
            .bind(to: categorySelectedRelay)
            .disposed(by: disposeBag)

        // 카테고리 칩 데이터 바인딩 (선택 상태 포함)
        output.categoryChips
            .drive(with: self) { owner, chips in
                owner.categoryChips = chips
                owner.applyCategoryChipSnapshot(chips: chips)
            }
            .disposed(by: disposeBag)

        // 섹션 데이터 바인딩
        output.sections
            .drive(with: self) { owner, sections in
                owner.applySnapshot(sections: sections)
            }
            .disposed(by: disposeBag)

        // 재료 추가 화면으로 이동
        output.pushIngredientSelectionVC
            .drive(with: self) { owner, _ in
                let vc = IngredientSelectionViewController(viewModel: .init())
                vc.hidesBottomBarWhenPushed = true
                owner.navigationController?.pushViewController(vc, animated: true)
            }
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> FridgeIngredientDetail? in
                guard let item = self?.dataSource.itemIdentifier(for: indexPath) else { return nil }
                return item
            }
            .bind(with: self) { owner, ingredient in
                owner.showIngredientDetail(ingredient)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Ingredient Detail
    private func showIngredientDetail(_ ingredient: FridgeIngredientDetail) {
        let detailCardView = IngredientDetailCardView()
        detailCardView.configure(with: ingredient)
        detailCardView.show(in: view)

        detailCardView.closeButton.rx.tap
            .bind {
                detailCardView.dismiss()
            }
            .disposed(by: disposeBag)

        detailCardView.consumeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.handleConsume(ingredient, cardView: detailCardView)
            }
            .disposed(by: disposeBag)

        detailCardView.discardButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.handleDiscard(ingredient, cardView: detailCardView)
            }
            .disposed(by: disposeBag)

        detailCardView.saveButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.handleSave(cardView: detailCardView)
            }
            .disposed(by: disposeBag)
    }

    private func handleConsume(_ ingredient: FridgeIngredientDetail, cardView: IngredientDetailCardView) {
        do {
            try viewModel.consumeIngredient(id: ingredient.id)
            cardView.dismiss()
            viewDidLoadRelay.accept(())
        } catch {
            print("소진 처리 실패: \(error)")
        }
    }

    private func handleDiscard(_ ingredient: FridgeIngredientDetail, cardView: IngredientDetailCardView) {
        do {
            try viewModel.discardIngredient(id: ingredient.id)
            cardView.dismiss()
            viewDidLoadRelay.accept(())
        } catch {
            print("폐기 처리 실패: \(error)")
        }
    }

    private func handleSave(cardView: IngredientDetailCardView) {
        guard let updatedDetail = cardView.getUpdatedDetail() else { return }

        do {
            try viewModel.updateIngredient(updatedDetail)
            cardView.dismiss()
            viewDidLoadRelay.accept(())
        } catch {
            print("수정 처리 실패: \(error)")
        }
    }

    // MARK: - DataSource
    private func configureCategoryChipDataSource() {
        chipDataSource = UICollectionViewDiffableDataSource<Int, CategoryChip>(
            collectionView: categoryChipCollectionView
        ) { collectionView, indexPath, chip in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FridgeCategoryChipCell.id,
                for: indexPath
            ) as? FridgeCategoryChipCell else {
                return UICollectionViewCell()
            }

            cell.configure(title: chip.name, isSelected: chip.isSelected)
            return cell
        }
    }

    private func applyCategoryChipSnapshot(chips: [CategoryChip]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CategoryChip>()
        snapshot.appendSections([0])
        snapshot.appendItems(chips)
        chipDataSource.apply(snapshot, animatingDifferences: false)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<FridgeCategorySection, FridgeIngredientDetail>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: FridgeIngredientCardCell.id,
                for: indexPath
            ) as? FridgeIngredientCardCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: item)
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: IngredientHeaderView.id,
                      for: indexPath
                  ) as? IngredientHeaderView,
                  let section = self?.dataSource.snapshot().sectionIdentifiers[indexPath.section] else {
                return nil
            }

            header.configure(title: section.categoryName, count: section.count)
            return header
        }
    }

    private func applySnapshot(sections: [FridgeCategorySection]) {
        var snapshot = NSDiffableDataSourceSnapshot<FridgeCategorySection, FridgeIngredientDetail>()

        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.items, toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(160)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return UICollectionViewCompositionalLayout(section: section)
    }
}
