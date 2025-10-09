//
//  IngredientDetailInputViewController.swift
//  YoriBogo
//
//  Created by 박성훈 on 10/1/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class IngredientDetailInputViewController: BaseViewController, ConfigureViewController {
    
    private let headerLabel = {
        let label = UILabel()
        label.text = "세부 정보를 입력해주세요"
        label.font = AppFont.pageTitle
        label.textColor = .black
        return label
    }()
    
    private let subHeaderLabel = {
        let label = UILabel()
        label.text = "수량과 유통기한을 정확히 입력하면 더 정확한 관리가 가능해요"
        label.font = AppFont.button
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var collectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(IngredientDetailInputCell.self,
                    forCellWithReuseIdentifier: IngredientDetailInputCell.id)
        cv.backgroundColor = .gray50
        cv.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        return cv
    }()
    
    let saveButton = RoundedButton(title: "냉장고에 추가하기", titleColor: .white, backgroundColor: .brandOrange500)
    
    private let viewModel: IngredientDetailInputViewModel
    private let disposeBag = DisposeBag()
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, FridgeIngredientDetail>!
    
    enum Section {
        case main
    }
    
    enum CellEvent {
        case quantityChanged(index: Int, quantity: String)
        case unitChanged(index: Int, unit: String)
        case dateSelected(index: Int, date: Date?)
    }
    
    private let cellEventRelay = PublishRelay<CellEvent>()
    
    init(viewModel: IngredientDetailInputViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        configureHierachy()
        configureLayout()
        configureDataSource()
        bind()
    }
    
    private func setupNavigation() {
        setNavigationTitle("재료 추가")
    }
    
    func configureHierachy() {
        view.addSubview(headerLabel)
        view.addSubview(subHeaderLabel)
        view.addSubview(collectionView)
        view.addSubview(saveButton)
    }
    
    func configureLayout() {
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        subHeaderLabel.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(subHeaderLabel.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(saveButton.snp.top).offset(-12)
        }
        
        saveButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.height.equalTo(52)
        }
    }
    
    func bind() {
        let quantityChangedRelay = PublishRelay<(index: Int, quantity: String)>()
        let unitSelectedRelay = PublishRelay<(index: Int, unit: String)>()
        let dateSelectedRelay = PublishRelay<(index: Int, date: Date?)>()
        
        let input = IngredientDetailInputViewModel.Input(
            quantityChanged: quantityChangedRelay.asObservable(),
            unitSelected: unitSelectedRelay.asObservable(),
            dateSelected: dateSelectedRelay.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        // 재료 리스트 업데이트
        output.ingredients
            .drive(with: self) { owner, ingredients in
                owner.applySnapshot(ingredients)
            }
            .disposed(by: disposeBag)
        
        // 저장 결과 처리
        output.saveResult
            .drive(with: self) { owner, result in
                switch result {
                case .success:
                    // 성공 토스트 표시 (선택사항)
                    print("재료 저장 완료")
                case .failure(let error):
                    // 에러 알림 (UIViewController+Alert Extension 사용)
                    owner.showErrorAlert(title: "저장 실패", error: error)
                }
            }
            .disposed(by: disposeBag)
        
        // 화면 닫기
        output.dismissScreen
            .drive(with: self) { owner, _ in
                owner.navigationController?.popToRootViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        // Cell에서 발생한 이벤트 전달
        cellEventRelay
            .subscribe(onNext: { event in
                switch event {
                case .quantityChanged(let index, let quantity):
                    quantityChangedRelay.accept((index, quantity))
                case .unitChanged(let index, let unit):
                    unitSelectedRelay.accept((index, unit))
                case .dateSelected(let index, let date):
                    dateSelectedRelay.accept((index, date))
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, FridgeIngredientDetail>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: IngredientDetailInputCell.id,
                    for: indexPath
                  ) as? IngredientDetailInputCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(with: item, index: indexPath.item)
            
            // Cell 이벤트 전달
            cell.onQuantityChanged = { [weak self] quantity in
                self?.cellEventRelay.accept(.quantityChanged(index: indexPath.item, quantity: quantity))
            }
            
            cell.onUnitChanged = { [weak self] unit in
                self?.cellEventRelay.accept(.unitChanged(index: indexPath.item, unit: unit))
            }
            
            cell.onDateSelected = { [weak self] date in
                self?.cellEventRelay.accept(.dateSelected(index: indexPath.item, date: date))
            }
            
            return cell
        }
    }
    
    private func applySnapshot(_ ingredients: [FridgeIngredientDetail]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, FridgeIngredientDetail>()
        snapshot.appendSections([.main])
        snapshot.appendItems(ingredients)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return CompositionalLayoutFactory.createVerticalListLayout(
            estimatedHeight: 280,
            spacing: 16,
            contentInsets: NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        )
    }
}

