//
//  RecipeAddViewModel.swift
//  YoriBogo
//
//  Created by Claude on 2025-10-23.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

final class RecipeAddViewModel: ViewModelType {

    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let titleText: Observable<String?>
        let categorySelected: Observable<RecipeCategory>
        let tagText: Observable<String>
        let tagRemoved: Observable<Int>
        let mainImagesAdded: Observable<[UIImage]>
        let mainImageRemoved: Observable<Int>
        let ingredientsChanged: Observable<[RecipeIngredient]>
        let stepsChanged: Observable<[RecipeStep]>
        let stepImagesAdded: Observable<(stepNumber: Int, images: [UIImage])>
        let stepImageRemoved: Observable<(stepNumber: Int, index: Int)>
        let tipText: Observable<String?>
        let saveTapped: Observable<Void>
    }

    // MARK: - Output
    struct Output {
        let title: Driver<String>
        let category: Driver<RecipeCategory>
        let tags: Driver<[String]>
        let mainImagePaths: Driver<[String]>
        let stepImagePaths: Driver<[Int: [String]]>
        let ingredients: Driver<[RecipeIngredient]>
        let steps: Driver<[RecipeStep]>
        let tip: Driver<String?>
        let saveEnabled: Driver<Bool>
        let saveSuccess: Driver<Recipe>
        let error: Driver<String>
        let dismissView: Driver<Void>
    }

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // Mode
    private let isEditMode: Bool
    private let isCreateFromApi: Bool
    private let editingRecipe: Recipe?
    private let originalRecipeSnapshot: Recipe?

    // Image paths
    private let mainImagePathsRelay = BehaviorRelay<[String]>(value: [])
    private let stepImagePathsRelay = BehaviorRelay<[Int: [String]]>(value: [:])
    private let originalMainImagePathsRelay = BehaviorRelay<[String]>(value: [])
    private let originalStepImagePathsRelay = BehaviorRelay<[Int: [String]]>(value: [:])

    // Data
    private let titleRelay = BehaviorRelay<String>(value: "")
    private let categoryRelay = BehaviorRelay<RecipeCategory>(value: .sideDish)
    private let tagsRelay = BehaviorRelay<[String]>(value: [])
    private let ingredientsRelay = BehaviorRelay<[RecipeIngredient]>(value: [])
    private let stepsRelay = BehaviorRelay<[RecipeStep]>(value: [])
    private let tipRelay = BehaviorRelay<String?>(value: nil)

    // State
    private let saveSuccessRelay = PublishRelay<Recipe>()
    private let errorRelay = PublishRelay<String>()
    private let dismissRelay = PublishRelay<Void>()

    // MARK: - Initialization
    init(editingRecipe: Recipe? = nil, isCreateFromApi: Bool = false) {
        self.isEditMode = editingRecipe != nil
        self.isCreateFromApi = isCreateFromApi
        self.editingRecipe = editingRecipe
        self.originalRecipeSnapshot = editingRecipe
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // viewDidLoad - 편집 모드일 때 데이터 로드
        input.viewDidLoad
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.loadRecipeDataIfNeeded()
            })
            .disposed(by: disposeBag)

        // Title
        input.titleText
            .compactMap { $0 }
            .skip(isEditMode ? 1 : 0) // 편집 모드일 때는 첫 번째 값(빈 값) 무시
            .bind(to: titleRelay)
            .disposed(by: disposeBag)

        // Category
        input.categorySelected
            .bind(to: categoryRelay)
            .disposed(by: disposeBag)

        // Tag 추가
        input.tagText
            .do(onNext: { newTag in print("🏷️ ViewModel: Received new tag: '\(newTag)'") })
            .withLatestFrom(tagsRelay) { ($0, $1) }
            .map { newTag, currentTags -> [String] in
                print("🏷️ ViewModel: Current tags: \(currentTags)")
                guard !newTag.isEmpty, !currentTags.contains(newTag) else {
                    print("🏷️ ViewModel: Tag rejected (empty or duplicate)")
                    return currentTags
                }
                let updatedTags = currentTags + [newTag]
                print("🏷️ ViewModel: Updated tags: \(updatedTags)")
                return updatedTags
            }
            .bind(to: tagsRelay)
            .disposed(by: disposeBag)

        // Tag 삭제
        input.tagRemoved
            .withLatestFrom(tagsRelay) { ($0, $1) }
            .map { index, currentTags -> [String] in
                var tags = currentTags
                guard index < tags.count else { return tags }
                tags.remove(at: index)
                return tags
            }
            .bind(to: tagsRelay)
            .disposed(by: disposeBag)

        // 메인 이미지 추가
        input.mainImagesAdded
            .withLatestFrom(mainImagePathsRelay) { ($0, $1) }
            .map { [weak self] images, currentPaths -> [String] in
                guard let self = self else { return currentPaths }
                let tempPaths = images.map { ImageCacheHelper.shared.cacheTempImage($0) }
                return currentPaths + tempPaths
            }
            .bind(to: mainImagePathsRelay)
            .disposed(by: disposeBag)

        // 메인 이미지 삭제
        input.mainImageRemoved
            .withLatestFrom(mainImagePathsRelay) { ($0, $1) }
            .map { [weak self] index, currentPaths -> [String] in
                guard let self = self else { return currentPaths }
                var paths = currentPaths
                guard index < paths.count else { return paths }

                // 임시 캐시에서 이미지 삭제
                let pathToRemove = paths[index]
                if ImageCacheHelper.shared.isTempPath(pathToRemove) {
                    ImageCacheHelper.shared.removeTempImage(at: pathToRemove)
                }

                paths.remove(at: index)
                return paths
            }
            .bind(to: mainImagePathsRelay)
            .disposed(by: disposeBag)

        // Ingredients
        input.ingredientsChanged
            .bind(to: ingredientsRelay)
            .disposed(by: disposeBag)

        // Steps
        input.stepsChanged
            .bind(to: stepsRelay)
            .disposed(by: disposeBag)

        // 단계 이미지 추가
        input.stepImagesAdded
            .withLatestFrom(stepImagePathsRelay) { ($0, $1) }
            .map { [weak self] stepImages, currentPaths -> [Int: [String]] in
                guard let self = self else { return currentPaths }
                let (stepNumber, images) = stepImages
                let tempPaths = images.map { ImageCacheHelper.shared.cacheTempImage($0) }

                var updatedPaths = currentPaths
                var currentStepPaths = updatedPaths[stepNumber] ?? []
                currentStepPaths.append(contentsOf: tempPaths)
                updatedPaths[stepNumber] = currentStepPaths

                return updatedPaths
            }
            .bind(to: stepImagePathsRelay)
            .disposed(by: disposeBag)

        // 단계 이미지 삭제
        input.stepImageRemoved
            .withLatestFrom(stepImagePathsRelay) { ($0, $1) }
            .map { [weak self] stepImage, currentPaths -> [Int: [String]] in
                guard let self = self else { return currentPaths }
                let (stepNumber, imageIndex) = stepImage

                var updatedPaths = currentPaths
                guard var stepPaths = updatedPaths[stepNumber],
                      imageIndex < stepPaths.count else { return currentPaths }

                // 임시 캐시에서 이미지 삭제
                let pathToRemove = stepPaths[imageIndex]
                if ImageCacheHelper.shared.isTempPath(pathToRemove) {
                    ImageCacheHelper.shared.removeTempImage(at: pathToRemove)
                }

                stepPaths.remove(at: imageIndex)
                updatedPaths[stepNumber] = stepPaths

                return updatedPaths
            }
            .bind(to: stepImagePathsRelay)
            .disposed(by: disposeBag)

        // Tip
        input.tipText
            .skip(isEditMode ? 1 : 0) // 편집 모드일 때는 첫 번째 값(placeholder) 무시
            .bind(to: tipRelay)
            .disposed(by: disposeBag)

        // Save 버튼 활성화 여부
        let saveEnabled = Observable.combineLatest(
            titleRelay,
            ingredientsRelay,
            stepsRelay,
            hasChanges()
        )
        .map { title, ingredients, steps, hasChanges in
            let titleValid = !title.trimmingCharacters(in: .whitespaces).isEmpty
            let ingredientsValid = !ingredients.isEmpty
            let stepsValid = !steps.isEmpty

            // 편집 모드일 때는 변경사항이 있어야 저장 가능
            if self.isEditMode && !self.isCreateFromApi {
                return titleValid && ingredientsValid && stepsValid && hasChanges
            }

            // 신규 추가 모드
            return titleValid && ingredientsValid && stepsValid
        }
        .asDriver(onErrorJustReturn: false)

        // Save 처리
        input.saveTapped
            .withUnretained(self)
            .subscribe(onNext: { owner, _ in
                owner.saveRecipe()
            })
            .disposed(by: disposeBag)

        return Output(
            title: titleRelay.asDriver(),
            category: categoryRelay.asDriver(),
            tags: tagsRelay.asDriver(),
            mainImagePaths: mainImagePathsRelay.asDriver(),
            stepImagePaths: stepImagePathsRelay.asDriver(),
            ingredients: ingredientsRelay.asDriver(),
            steps: stepsRelay.asDriver(),
            tip: tipRelay.asDriver(),
            saveEnabled: saveEnabled,
            saveSuccess: saveSuccessRelay.asDriver(onErrorDriveWith: .empty()),
            error: errorRelay.asDriver(onErrorDriveWith: .empty()),
            dismissView: dismissRelay.asDriver(onErrorDriveWith: .empty())
        )
    }

    // MARK: - Private Methods

    private func loadRecipeDataIfNeeded() {
        guard let recipe = editingRecipe else {
            print("⚠️ RecipeAddViewModel: editingRecipe is nil")
            return
        }

        print("✅ RecipeAddViewModel: Loading recipe data")
        print("   - Title: \(recipe.title)")
        print("   - Category: \(recipe.category?.displayName ?? "없음")")
        print("   - Tags: \(recipe.tags)")
        print("   - Ingredients count: \(recipe.ingredients.count)")
        print("   - Steps count: \(recipe.steps.count)")
        print("   - Tip: \(recipe.tip ?? "없음")")

        titleRelay.accept(recipe.title)
        categoryRelay.accept(recipe.category ?? .sideDish)
        tagsRelay.accept(recipe.tags)
        tipRelay.accept(recipe.tip)
        ingredientsRelay.accept(recipe.ingredients)
        stepsRelay.accept(recipe.steps)

        print("✅ RecipeAddViewModel: Relay values updated")

        // 메인 이미지 로드
        loadMainImages(from: recipe.images)

        // 단계별 이미지 로드
        loadStepImages(from: recipe.steps)
    }

    private func loadMainImages(from recipeImages: [RecipeImage]) {
        guard !recipeImages.isEmpty else { return }

        // 원본 이미지 경로 저장
        originalMainImagePathsRelay.accept(recipeImages.map { $0.value })

        let group = DispatchGroup()
        var loadedImages: [(index: Int, image: UIImage)] = []

        for (index, recipeImage) in recipeImages.enumerated() {
            group.enter()

            switch recipeImage.source {
            case .remoteURL:
                // HTTP -> HTTPS 변환
                let httpsURLString = recipeImage.value.replacingOccurrences(of: "http://", with: "https://")

                guard let url = URL(string: httpsURLString) else {
                    group.leave()
                    continue
                }

                // Kingfisher를 사용하여 이미지 다운로드
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        loadedImages.append((index, image))
                    }
                    group.leave()
                }

            case .localPath:
                // 로컬 파일에서 이미지 로드
                if let image = ImagePathHelper.shared.loadImage(at: recipeImage.value) {
                    loadedImages.append((index, image))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // 인덱스 순서대로 정렬
            loadedImages.sort { $0.index < $1.index }

            // 이미지를 임시 캐시에 저장하고 경로 반환
            let tempPaths = loadedImages.map { _, image in
                ImageCacheHelper.shared.cacheTempImage(image)
            }

            self.mainImagePathsRelay.accept(tempPaths)
        }
    }

    private func loadStepImages(from steps: [RecipeStep]) {
        var allStepImagePaths: [Int: [String]] = [:]
        var allOriginalStepImagePaths: [Int: [String]] = [:]

        let group = DispatchGroup()

        for (index, step) in steps.enumerated() {
            let stepNumber = index + 1
            guard !step.images.isEmpty else { continue }

            // 원본 이미지 경로 저장
            allOriginalStepImagePaths[stepNumber] = step.images.map { $0.value }

            var loadedImages: [(index: Int, image: UIImage)] = []

            for (imageIndex, recipeImage) in step.images.enumerated() {
                group.enter()

                switch recipeImage.source {
                case .remoteURL:
                    let httpsURLString = recipeImage.value.replacingOccurrences(of: "http://", with: "https://")

                    guard let url = URL(string: httpsURLString) else {
                        group.leave()
                        continue
                    }

                    DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url),
                           let image = UIImage(data: data) {
                            loadedImages.append((imageIndex, image))
                        }
                        group.leave()
                    }

                case .localPath:
                    if let image = ImagePathHelper.shared.loadImage(at: recipeImage.value) {
                        loadedImages.append((imageIndex, image))
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }

                loadedImages.sort { $0.index < $1.index }

                let tempPaths = loadedImages.map { _, image in
                    ImageCacheHelper.shared.cacheTempImage(image)
                }

                if !tempPaths.isEmpty {
                    allStepImagePaths[stepNumber] = tempPaths
                }

                self.stepImagePathsRelay.accept(allStepImagePaths)
                self.originalStepImagePathsRelay.accept(allOriginalStepImagePaths)
            }
        }
    }

    private func hasChanges() -> Observable<Bool> {
        guard isEditMode, let original = originalRecipeSnapshot else {
            return Observable.just(true)
        }

        return Observable.combineLatest(
            titleRelay,
            categoryRelay,
            tagsRelay,
            mainImagePathsRelay,
            ingredientsRelay,
            stepsRelay,
            tipRelay
        )
        .map { title, category, tags, mainImagePaths, ingredients, steps, tip in
            let titleChanged = title.trimmingCharacters(in: .whitespaces) != original.title
            let categoryChanged = category != original.category
            let tagsChanged = tags != original.tags
            let mainImagesChanged = mainImagePaths.count != original.images.count
            let ingredientsChanged = !self.areIngredientsEqual(ingredients, original.ingredients)
            let stepsChanged = !self.areStepsEqual(steps, original.steps)
            let tipChanged = tip != original.tip

            return titleChanged || categoryChanged || tagsChanged || mainImagesChanged ||
                   ingredientsChanged || stepsChanged || tipChanged
        }
    }

    private func areIngredientsEqual(_ ingredients1: [RecipeIngredient], _ ingredients2: [RecipeIngredient]) -> Bool {
        guard ingredients1.count == ingredients2.count else { return false }

        for (index, ingredient1) in ingredients1.enumerated() {
            let ingredient2 = ingredients2[index]

            if ingredient1.name != ingredient2.name ||
               ingredient1.qty != ingredient2.qty ||
               ingredient1.unit != ingredient2.unit {
                return false
            }
        }

        return true
    }

    private func areStepsEqual(_ steps1: [RecipeStep], _ steps2: [RecipeStep]) -> Bool {
        guard steps1.count == steps2.count else { return false }

        for (index, step1) in steps1.enumerated() {
            let step2 = steps2[index]

            if step1.text != step2.text ||
               step1.images.count != step2.images.count {
                return false
            }
        }

        return true
    }

    private func saveRecipe() {
        // 유효성 검증
        let title = titleRelay.value.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else {
            errorRelay.accept("레시피 이름을 입력해주세요")
            return
        }

        let ingredients = ingredientsRelay.value
        guard !ingredients.isEmpty else {
            errorRelay.accept("재료를 최소 1개 이상 입력해주세요")
            return
        }

        let steps = stepsRelay.value
        guard !steps.isEmpty else {
            errorRelay.accept("요리 단계를 최소 1개 이상 입력해주세요")
            return
        }

        // 메인 이미지 저장
        let mainRecipeImages = saveMainImagesToLocal()

        // 단계별 이미지가 포함된 Steps 생성
        let stepsWithImages = createStepsWithImages(steps: steps)

        // Recipe 객체 생성
        let recipe: Recipe
        if isEditMode, let existingRecipe = editingRecipe {
            recipe = Recipe(
                id: existingRecipe.id,
                baseId: existingRecipe.baseId,
                kind: existingRecipe.kind == .userOriginal ? .userOriginal : .userModified,
                version: existingRecipe.version,
                title: title,
                category: categoryRelay.value,
                method: existingRecipe.method,
                tags: tagsRelay.value,
                tip: tipRelay.value,
                images: mainRecipeImages,
                nutrition: existingRecipe.nutrition,
                ingredients: ingredients,
                steps: stepsWithImages,
                isBookmarked: existingRecipe.isBookmarked,
                rating: existingRecipe.rating,
                cookCount: existingRecipe.cookCount,
                lastCookedAt: existingRecipe.lastCookedAt,
                createdAt: existingRecipe.createdAt,
                updatedAt: Date()
            )
        } else {
            recipe = Recipe(
                id: UUID().uuidString,
                baseId: UUID().uuidString,
                kind: .userOriginal,
                version: 1,
                title: title,
                category: categoryRelay.value,
                method: nil,
                tags: tagsRelay.value,
                tip: tipRelay.value,
                images: mainRecipeImages,
                nutrition: nil,
                ingredients: ingredients,
                steps: stepsWithImages,
                isBookmarked: false,
                rating: nil,
                cookCount: 0,
                lastCookedAt: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        }

        // Realm에 저장
        do {
            try RecipeRealmManager.shared.updateRecipe(recipe)
            saveSuccessRelay.accept(recipe)
            dismissRelay.accept(())
        } catch {
            errorRelay.accept("레시피 저장에 실패했습니다: \(error.localizedDescription)")
        }
    }

    private func saveMainImagesToLocal() -> [RecipeImage] {
        var recipeImages: [RecipeImage] = []
        let mainImagePaths = mainImagePathsRelay.value
        let originalPaths = originalMainImagePathsRelay.value

        if isCreateFromApi {
            // API 레시피로부터 만들기: 모든 이미지를 새로 저장
            for (index, imagePath) in mainImagePaths.enumerated() {
                guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                    continue
                }

                if let savedPath = saveImageToLocal(image: image, prefix: "main", index: index) {
                    let recipeImage = RecipeImage(
                        source: .localPath,
                        value: savedPath,
                        isThumbnail: index == 0
                    )
                    recipeImages.append(recipeImage)
                }
            }
            return recipeImages
        }

        // 일반 편집 모드: 기존 이미지는 재사용, 새 이미지만 저장
        for (index, imagePath) in mainImagePaths.enumerated() {
            if index < originalPaths.count {
                // 기존 이미지 경로 재사용
                let recipeImage = RecipeImage(
                    source: .localPath,
                    value: originalPaths[index],
                    isThumbnail: index == 0
                )
                recipeImages.append(recipeImage)
            } else {
                // 새로운 이미지 저장
                guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                    continue
                }

                if let savedPath = saveImageToLocal(image: image, prefix: "main", index: index) {
                    let recipeImage = RecipeImage(
                        source: .localPath,
                        value: savedPath,
                        isThumbnail: index == 0
                    )
                    recipeImages.append(recipeImage)
                }
            }
        }

        // 삭제된 이미지 처리
        if mainImagePaths.count < originalPaths.count {
            for index in mainImagePaths.count..<originalPaths.count {
                deleteImageFile(at: originalPaths[index])
            }
        }

        return recipeImages
    }

    private func createStepsWithImages(steps: [RecipeStep]) -> [RecipeStep] {
        let stepImagePaths = stepImagePathsRelay.value
        let originalStepPaths = originalStepImagePathsRelay.value

        return steps.enumerated().map { index, step in
            let stepNumber = index + 1
            var recipeImages: [RecipeImage] = []

            if let imagePaths = stepImagePaths[stepNumber] {
                if isCreateFromApi {
                    // API 레시피로부터 만들기: 모든 이미지를 새로 저장
                    for (imageIndex, imagePath) in imagePaths.enumerated() {
                        guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                            continue
                        }

                        if let savedPath = saveImageToLocal(image: image, stepNumber: stepNumber, imageIndex: imageIndex) {
                            let recipeImage = RecipeImage(
                                source: .localPath,
                                value: savedPath,
                                isThumbnail: false
                            )
                            recipeImages.append(recipeImage)
                        }
                    }
                } else {
                    // 일반 편집 모드: 기존 이미지는 재사용, 새 이미지만 저장
                    let originalPaths = originalStepPaths[stepNumber] ?? []

                    for (imageIndex, imagePath) in imagePaths.enumerated() {
                        if imageIndex < originalPaths.count {
                            // 기존 이미지 경로 재사용
                            let recipeImage = RecipeImage(
                                source: .localPath,
                                value: originalPaths[imageIndex],
                                isThumbnail: false
                            )
                            recipeImages.append(recipeImage)
                        } else {
                            // 새로운 이미지 저장
                            guard let image = ImageCacheHelper.shared.loadImage(at: imagePath) else {
                                continue
                            }

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

                    // 삭제된 이미지 처리
                    if imagePaths.count < originalPaths.count {
                        for index in imagePaths.count..<originalPaths.count {
                            deleteImageFile(at: originalPaths[index])
                        }
                    }
                }
            }

            return RecipeStep(
                index: stepNumber,
                text: step.text,
                images: recipeImages
            )
        }
    }

    private func saveImageToLocal(image: UIImage, stepNumber: Int, imageIndex: Int) -> String? {
        return saveImageToLocal(image: image, prefix: "step_\(stepNumber)", index: imageIndex)
    }

    private func saveImageToLocal(image: UIImage, prefix: String, index: Int) -> String? {
        return ImagePathHelper.shared.saveImageWithDuplicateCheck(image, prefix: prefix, index: index)
    }

    private func deleteImageFile(at path: String) {
        ImagePathHelper.shared.deleteImage(at: path)
    }

    // MARK: - Deinit
    deinit {
        // 화면 종료 시 임시 이미지 캐시 정리
        ImageCacheHelper.shared.clearAllTempImages()
        print("✅ RecipeAddViewModel deinit - 임시 이미지 정리 완료")
    }
}
