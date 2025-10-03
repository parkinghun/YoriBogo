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

    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var viewModel: FridgeViewModel
    private var dataSource: UICollectionViewDiffableDataSource<FridgeCategorySection, FridgeIngredientDetail>!
    private let viewDidLoadRelay = PublishRelay<Void>()

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
    }

    func configureHierachy() {
        view.addSubview(emptyView)
        view.addSubview(collectionView)
    }

    func configureLayout() {
        emptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - Binding
    func bind() {
        let input = FridgeViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            addButtonTapped: emptyView.ctaButton.rx.tap
        )

        let output = viewModel.transform(input: input)

        // 빈 화면 전환
        output.isEmpty
            .drive(with: self) { owner, isEmpty in
                owner.emptyView.isHidden = !isEmpty
                owner.collectionView.isHidden = isEmpty
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
    }

    // MARK: - DataSource
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

        // 헤더 설정
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

    // MARK: - Layout
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(160)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(160)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)

        // 헤더 추가
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
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
